from pathlib import Path
import plistlib
import runpy
import subprocess
import unittest
from unittest.mock import patch


shortcuts = runpy.run_path(
    str(Path(__file__).resolve().parents[2] / "nix/macos-shortcuts.py")
)


class MacShortcutsTests(unittest.TestCase):
    def test_preserve_unmanaged_keys_and_replace_owned_entries(self):
        existing = {
            "unrelated": ["keep"],
            "AppleSymbolicHotKeys": {"60": {"enabled": True}, "98": {"enabled": False}},
        }
        managed = {"60": {"enabled": False, "value": {"type": "standard"}}}
        updated = shortcuts["merge"](existing, managed)
        self.assertEqual(updated["unrelated"], ["keep"])
        self.assertEqual(updated["AppleSymbolicHotKeys"]["98"], {"enabled": False})
        self.assertEqual(updated["AppleSymbolicHotKeys"]["60"], managed["60"])
        self.assertTrue(existing["AppleSymbolicHotKeys"]["60"]["enabled"])
        self.assertEqual(shortcuts["merge"](updated, managed), updated)

    def test_unchanged_settings_refresh_without_writing(self):
        managed = {"60": {"enabled": False}}
        result = subprocess.CompletedProcess(
            [], 0, plistlib.dumps({"AppleSymbolicHotKeys": managed})
        )
        with patch("subprocess.run", return_value=result) as run:
            shortcuts["apply"](managed)
        self.assertEqual(run.call_count, 2)
        self.assertEqual(
            run.call_args.args[0],
            [
                "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings",
                "-u",
            ],
        )
        self.assertTrue(run.call_args.kwargs["check"])

    def test_missing_domain_can_be_created(self):
        result = subprocess.CompletedProcess(
            [], 1, b"", b"Domain com.apple.symbolichotkeys does not exist"
        )
        with patch("subprocess.run", return_value=result) as run:
            shortcuts["apply"]({"60": {"enabled": False}})
        self.assertEqual(run.call_count, 3)
        self.assertEqual(
            plistlib.loads(run.call_args_list[1].kwargs["input"]),
            {"AppleSymbolicHotKeys": {"60": {"enabled": False}}},
        )
        self.assertEqual(run.call_args.args[0][-1], "-u")

    def test_import_failure_does_not_refresh_settings(self):
        result = subprocess.CompletedProcess([], 0, plistlib.dumps({}))
        with patch(
            "subprocess.run",
            side_effect=[result, subprocess.CalledProcessError(1, "defaults")],
        ) as run:
            with self.assertRaises(subprocess.CalledProcessError):
                shortcuts["apply"]({"60": {"enabled": False}})
        self.assertEqual(run.call_count, 2)

    def test_read_failure_does_not_overwrite_preferences(self):
        for result in [
            subprocess.CompletedProcess([], 1, b"", b"Permission denied"),
            subprocess.CompletedProcess([], 0, b"corrupt plist", b""),
            subprocess.CompletedProcess(
                [], 0, plistlib.dumps({"AppleSymbolicHotKeys": []}), b""
            ),
        ]:
            with (
                self.subTest(result=result),
                patch("subprocess.run", return_value=result) as run,
            ):
                with self.assertRaises(
                    (RuntimeError, ValueError, plistlib.InvalidFileException)
                ):
                    shortcuts["apply"]({"60": {"enabled": False}})
                self.assertEqual(run.call_count, 1)
