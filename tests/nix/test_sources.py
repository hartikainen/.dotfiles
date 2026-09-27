import json
from pathlib import Path
import runpy
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
sources = runpy.run_path(str(ROOT / "nix/sources.py"))


class SourcesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.doom = self.root / ".config/doom"
        self.doom.mkdir(parents=True)
        self.git(self.root, "init", "-q")
        self.git(self.doom, "init", "-q")
        for name in ("config.el", "init.el", "packages.el"):
            (self.doom / name).write_text(";; fixture\n")
        self.git(self.doom, "add", ".")
        self.git(
            self.doom,
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "Fixture",
        )
        self.revision = self.git(self.doom, "rev-parse", "HEAD")
        self.git(
            self.root,
            "update-index",
            "--add",
            "--cacheinfo",
            f"160000,{self.revision},.config/doom",
        )

    def git(self, root, *args):
        return subprocess.check_output(
            ["git", "-C", str(root), *args], text=True
        ).strip()

    def test_submodule_reference_is_the_pin(self):
        receipt = sources["doom_receipt"](self.root)
        self.assertEqual(receipt["revision"], self.revision)
        self.assertEqual(set(receipt["files"]), {"init.el", "config.el", "packages.el"})
        self.git(
            self.root, "update-index", "--cacheinfo", f"160000,{'1' * 40},.config/doom"
        )
        with self.assertRaisesRegex(RuntimeError, "submodule reference"):
            sources["doom_receipt"](self.root)

    def test_dirty_tracked_files_and_untracked_files_are_rejected(self):
        path = self.doom / "config.el"
        original = path.read_text()
        path.write_text("changed")
        with self.assertRaisesRegex(RuntimeError, "working-tree"):
            sources["doom_receipt"](self.root)
        path.write_text(original)
        (self.doom / "untracked.el").write_text("forgotten")
        with self.assertRaisesRegex(RuntimeError, "working-tree"):
            sources["doom_receipt"](self.root)

    def test_export_detects_changed_files_without_git_metadata(self):
        receipt = sources["doom_receipt"](self.root)
        exported = self.root / "exported"
        (exported / "nix").mkdir(parents=True)
        (exported / ".config/doom").mkdir(parents=True)
        for name in receipt["files"]:
            (exported / ".config/doom" / name).write_bytes(
                (self.doom / name).read_bytes()
            )
        (exported / sources["RECEIPT"]).write_text(json.dumps(receipt))
        self.assertEqual(sources["doom_receipt"](exported), receipt)
        (exported / ".config/doom/config.el").write_text("changed")
        with self.assertRaisesRegex(RuntimeError, "export receipt"):
            sources["doom_receipt"](exported)

    def test_tracked_snippets_are_included_and_ignored_state_is_excluded(self):
        snippet = self.doom / "snippets/text-mode/example"
        snippet.parent.mkdir(parents=True)
        snippet.write_text("snippet")
        self.git(self.doom, "add", "snippets")
        self.git(
            self.doom,
            "-c",
            "user.name=Test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "Snippet",
        )
        revision = self.git(self.doom, "rev-parse", "HEAD")
        self.git(
            self.root, "update-index", "--cacheinfo", f"160000,{revision},.config/doom"
        )
        (self.doom / ".git/info/exclude").write_text("runtime.el\n")
        (self.doom / "runtime.el").write_text("private runtime state")
        files = sources["doom_receipt"](self.root)["files"]
        self.assertIn("snippets/text-mode/example", files)
        self.assertNotIn("runtime.el", files)

    def test_archives_are_owner_only_and_never_overwrite(self):
        source = self.root / "source"
        source.mkdir()
        (source / "config.el").write_text("configuration")
        archive = self.root / "source.tar"
        sources["archive"](source, archive)
        self.assertEqual(stat.S_IMODE(archive.stat().st_mode), 0o600)
        with self.assertRaises(FileExistsError):
            sources["archive"](source, archive)

    def test_unverified_file_copy_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "verified bin/export"):
            sources["doom_receipt"](self.root / "unverified")

    def test_export_receipt_cannot_include_outside_files(self):
        exported = self.root / "exported"
        (exported / "nix").mkdir(parents=True)
        receipt = sources["doom_receipt"](self.root)
        receipt["files"] = {"../secret": "0" * 64, **receipt["files"]}
        (exported / sources["RECEIPT"]).write_text(json.dumps(receipt))
        with self.assertRaisesRegex(RuntimeError, "Invalid source path"):
            sources["doom_receipt"](exported)

    def test_docker_context_matches_declared_public_sources(self):
        self.assertEqual(
            (ROOT / ".dockerignore").read_text(), sources["dockerignore"](ROOT)
        )
        with tempfile.TemporaryDirectory() as temp:
            exported = Path(temp)
            sources["snapshot"](ROOT, exported, private=False)
            self.assertFalse((exported / ".config/doom").exists())
            self.assertFalse((exported / sources["RECEIPT"]).exists())
            self.assertFalse((exported / ".git").exists())


if __name__ == "__main__":
    unittest.main()
