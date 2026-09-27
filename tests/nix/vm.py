#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import platform
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time
import urllib.request


ROOT = Path(__file__).resolve().parents[2]


def run(args, **kwargs):
    return subprocess.run([str(arg) for arg in args], check=True, **kwargs)


class VM:
    def __init__(self, arch, directory, private_doom=False):
        self.arch = arch
        self.private_doom = private_doom
        self.directory = Path(directory)
        self.key = self.directory / "identity"
        self.process = None
        self.resumed = False
        self.memory_before = {}
        self.ssh = [
            "ssh",
            "-i",
            str(self.key),
            "-p",
            "2222",
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "UserKnownHostsFile=/dev/null",
            "-o",
            "LogLevel=ERROR",
            "-o",
            "ConnectTimeout=5",
            "-o",
            "BatchMode=yes",
            "tester@127.0.0.1",
        ]

    def remote(self, command, **kwargs):
        return run([*self.ssh, command], **kwargs)

    def wait(self):
        deadline = time.monotonic() + 1200
        while time.monotonic() < deadline:
            if self.process and self.process.poll() is not None:
                status = self.process.returncode
                detail = signal.Signals(-status).name if status < 0 else str(status)
                raise RuntimeError(
                    f"QEMU exited ({detail}); inspect {self.directory}/failure.json and qemu.log"
                )
            try:
                self.remote(
                    "true", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
                self.remote("sudo cloud-init status --wait")
                return
            except subprocess.CalledProcessError:
                time.sleep(5)
        raise RuntimeError(
            f"VM did not become ready; inspect {self.directory}/serial.log"
        )

    def prepare(self):
        self.directory.mkdir(parents=True)
        metadata = json.loads((ROOT / "tests/nix/vm-images.json").read_text())
        info = metadata["images"][self.arch]
        base = self.directory / info["name"]
        if not base.exists():
            urllib.request.urlretrieve(f"{metadata['baseUrl']}/{info['name']}", base)
        with base.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        if digest != info["sha256"]:
            raise RuntimeError("Ubuntu cloud image checksum mismatch")
        run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", self.key])
        public_key = self.key.with_suffix(".pub").read_text().strip()
        (self.directory / "user-data").write_text(
            "#cloud-config\nusers:\n  - name: tester\n    groups: [sudo]\n"
            "    shell: /bin/bash\n    lock_passwd: true\n"
            "    sudo: ALL=(ALL) NOPASSWD:ALL\n    ssh_authorized_keys:\n"
            f"      - {public_key}\nssh_pwauth: false\ndisable_root: true\n"
        )
        (self.directory / "meta-data").write_text(
            "instance-id: dotfiles-test\nlocal-hostname: dotfiles-test\n"
        )
        run(
            [
                "cloud-localds",
                self.directory / "seed.img",
                self.directory / "user-data",
                self.directory / "meta-data",
            ]
        )
        disk = self.directory / "disk.qcow2"
        run(["qemu-img", "create", "-f", "qcow2", "-F", "qcow2", "-b", base, disk])
        run(["qemu-img", "resize", disk, "64G"])
        (self.directory / "vm.json").write_text(
            json.dumps({"arch": self.arch, "private_doom": self.private_doom}) + "\n"
        )

    def start(self):
        self.resumed = self.directory.exists()
        if self.resumed:
            metadata = self.directory / "vm.json"
            if not metadata.exists():
                raise RuntimeError(
                    "VM preparation was interrupted; retain the logs and start a fresh trial"
                )
            if json.loads(metadata.read_text()) != {
                "arch": self.arch,
                "private_doom": self.private_doom,
            }:
                raise RuntimeError(
                    "Retained VM configuration does not match this invocation"
                )
        else:
            self.prepare()
        self.boot()
        self.wait()
        copied = self.directory / "source-copied"
        if not copied.exists():
            self.copy_source()

    def boot(self):
        disk = self.directory / "disk.qcow2"
        if self.arch == "aarch64-linux":
            machine = [
                "qemu-system-aarch64",
                "-machine",
                "virt,gic-version=3",
                "-cpu",
                "cortex-a72",
                "-bios",
                "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd",
            ]
        else:
            machine = ["qemu-system-x86_64", "-machine", "q35", "-cpu", "max"]
        native = {"arm64": "aarch64", "AMD64": "x86_64"}.get(
            platform.machine(), platform.machine()
        )
        accelerator = (
            "kvm"
            if os.access("/dev/kvm", os.R_OK | os.W_OK)
            and self.arch == native + "-linux"
            else "tcg,thread=multi"
        )
        if accelerator == "kvm":
            machine[machine.index("-cpu") + 1] = "host"
        self.memory_before = self.memory_status()
        with (self.directory / "qemu.log").open("a") as stderr:
            self.process = subprocess.Popen(
                [
                    *machine,
                    "-accel",
                    accelerator,
                    "-smp",
                    "4",
                    "-m",
                    "4096",
                    "-drive",
                    f"file={disk},if=virtio,format=qcow2",
                    "-drive",
                    f"file={self.directory}/seed.img,if=virtio,format=raw,readonly=on",
                    "-netdev",
                    "user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22",
                    "-device",
                    "virtio-net-pci,netdev=net0",
                    "-device",
                    "virtio-gpu-pci",
                    "-object",
                    "rng-random,filename=/dev/urandom,id=rng0",
                    "-device",
                    "virtio-rng-pci,rng=rng0",
                    "-display",
                    "none",
                    "-monitor",
                    "none",
                    "-chardev",
                    f"file,id=serial0,path={self.directory}/serial.log,append=on",
                    "-serial",
                    "chardev:serial0",
                ],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=stderr,
                start_new_session=True,
            )

    @staticmethod
    def memory_status():
        result = {}
        for name in ("memory.current", "memory.peak", "memory.max", "memory.events"):
            path = Path("/sys/fs/cgroup") / name
            try:
                result[name] = path.read_text().strip()
            except OSError:
                pass
        return result

    def diagnose(self, error):
        self.directory.mkdir(parents=True, exist_ok=True)
        status = self.process.poll() if self.process else None
        report = {
            "error": str(error) or type(error).__name__,
            "qemu_exit_status": status,
            "qemu_signal": signal.Signals(-status).name
            if status is not None and status < 0
            else None,
            "memory_before": self.memory_before,
            "memory_after": self.memory_status(),
        }
        destination = self.directory / f"failure-{time.time_ns()}.json"
        print(json.dumps(report, indent=2), flush=True)
        try:
            destination.write_text(json.dumps(report, indent=2) + "\n")
            (self.directory / "failure.json").write_text(destination.read_text())
        except OSError as failure:
            print(f"Could not save failure diagnostics: {failure}", file=sys.stderr)

    def copy_source(self):
        archive = (
            Path("/tmp/private-source.tar")
            if self.private_doom
            else self.directory / "source.tar"
        )
        if not self.private_doom:
            run(["tar", "-cf", archive, "-C", ROOT, "."])
        self.remote("mkdir -p /home/tester/dotfiles")
        with archive.open("rb") as stream:
            self.remote("tar -xf - -C /home/tester/dotfiles", stdin=stream)
        (self.directory / "source-copied").touch()
        archive.unlink()

    def reboot(self):
        before = self.remote(
            "cat /proc/sys/kernel/random/boot_id", capture_output=True, text=True
        ).stdout.strip()
        self.remote("sudo systemctl reboot")
        time.sleep(10)
        self.wait()
        after = self.remote(
            "cat /proc/sys/kernel/random/boot_id", capture_output=True, text=True
        ).stdout.strip()
        if before == after:
            raise RuntimeError("VM did not reboot")

    def explore(self):
        if self.resumed:
            print(
                "\nResumed the retained Ubuntu disk. Source and configuration are preserved.\n",
                flush=True,
            )
        else:
            self.installation_instructions()
        print(
            "Exit the shell to reconnect or delete the VM. Reboots preserve this session's disk.\n"
            "Choose q to delete it; interruptions and failures retain it for recovery.\n"
            "No graphical console is attached.\n",
            flush=True,
        )
        while True:
            self.wait()
            subprocess.run([*self.ssh[:-1], "-t", self.ssh[-1]], check=False)
            while True:
                choice = input("[r] Reconnect (also after reboot), [q] delete VM: ")
                if choice.strip().lower() == "q":
                    return
                if choice.strip().lower() == "r":
                    break

    def installation_instructions(self):
        print(
            "\nUbuntu is ready. Nix and the workstation configuration are not installed.\n"
            "Repository source is copied to ~/dotfiles; it is not activated.\n"
            "Inside the guest, start with:\n\n"
            "  cd ~/dotfiles\n",
            flush=True,
        )
        if self.arch == "aarch64-linux":
            print(
                "  sed -i 's/x86_64-linux/aarch64-linux/' nix/hosts/personal-desktop.nix\n",
                flush=True,
            )
        if self.private_doom:
            print(
                "  bash bin/install --host personal-desktop\n\nThe guest contains your pinned private Doom configuration, without Git credentials.\n",
                flush=True,
            )
        else:
            print(
                "  DOTFILES_TEST_GUEST=1 bash bin/install --host personal-desktop --public-doom\n\nThis uses a minimal public Doom configuration and the full user package selection.\nUse --fixture instead of --public-doom for a reduced package selection.\n",
                flush=True,
            )
        print(
            "If user files conflict, inspect them before repeating with --adopt.\n",
            flush=True,
        )

    def close(self):
        if self.process and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=30)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()


def session(vm, interactive=False, upgrade_from_previous=False):
    discard = not interactive
    try:
        vm.start()
        if interactive:
            vm.explore()
            discard = True
            return
        if upgrade_from_previous:
            vm.remote(
                "cd dotfiles && DOTFILES_TEST_GUEST=1 bash tests/nix/bootstrap-previous.sh"
            )
        else:
            vm.remote("cd dotfiles && bash bin/bootstrap")
        for stage in ["install", "containers", "boot", "update", "rollback-boot"]:
            print(f"Testing {vm.arch}: {stage}", flush=True)
            if stage in ("boot", "rollback-boot"):
                vm.reboot()
            vm.remote(
                f"cd dotfiles && DOTFILES_TEST_GUEST=1 bash tests/nix/system.sh {stage}"
            )
    except BaseException as error:
        vm.diagnose(error)
        if not interactive:
            for name in ("qemu.log", "serial.log"):
                path = vm.directory / name
                if path.exists():
                    print(
                        json.dumps({name: path.read_text(errors="replace")[-16000:]}),
                        flush=True,
                    )
        raise
    finally:
        vm.close()
        if discard:
            shutil.rmtree(vm.directory, ignore_errors=True)
        else:
            print(
                f"Retained VM disk and logs in {vm.directory} inside this container.",
                flush=True,
            )


def main():
    if os.environ.get("DOTFILES_TEST_GUEST") != "1" or not Path("/.dockerenv").exists():
        raise RuntimeError("Run this driver inside the disposable Docker VM runner")
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--arch", choices=["aarch64-linux", "x86_64-linux"], required=True
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--upgrade-from-previous", action="store_true")
    mode.add_argument("--interactive", action="store_true")
    parser.add_argument("--private-doom", action="store_true")
    args = parser.parse_args()
    if args.private_doom and not args.interactive:
        parser.error("--private-doom requires --interactive")
    if args.interactive and not sys.stdin.isatty():
        parser.error("--interactive requires a terminal")
    directory = Path("/tmp/dotfiles-vm")
    if directory.exists() and not args.interactive:
        raise RuntimeError("Use a fresh runner for each VM test")
    session(
        VM(args.arch, directory, private_doom=args.private_doom),
        interactive=args.interactive,
        upgrade_from_previous=args.upgrade_from_previous,
    )


if __name__ == "__main__":
    main()
