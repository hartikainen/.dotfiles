import json
import os
import plistlib
import subprocess
import sys


DOMAIN = "com.apple.symbolichotkeys"


def merge(existing, managed):
    shortcuts = existing.get("AppleSymbolicHotKeys", {})
    if not isinstance(shortcuts, dict) or not isinstance(managed, dict):
        raise ValueError("Expected a dictionary of symbolic shortcuts")
    return {**existing, "AppleSymbolicHotKeys": {**shortcuts, **managed}}


def apply(managed):
    result = subprocess.run(
        ["/usr/bin/defaults", "export", DOMAIN, "-"],
        capture_output=True,
        env={**os.environ, "LC_ALL": "C"},
        check=False,
    )
    if result.returncode:
        message = result.stderr.decode(errors="replace")
        if DOMAIN not in message or "does not exist" not in message:
            raise RuntimeError(f"Cannot read symbolic shortcuts: {message}")
        existing = {}
    else:
        existing = plistlib.loads(result.stdout)
    merged = merge(existing, managed)
    if merged != existing:
        subprocess.run(
            ["/usr/bin/defaults", "import", DOMAIN, "-"],
            input=plistlib.dumps(merged),
            check=True,
        )


if __name__ == "__main__":
    with open(sys.argv[1]) as source:
        apply(json.load(source))
