import fcntl
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


loader = importlib.machinery.SourceFileLoader(
    "macos_vm", str(Path(__file__).resolve().parents[2] / "bin/macos-vm")
)
spec = importlib.util.spec_from_loader(loader.name, loader)
vm = importlib.util.module_from_spec(spec)
loader.exec_module(vm)


class MacOSVMTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name) / "VM trial"

    def test_create_preserves_existing_directory(self):
        self.directory.mkdir()
        disk = self.directory / "Disk.img"
        disk.write_bytes(b"existing guest")
        with patch.object(vm, "build") as build, self.assertRaises(RuntimeError):
            vm.create(self.directory, None)
        build.assert_not_called()
        self.assertEqual(disk.read_bytes(), b"existing guest")

    def test_create_checks_space_before_building(self):
        with (
            patch.object(vm.shutil, "disk_usage", return_value=SimpleNamespace(free=0)),
            patch.object(vm, "build") as build,
            self.assertRaises(RuntimeError),
        ):
            vm.create(self.directory, None)
        build.assert_not_called()
        self.assertFalse(self.directory.exists())

    def test_failed_install_keeps_artifacts_without_success_marker(self):
        def fail_install(*args, **kwargs):
            (self.directory / "VM.bundle").mkdir()
            raise subprocess.CalledProcessError(1, "installer")

        with (
            patch.object(
                vm.shutil, "disk_usage", return_value=SimpleNamespace(free=10**12)
            ),
            patch.object(vm, "build"),
            patch.object(vm, "run", side_effect=fail_install),
            self.assertRaises(subprocess.CalledProcessError),
        ):
            vm.create(self.directory, None)
        self.assertTrue((self.directory / "VM.bundle").is_dir())
        self.assertFalse((self.directory / "installed").exists())

    def test_install_preserves_home_and_passes_ipsw_as_one_argument(self):
        ipsw = Path(self.temporary.name) / "restore image.ipsw"
        ipsw.touch()
        with (
            patch.object(
                vm.shutil, "disk_usage", return_value=SimpleNamespace(free=10**12)
            ),
            patch.object(vm, "build"),
            patch.object(vm, "run") as run,
        ):
            vm.create(self.directory, ipsw)
        self.assertTrue((self.directory / "installed").is_file())
        self.assertEqual(run.call_args.args[0][-1], ipsw)
        environment = run.call_args.kwargs["env"]
        self.assertEqual(environment.get("HOME"), os.environ.get("HOME"))
        self.assertEqual(
            environment["DOTFILES_VM_BUNDLE"], str(self.directory / "VM.bundle")
        )

    def test_start_requires_completed_installation(self):
        with patch.object(vm, "run") as run, self.assertRaises(RuntimeError):
            vm.start(self.directory)
        run.assert_not_called()

    def test_running_vm_cannot_be_started_twice(self):
        self.directory.mkdir()
        (self.directory / "installed").touch()
        with (self.directory / "run.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with patch.object(vm, "run") as run, self.assertRaises(RuntimeError):
                vm.start(self.directory)
            run.assert_not_called()

    def test_invalid_archive_is_rejected_before_extraction(self):
        archive = Path(self.temporary.name) / "sample.zip"
        archive.write_bytes(b"unexpected upstream contents")
        with self.assertRaisesRegex(RuntimeError, "checksum"):
            vm.prepare_source(archive, self.directory)
        self.assertFalse(self.directory.exists())

    @unittest.skipUnless(
        os.environ.get("APPLE_VM_SAMPLE_ARCHIVE"), "Apple sample not supplied"
    )
    def test_pinned_apple_source_can_be_prepared(self):
        vm.prepare_source(Path(os.environ["APPLE_VM_SAMPLE_ARCHIVE"]), self.directory)
        paths = (self.directory / "Swift/Common/Path.swift").read_text()
        self.assertNotIn("NSHomeDirectory", paths)
        self.assertIn('environment["DOTFILES_VM_BUNDLE"]!', paths)
        installer = (
            self.directory / "Swift/InstallationTool/MacOSVirtualMachineInstaller.swift"
        ).read_text()
        self.assertIn(
            'NSLog("Installation succeeded.")\n                exit(0)', installer
        )
        self.assertIn("virtualMachineConfiguration.audioDevices = []", installer)
        app = (
            self.directory / "Swift/macOSVirtualMachineSampleApp/AppDelegate.swift"
        ).read_text()
        self.assertNotIn("AAUSBAccessory", app)
        self.assertNotIn("setGuestProvisioning", app)


if __name__ == "__main__":
    unittest.main()
