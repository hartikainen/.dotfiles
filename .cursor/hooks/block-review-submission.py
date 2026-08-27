#!/usr/bin/env python3
"""Denies shell commands that would submit or publish a pull request review.

Cursor runs this as a `beforeShellExecution` hook. Reviews have to stay in
GitHub's `PENDING` state so that a human submits them by hand, so anything that
submits a review, publishes a comment, merges, or closes a pull request is
denied. Creating a pending review is deliberately left alone.

GitHub distinguishes the two by a single field: `POST /pulls/{n}/reviews`
leaves the review `PENDING` when `event` is absent and submits it the moment
`event` is set to `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`. That is why a
glob over the command name cannot express this policy and this script inspects
the whole invocation instead.

A top-level `body` on that same call is denied on related grounds. It does not
publish anything by itself, though it renders on the pull request page as soon
as the review exists and it fills the summary box the user types into when they
decide the outcome, so writing it pre-empts their verdict. Only
`comments[][body]=...` may carry prose. This is enforced for the two payload
forms the workflow documents, i.e. field flags and a file passed to `--input`,
which keeps the check exact rather than guessing at the nesting of a raw JSON
string.

The paths that publish are matched only once the command looks like a write,
i.e. it names a writing method or carries a flag that attaches a request body.
Reading a discussion is a normal part of preparing a review, and both clients
default to `GET`, so a command with neither of those cannot publish anything.
Anything this fails to classify counts as a write.

Thread maintenance goes through the idempotent helper in
`maintaining-pr-stacks`, which resolves without publishing a comment. Direct
reply and resolution mutations stay blocked here.

Commands that are not a review submission return an empty decision so the
normal permission system still applies. This hook only ever removes
permissions, it never grants them.
"""

import json
import re
import sys

# `gh pr review` has no pending mode, so every form of it submits.
SUBMITTING_COMMANDS = (
    (
        re.compile(r"\bgh\s+pr\s+review\b"),
        "`gh pr review` always submits the review, since `gh` has no pending mode.",
    ),
    (
        re.compile(r"\bgh\s+pr\s+comment\b"),
        "`gh pr comment` publishes a timeline comment immediately.",
    ),
    (
        re.compile(r"\bgh\s+pr\s+merge\b"),
        "`gh pr merge` merges the pull request.",
    ),
    (
        re.compile(r"\bgh\s+pr\s+close\b"),
        "`gh pr close` closes the pull request.",
    ),
    (
        re.compile(r"\baddPullRequestReviewThreadReply\b"),
        "direct review thread replies bypass the validated maintenance helper.",
    ),
    (
        re.compile(r"\bresolveReviewThread\b"),
        "direct review thread resolution bypasses the validated maintenance helper.",
    ),
)

# Methods that write. `gh` and `curl` between them spell the flag as `--method
# POST`, `--method=POST`, `--request POST`, `-X POST`, and `-XPOST`.
WRITE_METHOD = re.compile(
    r"""(?<![\w-])(?:--method|--request|-X)[=\s]*["']?(?:POST|PUT|PATCH|DELETE)\b""",
    re.IGNORECASE,
)

# Flags that attach a request body, which makes the call a write even when no
# method is named, since `gh api` switches from `GET` to `POST` on their
# presence.
BODY_CARRYING_FLAG = re.compile(
    r"""(?<![\w-])(?:-[fF]|--field|--raw-field|--input|-d|--data(?:-binary|-raw|-urlencode)?)(?=[=\s])""",
)

# REST paths that publish on write, whatever the payload looks like. Gated on
# `writes()` so that reading the same path stays available.
PUBLISHING_PATHS = (
    (
        re.compile(r"/reviews/[^/\s'\"]+/events"),
        "`POST /pulls/{n}/reviews/{id}/events` submits a pending review.",
    ),
    (
        re.compile(r"/reviews/[^/\s'\"]+/dismissals"),
        "dismissing a review is a published state change.",
    ),
    (
        re.compile(r"/pulls/[^/\s'\"]+/comments"),
        "`POST /pulls/{n}/comments` publishes an inline comment immediately, "
        "with no pending mode.",
    ),
    (
        re.compile(r"/comments/[^/\s'\"]+/replies"),
        "`POST /pulls/comments/{id}/replies` publishes a reply immediately.",
    ),
    (
        re.compile(r"/issues/[^/\s'\"]+/comments"),
        "`POST /issues/{n}/comments` publishes a timeline comment.",
    ),
)

# An `event` set to one of the three submitting actions, in any of the forms
# `event=APPROVE`, `"event": "APPROVE"`, and GraphQL `event: APPROVE`. Matching
# the value rather than the bare key keeps prose from tripping the guard, since
# a review comment may legitimately contain a phrase like "the event: ...".
EVENT_ACTION = re.compile(
    r"""event["']?\s*[=:]\s*["']?\s*(?:APPROVE|REQUEST_CHANGES|COMMENT)\b""",
    re.IGNORECASE,
)

# A quoted JSON `"event":` key, whose value may be a variable rather than a
# literal. Requiring the quotes keeps this off ordinary prose too.
EVENT_JSON_KEY = re.compile(r"""["']event["']\s*:""")

# A top-level `body` field, i.e. `-f body=...`, `-F body=...`, or the long
# spellings of either. Anchoring the key to the flag is what distinguishes it
# from `comments[][body]=...`, whose key does not start with `body`.
BODY_FIELD = re.compile(r"""(?<![\w-])(?:-[fF]|--(?:raw-)?field)[=\s]*["']?body=""")


# `.../pulls/{n}/reviews` with nothing after it, i.e. the create-review call.
REVIEWS_COLLECTION = re.compile(r"/pulls/[^/\s'\"]+/reviews(?![/\w])")

# Payload forms this script cannot read, i.e. piped stdin and `@file` bodies.
OPAQUE_PAYLOAD = (
    re.compile(r"--input[=\s]+-(?:\s|$)"),
    re.compile(r"--data(?:-binary|-raw)?[=\s]+@"),
    re.compile(r"\s-d[=\s]+@"),
)
FILE_INPUT = re.compile(r"--input[=\s]+([^\s'\"@-][^\s'\"]*)")

# Anything that can reach the REST API, not just `gh`. A `curl` to
# `api.github.com` submits a review just as effectively.
GITHUB_CLIENT = re.compile(r"\bgh\b|api\.github\.com")

GUIDANCE = (
    "Reviews must stay in GitHub's PENDING state for manual approval, and the "
    "summary is the user's to write. Create the review with `gh api --method "
    "POST repos/{owner}/{repo}/pulls/{n}/reviews`, omitting both `event` and "
    "the top-level `body`, and pass inline comments as `-F "
    "'comments[][path]=...'` field flags rather than `--input -`, so the "
    "payload stays inspectable. Report findings to the user in chat instead if "
    "you are unsure."
)

# Literals worth denying even if the main logic below fails to run.
FALLBACK_LITERALS = (
    "pr review",
    "pr comment",
    "pr merge",
    "pr close",
    "/events",
    "/dismissals",
    "submitPullRequestReview",
    "addPullRequestReviewThreadReply",
    "resolveReviewThread",
)


def sets_event(command: str) -> bool:
    """Whether `command` appears to set the review `event` field."""
    return bool(EVENT_ACTION.search(command) or EVENT_JSON_KEY.search(command))


def sets_body(command: str) -> bool:
    """Whether `command` appears to set the review's top-level `body` field."""
    return bool(BODY_FIELD.search(command))


def writes(command: str) -> bool:
    """Whether `command` sends anything other than a read to the API.

    Errs towards `True`, since a command this cannot classify has to be treated
    as a write. Both clients default to `GET`, so the only way to answer `False`
    is to find neither a writing method nor a flag carrying a request body.
    """
    return bool(WRITE_METHOD.search(command) or BODY_CARRYING_FLAG.search(command))


def evaluate(command: str) -> str:
    """Returns a denial reason for `command`, or an empty string to defer."""
    if not GITHUB_CLIENT.search(command):
        return ""

    for pattern, reason in SUBMITTING_COMMANDS:
        if pattern.search(command):
            return reason

    if writes(command):
        for pattern, reason in PUBLISHING_PATHS:
            if pattern.search(command):
                return reason

    if "submitPullRequestReview" in command:
        return "`submitPullRequestReview` submits a pending review."

    if "addPullRequestReview" in command and sets_event(command):
        return (
            "`addPullRequestReview` with an `event` argument creates and "
            "submits the review in one step."
        )

    if not REVIEWS_COLLECTION.search(command):
        return ""

    if sets_event(command):
        return (
            "this posts to the reviews endpoint with an `event` field, which "
            "submits the review instead of leaving it pending."
        )

    if sets_body(command):
        return (
            "this sets the review's top-level `body`, which is the summary the "
            "user writes when they submit. Only `comments[][body]=...` may "
            "carry prose."
        )

    for pattern in OPAQUE_PAYLOAD:
        if pattern.search(command):
            return (
                "the request body is not visible in the command, so this hook "
                "cannot confirm that `event` is absent."
            )

    file_input = FILE_INPUT.search(command)
    if file_input:
        try:
            with open(file_input.group(1), encoding="utf-8") as payload:
                document = json.load(payload)
        except (OSError, ValueError):
            return (
                "the payload file passed to `--input` could not be read, so "
                "this hook cannot confirm that `event` is absent."
            )
        if isinstance(document, dict) and document.get("event"):
            return (
                "the payload file passed to `--input` sets `event`, which "
                "submits the review instead of leaving it pending."
            )
        if isinstance(document, dict) and document.get("body"):
            return (
                "the payload file passed to `--input` sets a top-level `body`, "
                "which is the summary the user writes when they submit."
            )

    return ""


def fallback_reason(raw: str) -> str:
    """Scans the raw payload when the command could not be read from it.

    Reached when the input is malformed or the schema moves the command
    elsewhere. Deferring in that case would silently disable this guard, so the
    raw text is searched for the literals that matter most.
    """
    lowered = raw.lower()
    if any(literal.lower() in lowered for literal in FALLBACK_LITERALS):
        return (
            "this hook could not read the command from its input and the "
            "payload looks like a review submission."
        )
    return ""


def main() -> int:
    raw = sys.stdin.read()

    command = ""
    try:
        payload = json.loads(raw)
        if isinstance(payload, dict):
            command = payload.get("command") or ""
    except ValueError:
        pass

    try:
        reason = evaluate(command) if command else fallback_reason(raw)
    except Exception:
        reason = fallback_reason(raw)

    if not reason:
        print("{}")
        return 0

    print(
        json.dumps(
            {
                "permission": "deny",
                "user_message": f"Blocked a review submission: {reason}",
                "agent_message": f"Denied by the review guard, because {reason} {GUIDANCE}",
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
