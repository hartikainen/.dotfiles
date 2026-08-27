#!/usr/bin/env python3
"""Deny MCP tool calls that publish or submit a review.

Codex runs this as a `PreToolUse` hook for MCP tools. Linear's MCP server can
reach review submission and merging without a shell command, so the shell
guard alone would leave that route open.

Matching happens on a normalized name with case and separators stripped, so
`submit_diff_review`, `linear__submit_diff_review`, `submit-diff-review`, and
`submitDiffReview` all resolve to the same key.

Codex does not support returning `ask` from `PreToolUse`. Thread maintenance
therefore goes through the resolution-only helper in `maintaining-pr-stacks`,
whose input is narrow enough to validate before it reaches GitHub.
"""

import json
import re
import sys

DENIED_TOOLS = {
    "submitdiffreview": "submitting a diff review takes it out of pending state.",
    "mergediff": "merging a change is a manual decision.",
    "addreviewthreadreply": "direct review thread replies bypass the validated maintenance helper.",
    "replytoreviewthread": "direct review thread replies bypass the validated maintenance helper.",
    "resolvereviewthread": "direct review thread resolution bypasses the validated maintenance helper.",
}

GUIDANCE = (
    "Leave the review pending and report findings in chat, so that the user "
    "submits it themselves."
)


def normalize(name: str) -> str:
    """Lowercase `name` and strip everything that is not alphanumeric."""
    return re.sub(r"[^a-z0-9]", "", name.lower())


def evaluate(tool_name: str) -> str:
    """Return a denial reason, or an empty string to defer."""
    normalized = normalize(tool_name)
    for needle, reason in DENIED_TOOLS.items():
        if needle in normalized:
            return reason
    return ""


def fallback_reason(raw: str) -> str:
    """Scan raw hook input when the tool name could not be read from it."""
    normalized = normalize(raw)
    if any(needle in normalized for needle in DENIED_TOOLS):
        return (
            "this hook could not read the tool name from its input and the "
            "payload names a submitting tool."
        )
    return ""


def deny(tool_name: str, reason: str) -> dict[str, object]:
    """Return Codex's `PreToolUse` denial shape."""
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"Blocked `{tool_name}` because {reason} {GUIDANCE}"
            ),
        }
    }


def main() -> int:
    raw = sys.stdin.read()

    tool_name = ""
    try:
        payload = json.loads(raw)
        if isinstance(payload, dict):
            candidate = payload.get("tool_name")
            if isinstance(candidate, str):
                tool_name = candidate
    except ValueError:
        pass

    try:
        reason = evaluate(tool_name) if tool_name else fallback_reason(raw)
    except Exception:
        reason = fallback_reason(raw)

    print(json.dumps(deny(tool_name or "MCP tool", reason) if reason else {}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
