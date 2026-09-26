import importlib.machinery
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch


loader = importlib.machinery.SourceFileLoader(
    "launcher", str(Path(__file__).resolve().parents[2] / "bin/test")
)
spec = importlib.util.spec_from_loader(loader.name, loader)
launcher = importlib.util.module_from_spec(spec)
loader.exec_module(launcher)


class LauncherTests(unittest.TestCase):
    def test_low_disk_never_starts_docker(self):
        with (
            patch.object(
                launcher.shutil, "disk_usage", return_value=SimpleNamespace(free=0)
            ),
            patch.object(launcher.subprocess, "Popen") as popen,
            self.assertRaises(RuntimeError),
        ):
            launcher.run(["docker", "run"], Path("/tmp"))
        popen.assert_not_called()

    def test_disk_reserve_stops_running_client(self):
        with (
            patch.object(
                launcher, "require_space", side_effect=[None, RuntimeError("full")]
            ),
            patch.object(launcher.subprocess, "Popen") as popen,
            self.assertRaises(RuntimeError),
        ):
            process = popen.return_value
            process.wait.side_effect = [
                launcher.subprocess.TimeoutExpired("docker", 2),
                0,
            ]
            process.poll.return_value = None
            launcher.run(["docker", "run"], Path("/tmp"))
        process.terminate.assert_called_once()
