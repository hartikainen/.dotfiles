#!/usr/bin/env python3
"""Denies MCP tool calls that would submit a review or merge a change.

Cursor runs this as a `beforeMCPExecution` hook. Linear's MCP server reaches
review submission and merging without any shell command, so the
`beforeShellExecution` guard alone would leave that route open.

The literal value of `tool_name` for an MCP tool is not documented, and it may
or may not be namespaced by the server. Matching therefore happens on a
normalised name with case and separators stripped, so that `submit_diff_review`,
`linear__submit_diff_review`, `submit-diff-review`, and `submitDiffReview` all
resolve to the same key.
"""

import json
import re
import sys

# Submitting a review or merging is the user's decision, never the agent's.
DENIED_TOOLS = {
    "submitdiffreview": "submitting a diff review takes it out of pending state.",
    "mergediff": "merging a change is a manual decision.",
}

# Resolving a thread is a visible change to someone else's review, so it is
# worth a prompt without being outright refused.
ASK_TOOLS = {
    "resolvediffthread": "resolving a review thread is visible to others.",
}


def normalise(name: str) -> str:
    """Lowercases `name` and strips everything that is not alphanumeric."""
    return re.sub(r"[^a-z0-9]", "", name.lower())


GUIDANCE = (
    "Leave the review pending and report findings in chat, so that the user "
    "submits it themselves."
)


def evaluate(tool_name: str) -> tuple[str, str]:
    """Returns a `(permission, reason)` pair, or `("", "")` to defer."""
    normalised = normalise(tool_name)

    for needle, reason in DENIED_TOOLS.items():
        if needle in normalised:
            return "deny", reason

    for needle, reason in ASK_TOOLS.items():
        if needle in normalised:
            return "ask", reason

    return "", ""


def fallback(raw: str) -> tuple[str, str]:
    """Scans the raw payload when the tool name could not be read from it.

    Deferring on an unreadable payload would silently disable this guard, so the
    raw text is searched for the tool names that must never run unattended.
    """
    normalised = normalise(raw)
    if any(needle in normalised for needle in DENIED_TOOLS):
        return (
            "deny",
            "this hook could not read the tool name from its input and the "
            "payload names a submitting tool.",
        )
    return "", ""


def main() -> int:
    raw = sys.stdin.read()

    tool_name = ""
    try:
        payload = json.loads(raw)
        if isinstance(payload, dict):
            tool_name = payload.get("tool_name") or ""
    except ValueError:
        pass

    try:
        permission, reason = evaluate(tool_name) if tool_name else fallback(raw)
    except Exception:
        permission, reason = fallback(raw)

    if not permission:
        print("{}")
        return 0

    verb = "Blocked" if permission == "deny" else "Confirm"
    print(
        json.dumps(
            {
                "permission": permission,
                "user_message": f"{verb} `{tool_name}`: {reason}",
                "agent_message": f"`{tool_name}` was {permission}ed by the review guard, because {reason} {GUIDANCE}",
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
