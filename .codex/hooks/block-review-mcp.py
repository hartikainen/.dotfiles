#!/usr/bin/env python3
"""Deny MCP tool calls that publish or submit a review.

Codex and Antigravity run this as a `PreToolUse` hook for MCP tools. Linear's
MCP server can reach review submission and merging without a shell command, so
the shell guard alone would leave that route open.

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
    "submitpendingpullrequestreview": "submitting a pull request review takes it out of pending state.",
    "submitpullrequestreview": "submitting a pull request review takes it out of pending state.",
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


def deny(
    tool_name: str, reason: str, *, antigravity: bool = False
) -> dict[str, object]:
    """Return the `PreToolUse` denial shape for Codex or Antigravity."""
    message = f"Blocked `{tool_name}` because {reason} {GUIDANCE}"
    if antigravity:
        return {"decision": "deny", "reason": message}
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": message,
        }
    }


def main() -> int:
    raw = sys.stdin.read()

    tool_name = ""
    antigravity = False
    try:
        payload = json.loads(raw)
        if isinstance(payload, dict):
            candidate = payload.get("tool_name")
            if isinstance(candidate, str):
                tool_name = candidate
            tool_call = payload.get("toolCall")
            if isinstance(tool_call, dict):
                antigravity = True
                candidate = tool_call.get("name")
                if isinstance(candidate, str):
                    tool_name = candidate
                if tool_name == "call_mcp_tool":
                    tool_name = ""
                    args = tool_call.get("args")
                    if isinstance(args, dict):
                        candidate = args.get("ToolName")
                        if isinstance(candidate, str) and candidate:
                            server = args.get("ServerName")
                            tool_name = (
                                f"{server}__{candidate}"
                                if isinstance(server, str) and server
                                else candidate
                            )
    except ValueError:
        pass

    try:
        reason = evaluate(tool_name) if tool_name else fallback_reason(raw)
    except Exception:
        reason = fallback_reason(raw)

    print(
        json.dumps(
            deny(tool_name or "MCP tool", reason, antigravity=antigravity)
            if reason
            else ({"decision": "ask"} if antigravity else {})
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
