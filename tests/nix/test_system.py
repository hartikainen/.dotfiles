import importlib.util
import json
import os
import stat
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "system_transaction",
    Path(__file__).resolve().parents[2] / "nix/system-transaction.py",
)
transaction = importlib.util.module_from_spec(spec)
spec.loader.exec_module(transaction)


class SystemTransactions(unittest.TestCase):
    def test_unsupported_os_stops_before_package_inspection(self):
        with (
            patch.object(Path, "read_text", return_value="systemd\n"),
            patch.object(
                transaction.platform,
                "freedesktop_os_release",
                return_value={"ID": "debian", "VERSION_ID": "13"},
            ),
            patch.object(transaction.subprocess, "run") as run,
        ):
            with self.assertRaisesRegex(RuntimeError, "requires Ubuntu 26.04"):
                transaction.preflight(Path("/unused"), None, False)
            run.assert_not_called()

    def test_registration_must_change_the_active_profile(self):
        with (
            patch.object(transaction, "engine"),
            patch.object(transaction, "current", return_value=Path("/old")),
        ):
            with self.assertRaisesRegex(RuntimeError, "did not register"):
                transaction.register(Path("/candidate"))

    def test_native_package_conflict_stops_before_activation(self):
        with (
            patch.object(transaction, "current", return_value=None),
            patch.object(
                transaction,
                "preflight",
                side_effect=[[], RuntimeError("native package conflict")],
            ),
            patch.object(transaction, "run"),
            patch.object(transaction, "engine") as engine,
        ):
            with self.assertRaisesRegex(RuntimeError, "native package conflict"):
                transaction.apply(Path("/candidate"), False, {"adoptions": {}})
            engine.assert_not_called()

    def test_logged_activation_error_is_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            profile = Path(directory)
            (profile / "bin").mkdir()
            script = profile / "bin/activate"
            script.write_text("#!/bin/sh\necho 'ERROR failed to start unit'\nexit 0\n")
            script.chmod(0o755)
            with self.assertRaisesRegex(RuntimeError, "activate failed"):
                transaction.engine(profile, "activate")

    def test_system_commands_do_not_inherit_backup_umask(self):
        with tempfile.TemporaryDirectory() as directory:
            profile = Path(directory)
            (profile / "bin").mkdir()
            script = profile / "bin/activate"
            script.write_text('#!/bin/sh\nprintf x > "$0.mode"\n')
            script.chmod(0o755)
            before = os.umask(0o077)
            try:
                transaction.engine(profile, "activate")
                transaction.run(
                    ["/bin/sh", "-c", 'printf x > "$1"', "sh", profile / "native.mode"]
                )
            finally:
                os.umask(before)
            for path in (profile / "bin/activate.mode", profile / "native.mode"):
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o644)

    def test_failed_health_restores_before_registering(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            previous, candidate = state / "old", state / "candidate"
            with (
                patch.object(transaction, "STATE", state),
                patch.object(transaction, "PENDING_ROOT", state / "pending"),
                patch.object(transaction, "current", return_value=previous),
                patch.object(transaction, "preflight", return_value=[]),
                patch.object(transaction, "run"),
                patch.object(transaction, "engine"),
                patch.object(
                    transaction, "healthy", side_effect=RuntimeError("unhealthy")
                ),
                patch.object(transaction, "register") as register,
                patch.object(transaction, "restore") as restore,
                patch.object(transaction, "files", return_value={}),
            ):
                with self.assertRaisesRegex(RuntimeError, "unhealthy"):
                    transaction.apply(candidate, False, {"adoptions": {}})
                register.assert_not_called()
                restore.assert_called_once_with(previous, candidate, {})
                self.assertNotIn(
                    "pending", json.loads((state / "state.json").read_text())
                )
                self.assertFalse((state / "pending").is_symlink())

    def test_failed_update_restores_adopted_manual_edit(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            etc = state / "etc"
            etc.mkdir()
            target = etc / "setting"
            target.write_text("manual edit")
            old_source = state / "old-source"
            old_source.write_text("old declaration")
            previous, candidate = state / "old", state / "candidate"

            def restore(*args):
                target.symlink_to(old_source)

            with (
                patch.object(transaction, "STATE", state),
                patch.object(transaction, "ETC", etc),
                patch.object(transaction, "PENDING_ROOT", state / "pending"),
                patch.object(transaction, "current", return_value=previous),
                patch.object(transaction, "preflight", return_value=[target]),
                patch.object(transaction, "run"),
                patch.object(
                    transaction, "engine", side_effect=RuntimeError("activation")
                ),
                patch.object(transaction, "restore", side_effect=restore),
                patch.object(transaction, "files", return_value={target: old_source}),
            ):
                with self.assertRaisesRegex(RuntimeError, "activation"):
                    transaction.apply(candidate, True, {"adoptions": {}})
            self.assertFalse(target.is_symlink())
            self.assertEqual(target.read_text(), "manual edit")
            self.assertEqual(
                json.loads((state / "state.json").read_text())["adoptions"], {}
            )

    def test_failed_recovery_retains_pending_generation(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            previous, candidate = state / "old", state / "candidate"
            with (
                patch.object(transaction, "STATE", state),
                patch.object(transaction, "PENDING_ROOT", state / "pending"),
                patch.object(transaction, "current", return_value=previous),
                patch.object(transaction, "preflight", return_value=[]),
                patch.object(transaction, "run"),
                patch.object(
                    transaction, "engine", side_effect=RuntimeError("activation")
                ),
                patch.object(
                    transaction, "restore", side_effect=RuntimeError("recovery")
                ),
            ):
                with self.assertRaisesRegex(RuntimeError, "activation"):
                    transaction.apply(candidate, False, {"adoptions": {}})
                self.assertEqual(
                    json.loads((state / "state.json").read_text())["pending"]["target"],
                    str(candidate),
                )
                self.assertEqual((state / "pending").resolve(), candidate)


if __name__ == "__main__":
    unittest.main()
