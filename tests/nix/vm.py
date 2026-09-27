#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import platform
from pathlib import Path
import shutil
import subprocess
import time
import urllib.request


ROOT = Path(__file__).resolve().parents[2]


def run(args, **kwargs):
    return subprocess.run([str(arg) for arg in args], check=True, **kwargs)


class VM:
    def __init__(self, arch, directory):
        self.arch = arch
        self.directory = Path(directory)
        self.key = self.directory / "identity"
        self.process = None
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
                raise RuntimeError(f"QEMU exited; inspect {self.directory}/serial.log")
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

    def start(self):
        self.directory.mkdir(parents=True, exist_ok=True)
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
                "-serial",
                f"file:{self.directory}/serial.log",
            ],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=(self.directory / "qemu.log").open("w"),
        )
        self.wait()
        self.copy_source()

    def copy_source(self):
        archive = self.directory / "source.tar"
        run(["tar", "-cf", archive, "-C", ROOT, "."])
        self.remote("mkdir -p /home/tester/dotfiles")
        with archive.open("rb") as stream:
            self.remote("tar -xf - -C /home/tester/dotfiles", stdin=stream)
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

    def close(self):
        if self.process:
            self.process.terminate()
            self.process.wait(timeout=30)
        self.key.unlink(missing_ok=True)


def main():
    if os.environ.get("DOTFILES_TEST_GUEST") != "1" or not Path("/.dockerenv").exists():
        raise RuntimeError("Run this driver inside the disposable Docker VM runner")
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--arch", choices=["aarch64-linux", "x86_64-linux"], required=True
    )
    parser.add_argument("--upgrade-from-previous", action="store_true")
    args = parser.parse_args()
    directory = Path("/tmp/dotfiles-vm")
    if directory.exists():
        raise RuntimeError("Use a fresh runner for each VM test")
    vm = VM(args.arch, directory)
    try:
        vm.start()
        if args.upgrade_from_previous:
            vm.remote(
                "cd dotfiles && DOTFILES_TEST_GUEST=1 bash tests/nix/bootstrap-previous.sh"
            )
        else:
            vm.remote("cd dotfiles && bash bin/bootstrap")
        for stage in ["install", "containers", "boot", "update", "rollback-boot"]:
            print(f"Testing {args.arch}: {stage}", flush=True)
            if stage in ("boot", "rollback-boot"):
                vm.reboot()
            vm.remote(
                f"cd dotfiles && DOTFILES_TEST_GUEST=1 bash tests/nix/system.sh {stage}"
            )
    except BaseException:
        for name in ("qemu.log", "serial.log"):
            path = directory / name
            if path.exists():
                print(path.read_text(errors="replace")[-16000:], flush=True)
        raise
    finally:
        vm.close()
        shutil.rmtree(directory, ignore_errors=True)


if __name__ == "__main__":
    main()
