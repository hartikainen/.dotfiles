import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch


ROOT = Path(__file__).resolve().parents[2]


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


driver = load("vm_driver", "tests/nix/vm.py")
launcher = load("vm_launcher", "bin/test-vm")


class VMRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name) / "vm"
        self.directory.mkdir()
        self.disk = self.directory / "disk.qcow2"
        self.disk.write_text("guest changes")
        (self.directory / "identity").write_text("guest-only key")
        (self.directory / "vm.json").write_text(
            json.dumps({"arch": "x86_64-linux", "private_doom": False})
        )
        (self.directory / "source-copied").touch()

    def test_resume_preserves_disk_key_and_guest_source(self):
        vm = driver.VM("x86_64-linux", self.directory)
        with (
            patch.object(vm, "prepare") as prepare,
            patch.object(vm, "boot"),
            patch.object(vm, "wait"),
            patch.object(vm, "copy_source") as copy,
        ):
            vm.start()
        prepare.assert_not_called()
        copy.assert_not_called()
        self.assertTrue(vm.resumed)
        self.assertEqual(self.disk.read_text(), "guest changes")
        self.assertEqual(vm.key.read_text(), "guest-only key")

    def test_resume_rejects_different_architecture_without_booting(self):
        vm = driver.VM("aarch64-linux", self.directory)
        with patch.object(vm, "boot") as boot:
            with self.assertRaisesRegex(RuntimeError, "does not match"):
                vm.start()
        boot.assert_not_called()
        self.assertTrue(self.disk.exists())

    def test_incomplete_preparation_is_not_overwritten(self):
        (self.directory / "vm.json").unlink()
        vm = driver.VM("x86_64-linux", self.directory)
        with self.assertRaisesRegex(RuntimeError, "preparation was interrupted"):
            vm.start()
        self.assertEqual(self.disk.read_text(), "guest changes")

    def test_interactive_failure_preserves_disk_and_key(self):
        vm = Mock(directory=self.directory)
        vm.start.side_effect = RuntimeError("QEMU exited")
        with self.assertRaisesRegex(RuntimeError, "QEMU exited"):
            driver.session(vm, interactive=True)
        vm.diagnose.assert_called_once()
        vm.close.assert_called_once()
        self.assertTrue(self.disk.exists())
        self.assertTrue((self.directory / "identity").exists())

    def test_explicit_quit_discards_disk(self):
        vm = Mock(directory=self.directory)
        driver.session(vm, interactive=True)
        self.assertFalse(self.directory.exists())

    def test_automated_failure_discards_disk(self):
        vm = Mock(directory=self.directory)
        vm.start.side_effect = RuntimeError("QEMU exited")
        with self.assertRaisesRegex(RuntimeError, "QEMU exited"):
            driver.session(vm)
        self.assertFalse(self.directory.exists())

    def test_failure_records_signal_and_memory_events_without_terminal_escapes(self):
        vm = driver.VM("x86_64-linux", self.directory)
        vm.process = Mock(returncode=-9)
        vm.process.poll.return_value = -9
        vm.memory_before = {"memory.events": "oom_kill 0"}
        with patch.object(
            vm, "memory_status", return_value={"memory.events": "oom_kill 1"}
        ):
            vm.diagnose(RuntimeError("failure\x1b[2J"))
        text = (self.directory / "failure.json").read_text()
        self.assertNotIn("\x1b", text)
        report = json.loads(text)
        self.assertEqual(report["qemu_signal"], "SIGKILL")
        self.assertEqual(report["qemu_exit_status"], -9)
        self.assertEqual(report["memory_after"]["memory.events"], "oom_kill 1")
        with self.assertRaisesRegex(RuntimeError, "SIGKILL"):
            vm.wait()

    def test_launcher_retains_container_after_failure(self):
        with patch.object(launcher.subprocess, "run") as run:
            run.return_value = Mock(returncode=0, stdout='{"Status":"exited"}')
            launcher.finish("dotfiles-vm-test", retain=True)
        self.assertEqual(run.call_count, 1)
        self.assertEqual(run.call_args.args[0][1], "inspect")

    def test_launcher_does_not_delete_on_inspection_failure(self):
        with patch.object(launcher.subprocess, "run") as run:
            run.return_value = Mock(returncode=1, stderr="Docker unavailable")
            launcher.finish("dotfiles-vm-test", retain=True)
        self.assertEqual(run.call_count, 1)

    def test_launcher_removes_container_and_image_after_explicit_quit(self):
        with patch.object(launcher.subprocess, "run") as run:
            launcher.finish("dotfiles-vm-test", retain=False)
        self.assertEqual(
            [call.args[0] for call in run.call_args_list],
            [
                ["docker", "rm", "-f", "dotfiles-vm-test"],
                ["docker", "image", "rm", "dotfiles-vm-test"],
            ],
        )
