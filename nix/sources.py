import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import tarfile


DOOM = ".config/doom"
RECEIPT = "nix/doom-source.json"
EXTRA_FILES = [
    "flake.nix",
    "flake.lock",
    ".dockerignore",
    "bin/dotfiles",
    "bin/bootstrap",
    "bin/install",
    "bin/export",
    "bin/test",
    "bin/test-vm",
    ".github/scripts/check-agent-references.sh",
]


def regular_file(root, name):
    path = PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts or not path.parts:
        raise RuntimeError(f"Invalid source path: {name}")
    source = root / name
    if (
        not source.is_file()
        or source.is_symlink()
        or not source.resolve().is_relative_to(root.resolve())
    ):
        raise RuntimeError(f"Source must be a regular repository file: {name}")
    return source


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def doom_receipt(root):
    doom = root / DOOM
    if (root / ".git").exists():
        entry = git(root, "ls-files", "--stage", "--", DOOM).split()
        if len(entry) != 4 or entry[0] != "160000" or entry[2] != "0":
            raise RuntimeError("Doom must have one staged Git submodule reference")
        revision = entry[1]
        if not (doom / ".git").exists() or git(doom, "rev-parse", "HEAD") != revision:
            raise RuntimeError(
                "Doom checkout does not match the Git submodule reference"
            )
        if git(doom, "status", "--porcelain", "--untracked-files=all"):
            raise RuntimeError(
                "Commit or remove Doom working-tree changes before deployment"
            )
        names = git(doom, "ls-files", "-z").strip("\0").split("\0")
        receipt = {
            "revision": revision,
            "files": {name: digest(regular_file(doom, name)) for name in names},
        }
    else:
        path = root / RECEIPT
        if not path.is_file():
            raise RuntimeError(
                "Private Doom requires a Git checkout or a verified bin/export archive"
            )
        receipt = json.loads(path.read_text())
        if (
            not isinstance(receipt, dict)
            or not isinstance(receipt.get("revision"), str)
            or not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", receipt["revision"])
            or not isinstance(receipt.get("files"), dict)
            or not {"init.el", "config.el", "packages.el"}.issubset(receipt["files"])
        ):
            raise RuntimeError("Incomplete Doom source receipt")
        for name, expected in receipt["files"].items():
            if digest(regular_file(doom, name)) != expected:
                raise RuntimeError(
                    f"Doom source differs from its export receipt: {name}"
                )
    return receipt


def source_files(root, private=True):
    files = set(json.loads((root / "nix/dotfiles.json").read_text()))
    files.update(EXTRA_FILES)
    for directory in ("nix", "tests/nix"):
        files.update(
            str(p.relative_to(root))
            for p in (root / directory).rglob("*")
            if p.is_file() and "__pycache__" not in p.parts and p.suffix != ".pyc"
        )
    files.discard(RECEIPT)
    files = {name for name in files if name != DOOM and not name.startswith(DOOM + "/")}
    if private and (root / DOOM / "init.el").exists():
        files.update(f"{DOOM}/{name}" for name in doom_receipt(root)["files"])
    return sorted(files)


def snapshot(root, destination, private=True):
    receipt = (
        doom_receipt(root) if private and (root / DOOM / "init.el").exists() else None
    )
    files = source_files(root, private=private)
    for name in files:
        if name == "flake.lock" and not (root / name).exists():
            continue
        source = root / name
        if source.is_symlink():
            resolved = source.resolve()
            if (
                not resolved.is_relative_to(root.resolve())
                or str(resolved.relative_to(root.resolve())) not in files
            ):
                raise RuntimeError(
                    f"Symlink target is outside the source manifest: {name}"
                )
            source = regular_file(root, str(resolved.relative_to(root.resolve())))
        else:
            source = regular_file(root, name)
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    if receipt:
        (destination / RECEIPT).write_text(json.dumps(receipt, indent=2) + "\n")
        doom_receipt(destination)


def archive(source, destination):
    with os.fdopen(
        os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb"
    ) as stream:
        with tarfile.open(fileobj=stream, mode="w") as output:
            for path in sorted(source.rglob("*")):
                if path.is_file():
                    output.add(path, arcname=path.relative_to(source), recursive=False)


def dockerignore(root):
    portable = json.loads((root / "nix/dotfiles.json").read_text())
    included = sorted(set(portable + EXTRA_FILES + ["nix/**", "tests/nix/**"]))
    return (
        "# Generated from `nix/dotfiles.json` and `nix/sources.py`.\n**\n"
        + "".join(f"!{name}\n" for name in included)
        + f"{DOOM}\n{DOOM}/**\n{RECEIPT}\n**/__pycache__\n**/*.pyc\n"
    )


if __name__ == "__main__":
    print(dockerignore(Path(__file__).resolve().parents[1]), end="")
