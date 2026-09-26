#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys
import tempfile
import tomllib
import tomli_w


def merge(existing, seed):
    result = dict(existing)
    for key, value in seed.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = value
    return result


def apply(target, seed):
    target, seed = Path(target), Path(seed)
    if target.is_symlink() or any(p.is_symlink() for p in target.parents):
        raise RuntimeError(f"Mutable settings path contains a symlink: {target}")
    is_toml = seed.suffix == ".toml"
    loads = tomllib.loads if is_toml else json.loads
    dumps = (
        tomli_w.dumps if is_toml else lambda value: json.dumps(value, indent=2) + "\n"
    )
    existing = loads(target.read_text()) if target.exists() else {}
    combined = merge(existing, loads(seed.read_text()))
    encoded = dumps(combined)
    if loads(encoded) != combined:
        raise RuntimeError(f"Settings cannot round-trip: {target}")
    if target.exists() and target.read_text() == encoded:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=target.parent, prefix=".dotfiles-settings-")
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(encoded)
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    apply(*sys.argv[1:])
