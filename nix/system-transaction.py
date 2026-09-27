import argparse
import fcntl
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import time


PROFILE = Path("/nix/var/nix/profiles/system-manager-profiles/system-manager")
ETC = Path("/etc")
STATE = Path("/var/lib/dotfiles-system")
PENDING_ROOT = Path("/nix/var/nix/gcroots/dotfiles-system-pending")


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, umask=0o022, **kwargs)


def generation(value):
    path = Path(value).resolve(strict=True)
    if (
        path.parent != Path("/nix/store")
        or not (path / "bin/dotfiles-manifest").is_file()
    ):
        raise RuntimeError("Expected an immutable dotfiles system generation")
    return path


def current():
    return generation(PROFILE) if PROFILE.exists() else None


def read_json(path):
    return json.loads(path.read_text())


def write_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def files(profile):
    if not profile:
        return {}
    metadata = read_json(profile / "etcFiles/etcFiles.json")
    root = Path(metadata["staticEnv"])
    result = {}
    for directory, _, names in os.walk(root, followlinks=True):
        for name in names:
            source = Path(directory) / name
            result[ETC / source.relative_to(root)] = source.resolve()
    for entry in metadata["entries"].values():
        if entry["mode"] != "symlink":
            target = Path(entry["target"])
            if target.is_absolute() or ".." in target.parts:
                raise RuntimeError("Invalid system file target")
            result[ETC / target] = Path(entry["source"]) / target
    return result


def matches(path, source):
    if path.is_symlink():
        return path.resolve() == source.resolve()
    return (
        path.is_file() and source.is_file() and path.read_bytes() == source.read_bytes()
    )


def conflicts(profile, previous):
    old = files(previous)
    result = []
    old_root = (
        Path(read_json(previous / "etcFiles/etcFiles.json")["staticEnv"])
        if previous
        else None
    )
    for path, source in files(profile).items():
        for parent in path.parents:
            if parent == ETC:
                break
            owned_parent = (
                old_root is not None
                and parent.resolve() == (old_root / parent.relative_to(ETC)).resolve()
            )
            if parent.is_symlink() and not owned_parent:
                raise RuntimeError(f"Unmanaged system parent is a symlink: {parent}")
            if parent.exists() and not parent.is_dir():
                raise RuntimeError(f"System parent is not a directory: {parent}")
        if not path.exists() and not path.is_symlink():
            continue
        if path in old and matches(path, old[path]):
            continue
        if path.is_symlink() and matches(path, source):
            continue
        result.append(path)
    return result


def preflight(profile, previous, adopt):
    if Path("/proc/1/comm").read_text().strip() != "systemd":
        raise RuntimeError("System provisioning requires a booted systemd machine")
    release = platform.freedesktop_os_release()
    if release.get("ID") != "ubuntu" or release.get("VERSION_ID") != "26.04":
        raise RuntimeError("System provisioning requires Ubuntu 26.04")
    for legacy in (
        Path("/etc/tmpfiles.d/non-nixos-gpu.conf"),
        Path("/etc/systemd/system/non-nixos-gpu.service"),
    ):
        if legacy.exists() or legacy.is_symlink():
            raise RuntimeError(
                "Archive the legacy non-nixos-gpu unit and tmpfiles configuration and disable its service before system provisioning"
            )
    docker_packages = (
        "docker.io",
        "docker-ce",
        "docker-ce-cli",
        "containerd",
        "containerd.io",
        "podman-docker",
    )
    for package in (
        docker_packages
        if read_json(profile / "bin/dotfiles-manifest")["docker"]
        else ()
    ):
        installed = subprocess.run(
            ["/usr/bin/dpkg-query", "-W", "-f=${db:Status-Status}", package],
            capture_output=True,
            text=True,
        )
        if installed.returncode == 0 and installed.stdout == "installed":
            raise RuntimeError(
                f"Remove the Ubuntu-managed {package} package before adopting Nix Docker; preserve /var/lib/docker"
            )
    collision = conflicts(profile, previous)
    if collision and not adopt:
        raise RuntimeError(
            "Unmanaged system files conflict; inspect them before --adopt:\n"
            + "\n".join(map(str, collision))
        )
    return collision


def engine(profile, action):
    # Upstream `185062bb` can log activation failures and return success.
    # Keep this check until https://github.com/numtide/system-manager/blob/185062bb39493a74599bb3cf7731ee0614cade9b/crates/system-manager-engine/src/activate.rs propagates them.
    command = [str(profile / "bin" / action)]
    environment = dict(os.environ, RUST_LOG="error", RUST_LOG_STYLE="never")
    if action == "deactivate":
        command = [str(profile / "bin/system-manager-engine"), "deactivate"]
        environment["PATH"] = "/usr/bin:/usr/sbin:/bin:/sbin"
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=environment,
        umask=0o022,
    )
    errors = False
    for line in process.stdout:
        print(line, end="", flush=True)
        errors = errors or "ERROR" in line
    result = process.wait()
    process.stdout.close()
    if result or errors:
        raise RuntimeError(f"system-manager {action} failed")


def healthy(profile):
    for path, source in files(profile).items():
        if not matches(path, source):
            raise RuntimeError(f"System file was not activated: {path}")
    manifest = read_json(profile / "bin/dotfiles-manifest")
    for unit in manifest["requiredServices"]:
        run(["/usr/bin/systemctl", "is-active", "--quiet", unit])


def register(profile):
    engine(profile, "register-profile")
    if current() != profile:
        raise RuntimeError("System profile did not register the requested generation")


def restore_adoptions(profile, adoptions):
    desired = files(profile)
    for name, saved in list(adoptions.items()):
        path, backup = Path(name), Path(saved)
        if path in desired:
            continue
        if path.exists() or path.is_symlink():
            raise RuntimeError(
                f"Recovery collision at {path}; backup retained at {backup}"
            )
        path.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(backup, path)
        del adoptions[name]


def restore(previous, failed, adoptions):
    if previous:
        engine(previous, "activate")
        healthy(previous)
        register(previous)
    else:
        engine(failed, "deactivate")
        if PROFILE.is_symlink():
            PROFILE.unlink()
        Path("/nix/var/nix/gcroots/system-manager-current").unlink(missing_ok=True)
    restore_adoptions(previous, adoptions)


def apply(profile, adopt, state):
    previous = current()
    preflight(profile, previous, adopt)
    run([profile / "bin/dotfiles-native"])
    collision = preflight(profile, previous, adopt)
    transaction = STATE / "transactions" / str(time.time_ns())
    transaction.mkdir(parents=True, mode=0o700)
    adoptions = state.setdefault("adoptions", {})
    original_adoptions = dict(adoptions)
    moved = []
    write_json(
        transaction / "operation.json",
        {"previous": str(previous) if previous else None, "target": str(profile)},
    )
    state["pending"] = {
        "previous": str(previous) if previous else None,
        "target": str(profile),
    }
    pending_root = PENDING_ROOT
    pending_root.unlink(missing_ok=True)
    pending_root.symlink_to(profile)
    write_json(STATE / "state.json", state)
    try:
        for path in collision:
            backup = transaction / "files" / path.relative_to(ETC)
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(path, backup)
            moved.append((path, backup))
            adoptions.setdefault(str(path), str(backup))
            write_json(STATE / "state.json", state)
        engine(profile, "activate")
        healthy(profile)
        register(profile)
        restore_adoptions(profile, adoptions)
    except BaseException:
        try:
            restore(previous, profile, adoptions)
            old_files = files(previous)
            for path, backup in reversed(moved):
                if not backup.exists() and not backup.is_symlink():
                    continue
                if path.exists() or path.is_symlink():
                    if path not in old_files or not matches(path, old_files[path]):
                        raise RuntimeError(
                            f"Recovery collision at {path}; backup retained at {backup}"
                        )
                    path.unlink()
                shutil.move(backup, path)
            state["adoptions"] = original_adoptions
            state.pop("pending", None)
            write_json(STATE / "state.json", state)
            pending_root.unlink(missing_ok=True)
        except Exception as error:
            print(
                f"System recovery failed: {error}; transaction: {transaction}",
                file=sys.stderr,
            )
        write_json(STATE / "state.json", state)
        raise
    state.pop("pending", None)
    write_json(STATE / "state.json", state)
    pending_root.unlink(missing_ok=True)
    print(f"System transaction: {transaction}")


def main():
    if os.geteuid() != 0:
        raise RuntimeError("System transactions require sudo")
    os.umask(0o077)
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["check", "apply", "recover", "repair"])
    parser.add_argument("generation")
    parser.add_argument("previous", nargs="?")
    parser.add_argument("--adopt", action="store_true")
    args = parser.parse_args()
    profile = generation(args.generation)
    if STATE.is_symlink():
        raise RuntimeError("System transaction state must not be a symlink")
    STATE.mkdir(mode=0o700, exist_ok=True)
    with (STATE / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        state_path = STATE / "state.json"
        state = read_json(state_path) if state_path.exists() else {"adoptions": {}}
        if args.action == "repair":
            pending = state.get("pending")
            if not pending:
                raise RuntimeError("No interrupted system transaction exists")
            previous = generation(pending["previous"]) if pending["previous"] else None
            restore(previous, generation(pending["target"]), state["adoptions"])
            state.pop("pending")
            write_json(state_path, state)
            PENDING_ROOT.unlink(missing_ok=True)
            return
        if state.get("pending"):
            raise RuntimeError(
                "Interrupted system transaction; run this helper with repair before applying another generation"
            )
        if args.action == "check":
            for path in preflight(profile, current(), args.adopt):
                print(f"adopt system path: {path}")
        elif args.action == "apply":
            apply(profile, args.adopt, state)
        else:
            if current() != profile:
                raise RuntimeError(
                    "System generation changed during home activation; refusing to overwrite another deployment"
                )
            previous = generation(args.previous) if args.previous != "none" else None
            state["pending"] = {
                "previous": str(previous) if previous else None,
                "target": str(profile),
            }
            PENDING_ROOT.unlink(missing_ok=True)
            PENDING_ROOT.symlink_to(profile)
            write_json(state_path, state)
            restore(previous, profile, state["adoptions"])
            state.pop("pending")
            write_json(state_path, state)
            PENDING_ROOT.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print(f"dotfiles-system: {error}", file=sys.stderr)
        sys.exit(1)
