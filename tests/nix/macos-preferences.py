import json
import os
from pathlib import Path
import platform
import plistlib
import subprocess
import sys


DOMAIN = "com.apple.symbolichotkeys"
UNMANAGED = {
    "enabled": True,
    "value": {"parameters": [65535, 18, 1048576], "type": "standard"},
}


def read(domain, current_host=False):
    return plistlib.loads(
        subprocess.check_output(
            [
                "/usr/bin/defaults",
                *(["-currentHost"] if current_host else []),
                "export",
                domain,
                "-",
            ]
        )
    )


def main():
    if os.environ.get("DOTFILES_TEST_GUEST") != "1" or platform.system() != "Darwin":
        raise RuntimeError("Run only in a disposable macOS VM")
    if sys.argv[1] == "seed":
        subprocess.run(
            [
                "/usr/bin/defaults",
                "write",
                DOMAIN,
                "DotfilesUnmanaged",
                "-string",
                "retained",
            ],
            check=True,
        )
        existing = read(DOMAIN)
        existing.setdefault("AppleSymbolicHotKeys", {})["98"] = UNMANAGED
        subprocess.run(
            ["/usr/bin/defaults", "import", DOMAIN, "-"],
            input=plistlib.dumps(existing),
            check=True,
        )
        return
    if sys.argv[1] != "verify":
        raise ValueError("Choose seed or verify")
    expected = json.loads(
        (Path(__file__).resolve().parents[2] / "nix/macos-defaults.json")
        .read_text()
        .replace("@HOME@", str(Path.home()))
    )
    expected[DOMAIN]["AppleSymbolicHotKeys"]["60"]["enabled"] = sys.argv[2] == "b"
    for domain, keys in expected.items():
        actual = read(domain)
        for key, value in keys.items():
            if domain == DOMAIN:
                for shortcut, settings in value.items():
                    assert actual[key][shortcut] == settings, (
                        domain,
                        shortcut,
                        actual[key],
                    )
            else:
                assert actual[key] == value, (domain, key, actual[key], value)
    actual = read(DOMAIN)
    assert actual["AppleSymbolicHotKeys"]["98"] == UNMANAGED
    assert actual["DotfilesUnmanaged"] == "retained"
    controlcenter = read("com.apple.controlcenter", True)
    assert controlcenter["BatteryShowPercentage"]
    assert controlcenter["Bluetooth"] == 18
    assert read("com.apple.ImageCapture", True)["disableHotPlug"]


if __name__ == "__main__":
    main()
