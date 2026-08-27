#!/usr/bin/env python3
"""Resolve one GitHub review thread without publishing a comment."""

import argparse
import json
import subprocess
import sys


QUERY = """
query($id: ID!) {
  node(id: $id) {
    ... on PullRequestReviewThread { isResolved }
  }
}
"""

RESOLVE = """
mutation($thread: ID!) {
  resolveReviewThread(input: {threadId: $thread}) {
    thread { isResolved }
  }
}
"""


class ThreadError(RuntimeError):
    pass


def command(*args: str) -> str:
    result = subprocess.run(args, check=False, text=True, capture_output=True)
    if result.returncode != 0:
        raise ThreadError(result.stderr.strip() or f"`{' '.join(args)}` failed")
    return result.stdout


def graphql(query: str, **variables: str) -> dict[str, object]:
    args = ["gh", "api", "graphql", "-f", f"query={query}"]
    for key, value in variables.items():
        args.extend(("-f", f"{key}={value}"))
    try:
        payload = json.loads(command(*args))
    except ValueError as error:
        raise ThreadError("GitHub returned invalid JSON") from error
    if not isinstance(payload, dict) or not isinstance(payload.get("data"), dict):
        raise ThreadError("GitHub returned an unexpected GraphQL response")
    return payload["data"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve one GitHub review thread without commenting."
    )
    parser.add_argument("--thread", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        data = graphql(QUERY, id=args.thread)
        thread = data.get("node")
        if not isinstance(thread, dict):
            raise ThreadError("the review thread does not exist")
        if thread.get("isResolved") is True:
            print("The review thread is already resolved.")
            return 0
        resolved = graphql(RESOLVE, thread=args.thread)
        mutation = resolved.get("resolveReviewThread")
        result = mutation.get("thread") if isinstance(mutation, dict) else None
        if not isinstance(result, dict) or result.get("isResolved") is not True:
            raise ThreadError("GitHub did not resolve the review thread")
    except ThreadError as error:
        print(f"resolve-review-thread: {error}", file=sys.stderr)
        return 1
    print("Resolved the review thread without publishing a comment.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
