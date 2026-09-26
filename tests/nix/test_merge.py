import importlib.util
from pathlib import Path
import tempfile
import unittest


try:
    import tomli_w
except ImportError:
    tomli_w = None


@unittest.skipUnless(tomli_w, "TOML tests run in the Nix check environment")
class MergeTests(unittest.TestCase):
    def setUp(self):
        source = Path(__file__).resolve().parents[2] / "nix/merge-settings.py"
        spec = importlib.util.spec_from_file_location("settings", source)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_toml_preserves_machine_tables_and_replaces_owned_values(self):
        target = self.root / "config.toml"
        seed = self.root / "seed.toml"
        target.write_text(
            'model = "personal"\n[projects."/path.with.dots"]\ntrust_level = "trusted"\n'
        )
        seed.write_text(
            'model = "managed"\n[agents.worker]\nconfig_file = "worker.toml"\n'
        )
        self.module.apply(target, seed)
        value = self.module.tomllib.loads(target.read_text())
        self.assertEqual(value["projects"]["/path.with.dots"]["trust_level"], "trusted")
        self.assertEqual(value["model"], "managed")
        inode = target.stat().st_ino
        self.module.apply(target, seed)
        self.assertEqual(target.stat().st_ino, inode)

    def test_invalid_input_does_not_replace_settings(self):
        target = self.root / "config.toml"
        seed = self.root / "seed.toml"
        target.write_text('model = "personal"\n')
        seed.write_text("invalid = [")
        with self.assertRaises(ValueError):
            self.module.apply(target, seed)
        self.assertEqual(target.read_text(), 'model = "personal"\n')

    def test_symlinked_parent_is_rejected(self):
        (self.root / "real").mkdir()
        (self.root / "linked").symlink_to(self.root / "real", target_is_directory=True)
        seed = self.root / "seed.json"
        seed.write_text("{}")
        with self.assertRaisesRegex(RuntimeError, "symlink"):
            self.module.apply(self.root / "linked/config.json", seed)
