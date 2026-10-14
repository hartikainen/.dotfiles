import json
from pathlib import Path
import re
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ReviewHookTests(unittest.TestCase):
    def invoke(self, script, payload):
        result = subprocess.run(
            [sys.executable, str(ROOT / ".codex/hooks" / script)],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stderr, "")
        return json.loads(result.stdout)

    def assert_decision(self, result, antigravity, denied):
        if antigravity:
            self.assertEqual(result["decision"], "deny" if denied else "ask")
            if denied:
                self.assertTrue(result["reason"])
        elif denied:
            output = result["hookSpecificOutput"]
            self.assertEqual(output["hookEventName"], "PreToolUse")
            self.assertEqual(output["permissionDecision"], "deny")
            self.assertTrue(output["permissionDecisionReason"])
        else:
            self.assertEqual(result, {})

    def test_shell_reads_pending_reviews_and_publication(self):
        cases = [
            ("gh pr view 3874", False),
            ("gh pr diff 3874", False),
            ("git status --short", False),
            ("gh api -X POST repos/o/r/pulls/3874/reviews", False),
            ("gh pr review 3874 --comment --body feedback", True),
            ("gh pr merge 3874", True),
            ("gh api -X POST repos/o/r/pulls/3874/reviews -f event=COMMENT", True),
        ]
        for antigravity in (False, True):
            for command, denied in cases:
                with self.subTest(antigravity=antigravity, command=command):
                    payload = (
                        {
                            "toolCall": {
                                "name": "run_command",
                                "args": {"CommandLine": command},
                            }
                        }
                        if antigravity
                        else {"tool_name": "Bash", "tool_input": {"command": command}}
                    )
                    result = self.invoke("block-review-submission.py", payload)
                    self.assert_decision(result, antigravity, denied)

    def test_mcp_reads_and_publication_in_each_transport(self):
        cases = [
            ("linear", "get_diff", False),
            ("github", "pull_request_read.get", False),
            ("github", "pull_request_read.get_diff", False),
            ("github", "create_pending_pull_request_review", False),
            ("linear", "submit_diff_review", True),
            ("linear", "merge_diff", True),
            ("linear", "resolve_review_thread", True),
            ("github", "submit_pending_pull_request_review", True),
            ("github", "submitPullRequestReview", True),
        ]
        for transport in ("codex", "eager", "native"):
            for server, tool, denied in cases:
                with self.subTest(transport=transport, server=server, tool=tool):
                    name = f"mcp__{server}__{tool}"
                    if transport == "codex":
                        payload = {"tool_name": name, "tool_input": {}}
                    elif transport == "eager":
                        payload = {"toolCall": {"name": name, "args": {}}}
                    else:
                        payload = {
                            "toolCall": {
                                "name": "call_mcp_tool",
                                "args": {
                                    "ServerName": server,
                                    "ToolName": tool,
                                    "Arguments": {"body": "submit_diff_review"},
                                },
                            }
                        }
                    result = self.invoke("block-review-mcp.py", payload)
                    self.assert_decision(result, transport != "codex", denied)

    def test_native_mcp_missing_tool_name_uses_fallback(self):
        result = self.invoke(
            "block-review-mcp.py",
            {
                "toolCall": {
                    "name": "call_mcp_tool",
                    "args": {"unknown": "submit_diff_review"},
                }
            },
        )
        self.assert_decision(result, True, True)

    def test_antigravity_hook_matchers_cover_both_mcp_transports(self):
        config = json.loads((ROOT / ".gemini/config/hooks.json").read_text())
        handlers = config["review-guard"]["PreToolUse"]
        for name, script in (
            ("run_command", "block-review-submission.py"),
            ("call_mcp_tool", "block-review-mcp.py"),
            ("mcp__linear__submit_diff_review", "block-review-mcp.py"),
        ):
            with self.subTest(name=name):
                matches = [h for h in handlers if re.fullmatch(h["matcher"], name)]
                self.assertEqual(len(matches), 1)
                self.assertIn(script, matches[0]["hooks"][0]["command"])


if __name__ == "__main__":
    unittest.main()
