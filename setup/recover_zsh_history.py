#!/usr/bin/env python3
"""Merge zsh extended-history files, dedupe by (timestamp, command), sort.

Reads every path given on the command line (typically the live history
file plus any `~/.local/state/zsh/history.rescue-*` dumps) and writes a
single merged file to stdout. Designed to recover after a zsh shell
exited without `APPEND_HISTORY` and truncated `$HISTFILE` to `$SAVEHIST`
entries.
"""

import re
import sys
from pathlib import Path

# zsh extended-history entry header: `: <unix-ts>:<duration-sec>;<command>`.
HEADER_RE = re.compile(rb"^: (\d+):(\d+);")


def parse_entries(blob: bytes):
    """Yield (timestamp, raw_entry_bytes) for each extended-history entry.

    A single entry can span multiple lines: any line ending with an
    unescaped backslash is continued on the next line.
    """
    lines = blob.split(b"\n")
    current: list[bytes] | None = None
    current_ts: int | None = None
    for line in lines:
        m = HEADER_RE.match(line)
        if m is not None:
            if current is not None and current_ts is not None:
                yield current_ts, b"\n".join(current)
            current = [line]
            current_ts = int(m.group(1))
        elif current is not None:
            current.append(line)
    if current is not None and current_ts is not None:
        yield current_ts, b"\n".join(current)


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: recover_zsh_history.py <histfile>...\n")
        return 2

    seen: dict[tuple[int, bytes], bytes] = {}
    for path in sys.argv[1:]:
        p = Path(path)
        if not p.exists():
            sys.stderr.write(f"skip (missing): {p}\n")
            continue
        for ts, entry in parse_entries(p.read_bytes()):
            seen.setdefault((ts, entry), entry)

    out = sys.stdout.buffer
    for (_, _), entry in sorted(seen.items(), key=lambda kv: kv[0][0]):
        out.write(entry)
        out.write(b"\n")

    sys.stderr.write(f"merged {len(seen)} unique entries from {len(sys.argv) - 1} file(s)\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
