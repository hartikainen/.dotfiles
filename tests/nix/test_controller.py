import importlib.machinery
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import types
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
loader = importlib.machinery.SourceFileLoader("dotfiles", str(ROOT / "bin/dotfiles"))
spec = importlib.util.spec_from_loader(loader.name, loader)
controller = importlib.util.module_from_spec(spec)
loader.exec_module(controller)


class ActivationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / "home"
        self.home.mkdir()
        self.state = self.base / "state"
        self.state.mkdir()
        self.home_patch = patch.object(Path, "home", return_value=self.home)
        profile_patch = patch.object(
            controller, "home_profile", return_value=self.state / "home-manager"
        )
        profile_patch.start()
        self.addCleanup(profile_patch.stop)
        self.home_patch.start()
        self.addCleanup(self.home_patch.stop)

    def generation(self, name, files):
        generation = self.base / name
        for relative, contents in files.items():
            source = generation / "source" / relative
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_text(contents)
            link = generation / "home-files" / relative
            link.parent.mkdir(parents=True, exist_ok=True)
            link.symlink_to(source)
        return generation

    def test_conflicts_require_adoption(self):
        generation = self.generation("candidate", {".bashrc": "managed"})
        target = self.home / ".bashrc"
        target.write_text("personal")
        with self.assertRaisesRegex(RuntimeError, "Unmanaged paths"):
            controller.activate(
                generation, types.SimpleNamespace(adopt=False), self.state, None
            )
        self.assertEqual(target.read_text(), "personal")

    def test_foreign_parent_symlink_is_never_followed(self):
        generation = self.generation("candidate", {".config/tmux/tmux.conf": "managed"})
        outside = self.base / "outside"
        outside.mkdir()
        (self.home / ".config").symlink_to(outside)
        with self.assertRaisesRegex(RuntimeError, "parent"):
            controller.conflicts(generation, self.home)
        self.assertEqual(list(outside.iterdir()), [])

    def test_failed_activation_restores_files_and_mutable_settings(self):
        generation = self.generation("candidate", {".bashrc": "managed"})
        target = self.home / ".bashrc"
        target.write_text("personal")
        settings = self.home / ".codex/config.toml"
        settings.parent.mkdir()
        settings.write_text("machine-owned")

        def fail(*args, **kwargs):
            target.symlink_to(generation / "home-files/.bashrc")
            settings.write_text("partial-write")
            raise subprocess.CalledProcessError(1, "activate")

        with patch.object(controller, "run", side_effect=fail):
            with self.assertRaises(subprocess.CalledProcessError):
                controller.activate(
                    generation, types.SimpleNamespace(adopt=True), self.state, None
                )
        self.assertEqual(target.read_text(), "personal")
        self.assertFalse(target.is_symlink())
        self.assertEqual(settings.read_text(), "machine-owned")

    def test_owned_links_can_change_and_repeat_without_adoption(self):
        old = self.generation("old", {".bashrc": "old"})
        candidate = self.generation("candidate", {".bashrc": "candidate"})
        (self.home / ".bashrc").symlink_to(old / "home-files/.bashrc")
        self.assertEqual(controller.conflicts(candidate, self.home, old), [])
        self.assertEqual(controller.conflicts(old, self.home, old), [])

    def test_profile_recovery_failure_still_restores_settings(self):
        old = self.generation("old", {".bashrc": "old"})
        candidate = self.generation("candidate", {".bashrc": "candidate"})
        profile = self.state / "home-manager"
        profile.symlink_to("home-manager-1-link")
        (self.home / ".bashrc").symlink_to(old / "home-files/.bashrc")
        settings = self.home / ".codex/config.toml"
        settings.parent.mkdir()
        settings.write_text("personal")

        def fail(command, **kwargs):
            if command[0] == candidate / "activate":
                profile.unlink()
                profile.symlink_to("home-manager-2-link")
                settings.write_text("partial")
            raise subprocess.CalledProcessError(1, command)

        with patch.object(controller, "run", side_effect=fail):
            with self.assertRaises(subprocess.CalledProcessError):
                controller.activate(
                    candidate, types.SimpleNamespace(adopt=False), self.state, old
                )
        self.assertEqual(settings.read_text(), "personal")

    def test_settings_backup_rejects_symlinked_parent(self):
        outside = self.base / "outside"
        outside.mkdir()
        (outside / "config.toml").write_text("personal")
        (self.home / ".codex").symlink_to(outside)
        with self.assertRaisesRegex(RuntimeError, "symlink"):
            controller.merge_backups(self.state)
        self.assertEqual((outside / "config.toml").read_text(), "personal")

    def test_foreign_symlink_requires_adoption(self):
        generation = self.generation("candidate", {".bashrc": "managed"})
        (self.home / ".bashrc").symlink_to(self.base / "unrelated")
        self.assertEqual(
            controller.conflicts(generation, self.home), [self.home / ".bashrc"]
        )

    def test_system_failure_attempts_to_restore_previous_system(self):
        generation = self.generation("candidate", {".bashrc": "managed"})
        old_system = self.base / "old-system"
        old_system.mkdir()
        system = self.base / "candidate-system"
        profile = self.base / "system-profile"
        profile.symlink_to(old_system)
        calls = []

        def switch(value):
            calls.append(value)
            if value == system:
                raise subprocess.CalledProcessError(1, "activate")

        with (
            patch.object(controller, "SYSTEM_PROFILE", profile),
            patch.object(controller, "switch_system", side_effect=switch),
        ):
            with self.assertRaises(subprocess.CalledProcessError):
                controller.activate_pair(
                    generation,
                    system,
                    types.SimpleNamespace(adopt=False),
                    self.state,
                    None,
                )
        self.assertEqual(calls, [system, old_system])
        self.assertFalse((self.home / ".bashrc").exists())

    def test_snapshot_excludes_runtime_files(self):
        destination = self.base / "snapshot"
        destination.mkdir()
        controller.snapshot(ROOT, destination)
        self.assertFalse((destination / ".git").exists())
        self.assertFalse((destination / ".config/doom/.git").exists())
        self.assertFalse((destination / ".config/git/config.local").exists())
        self.assertFalse((destination / ".codex/config.toml").exists())
        self.assertTrue((destination / "nix/settings/codex.toml").exists())
        self.assertTrue((destination / "nix/hosts/work-macbook.nix").exists())

    def test_rollback_does_not_require_a_valid_source_checkout(self):
        state = self.home / ".local/state/dotfiles"
        state.mkdir(parents=True)
        generation = self.generation("retained", {".bashrc": "retained"})
        (state / "home-manager-1-link").symlink_to(generation)
        (state / "home-manager-2-link").symlink_to(generation)
        (state / "home-manager").symlink_to("home-manager-2-link")
        with (
            patch.dict(os.environ, {"DOTFILES_TEST_GUEST": "1"}, clear=True),
            patch.object(
                sys,
                "argv",
                ["dotfiles", "rollback", "--profile", "headless", "--fixture"],
            ),
            patch.object(
                controller, "snapshot", side_effect=AssertionError("source inspected")
            ),
            patch.object(controller.shutil, "which", return_value="/nix/bin/nix"),
            patch.object(controller, "activate_pair") as activate,
            patch.object(
                controller, "home_profile", return_value=state / "home-manager"
            ),
        ):
            controller.main()
        self.assertEqual(activate.call_args.args[0], generation)


class HostTests(unittest.TestCase):
    def setUp(self):
        self.host = {
            "system": "x86_64-linux",
            "profile": "desktop",
            "osRelease": {"ID": "ubuntu", "VERSION_ID": "26.04"},
        }
        self.args = types.SimpleNamespace(
            host="work-desktop", profile=None, fixture=True
        )

    def test_unknown_host_is_rejected(self):
        with patch.object(controller, "host_inventory", return_value={}):
            with self.assertRaisesRegex(RuntimeError, "Unknown host"):
                controller.resolve_host(self.args, ROOT)

    def test_wrong_architecture_is_rejected(self):
        with (
            patch.object(
                controller, "host_inventory", return_value={self.args.host: self.host}
            ),
            patch.object(controller, "system_name", return_value="aarch64-linux"),
            self.assertRaisesRegex(RuntimeError, "requires x86_64-linux"),
        ):
            controller.resolve_host(self.args, ROOT)

    def test_wrong_distribution_release_is_rejected(self):
        with (
            patch.object(
                controller, "host_inventory", return_value={self.args.host: self.host}
            ),
            patch.object(controller, "system_name", return_value="x86_64-linux"),
            patch.object(controller.platform, "system", return_value="Linux"),
            patch.object(
                controller.platform,
                "freedesktop_os_release",
                return_value={"ID": "ubuntu", "VERSION_ID": "24.04"},
            ),
            self.assertRaisesRegex(RuntimeError, "requires VERSION_ID=26.04"),
        ):
            controller.resolve_host(self.args, ROOT)

    def test_matching_host_selects_its_profile(self):
        with (
            patch.object(
                controller, "host_inventory", return_value={self.args.host: self.host}
            ),
            patch.object(controller, "system_name", return_value="x86_64-linux"),
            patch.object(controller.platform, "system", return_value="Linux"),
            patch.object(
                controller.platform,
                "freedesktop_os_release",
                return_value=self.host["osRelease"],
            ),
        ):
            controller.resolve_host(self.args, ROOT)
        self.assertEqual(self.args.profile, "desktop")

    def test_host_expression_uses_the_named_factory(self):
        home = controller.expression(ROOT, self.args, "home")
        system = controller.expression(ROOT, self.args, "darwin")
        self.assertIn(".lib.mkHostHome", home)
        self.assertIn(".lib.mkHostDarwin", system)
        self.assertIn("work-desktop", home)
        self.assertNotIn("profile", home)

    def test_linux_system_rollback_rejects_headless_generation_before_activation(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            with (
                patch.object(Path, "home", return_value=home),
                patch.dict(os.environ, {"DOTFILES_TEST_GUEST": "1"}, clear=True),
                patch.object(
                    sys, "argv", ["dotfiles", "rollback", "--system", "--fixture"]
                ),
                patch.object(controller.platform, "system", return_value="Linux"),
                patch.object(controller.shutil, "which", return_value="/nix/bin/nix"),
                patch.object(controller, "home_profile", return_value=home / "profile"),
                patch.object(
                    controller, "preceding_generation", return_value=home / "headless"
                ),
                patch.object(controller, "activate_pair") as activate,
                self.assertRaisesRegex(
                    RuntimeError, "no Linux desktop GPU integration"
                ),
            ):
                controller.main()
            activate.assert_not_called()


if __name__ == "__main__":
    unittest.main()
