import json
from pathlib import Path
import re
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ReviewHookTests(unittest.TestCase):
    def invoke(self, script, payload, agent="codex"):
        result = subprocess.run(
            [sys.executable, str(ROOT / f".{agent}/hooks" / script)],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stderr, "")
        return json.loads(result.stdout)

    def shell_payload(self, command, agent, event="PreToolUse"):
        if agent == "cursor":
            return {"command": command}
        if agent == "antigravity":
            return {
                "toolCall": {"name": "run_command", "args": {"CommandLine": command}}
            }
        return {
            "hook_event_name": event,
            "tool_name": "Bash",
            "tool_input": {"command": command},
        }

    def test_exact_codex_review_trigger_is_allowed(self):
        for agent in ("codex", "antigravity", "cursor"):
            for quote in ("'", '"'):
                command = (
                    f"gh api --method POST --raw-field {quote}body=@codex review.{quote} "
                    "repos/Eka-Robotics/eka-robotics/issues/3874/comments"
                )
                with self.subTest(agent=agent, quote=quote):
                    result = self.invoke(
                        "block-review-submission.py",
                        self.shell_payload(command, agent),
                        "cursor" if agent == "cursor" else "codex",
                    )
                    self.assertEqual(
                        result,
                        {"permission": "allow"}
                        if agent == "cursor"
                        else {"decision": "allow"}
                        if agent == "antigravity"
                        else {},
                    )

    def test_trigger_exception_does_not_allow_other_publication(self):
        trigger = (
            "gh api --method POST --raw-field 'body=@codex review.' "
            "repos/o/r/issues/3874/comments"
        )
        commands = [
            trigger.replace("review.", "review"),
            trigger.replace("review.", "review. Extra prose"),
            trigger.replace("review.", "review.\nExtra prose"),
            trigger.replace("@codex", "@someone"),
            trigger.replace("POST", "PATCH"),
            trigger.replace("/issues/", "/pulls/"),
            trigger.replace("'body=@codex review.'", '"body=$(cat /tmp/body)"'),
            trigger.replace("'body=@codex review.'", '"body=`cat /tmp/body`"'),
            trigger.replace(
                "--raw-field 'body=@codex review.'", "--input /tmp/body.json"
            ),
            trigger.replace("/o/r/", "/$OWNER/$REPO/"),
            trigger + " --raw-field body=extra",
            trigger + " --input /tmp/body.json",
            trigger + " > /tmp/output",
            trigger + " # extra",
            "echo " + trigger,
            "GH_HOST=example.com " + trigger,
            trigger + "; gh pr merge 3874",
            trigger + " && gh pr comment 3874 --body extra",
            trigger + "\ngh pr close 3874",
            trigger + " | sh",
            "gh pr comment 3874 --body '@codex review.'",
            "gh pr review 3874 --comment --body '@codex review.'",
        ]
        for agent in ("codex", "antigravity", "cursor"):
            for command in commands:
                with self.subTest(agent=agent, command=command):
                    result = self.invoke(
                        "block-review-submission.py",
                        self.shell_payload(command, agent),
                        "cursor" if agent == "cursor" else "codex",
                    )
                    if agent == "cursor":
                        self.assertEqual(result["permission"], "deny")
                    else:
                        self.assert_decision(result, agent == "antigravity", True)

    def test_codex_permission_request_approves_only_exact_trigger(self):
        trigger = (
            "gh api --method POST --raw-field 'body=@codex review.' "
            "repos/o/r/issues/3874/comments"
        )
        for command in (
            trigger,
            trigger + " -f body=extra",
            "git status --short",
            "git push",
        ):
            with self.subTest(command=command):
                result = self.invoke(
                    "block-review-submission.py",
                    self.shell_payload(command, "codex", "PermissionRequest"),
                )
                self.assertEqual(
                    result,
                    {
                        "hookSpecificOutput": {
                            "hookEventName": "PermissionRequest",
                            "decision": {"behavior": "allow"},
                        }
                    }
                    if command == trigger
                    else {},
                )

    def test_codex_permission_hook_is_registered_for_shell_only(self):
        config = json.loads((ROOT / ".codex/hooks.json").read_text())
        handlers = config["hooks"]["PermissionRequest"]
        self.assertEqual(len(handlers), 1)
        self.assertIsNotNone(re.fullmatch(handlers[0]["matcher"], "Bash"))
        self.assertIsNone(re.fullmatch(handlers[0]["matcher"], "apply_patch"))
        self.assertIn("block-review-submission.py", handlers[0]["hooks"][0]["command"])

    def test_malformed_inputs_do_not_receive_trigger_approval(self):
        for payload, agent in (
            ({"command": ["unexpected"]}, "cursor"),
            (
                {"hook_event_name": "PermissionRequest", "tool_input": "unexpected"},
                "codex",
            ),
            (
                {"hook_event_name": "PermissionRequest", "tool_input": {"command": []}},
                "codex",
            ),
        ):
            with self.subTest(payload=payload, agent=agent):
                self.assertEqual(
                    self.invoke("block-review-submission.py", payload, agent), {}
                )

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
