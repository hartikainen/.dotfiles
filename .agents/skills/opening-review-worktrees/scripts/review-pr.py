#!/usr/bin/env python3
"""Open an interactive agent in a validated pull request worktree."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


AGENTS = ("codex", "agy", "cursor-agent")


class LauncherError(RuntimeError):
    pass


def run(*args: str, cwd: Path, capture: bool = True) -> str:
    result = subprocess.run(
        args,
        cwd=cwd,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() if result.stderr else ""
        raise LauncherError(detail or f"`{' '.join(args)}` failed")
    return result.stdout.strip() if result.stdout else ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Open an interactive agent in a pull request worktree."
    )
    parser.add_argument("--agent", choices=AGENTS, default="codex")
    parser.add_argument("pr", type=int)
    args = parser.parse_args()
    if args.pr < 1:
        parser.error("`pr` must be positive")
    return args


def expected_paths(checkout: Path, pr: int) -> tuple[Path, Path]:
    common_dir = Path(
        run(
            "git",
            "rev-parse",
            "--path-format=absolute",
            "--git-common-dir",
            cwd=checkout,
        )
    ).resolve()
    primary = common_dir.parent
    if primary.name == "main":
        parent = primary.parent / "github"
    else:
        parent = Path(f"{primary}.worktrees") / "github"
    return common_dir, parent / str(pr)


def invoke_bootstrap(checkout: Path, expected: Path, pr: int) -> dict[str, object]:
    script_dir = Path(__file__).resolve().parent
    schema = script_dir / "bootstrap-output.schema.json"
    expected.parent.mkdir(parents=True, exist_ok=True)
    prompt = (
        "Use $opening-review-worktrees to prepare pull request "
        f"#{pr} from `{checkout}`. The only acceptable worktree path is "
        f"`{expected}`. Create or inspect the worktree, do not review the "
        "change, and return only the schema-constrained result."
    )
    with tempfile.TemporaryDirectory(prefix="review-pr-") as temporary:
        output = Path(temporary) / "bootstrap.json"
        command = (
            "codex",
            "exec",
            "--ephemeral",
            "--approve-for-me",
            "-C",
            str(checkout),
            "--add-dir",
            str(expected.parent),
            "--output-schema",
            str(schema),
            "--output-last-message",
            str(output),
            prompt,
        )
        result = subprocess.run(command, check=False)
        if result.returncode != 0:
            raise LauncherError(f"`codex exec` exited with `{result.returncode}`")
        try:
            payload = json.loads(output.read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            raise LauncherError("`codex exec` did not return valid JSON") from error
    if not isinstance(payload, dict):
        raise LauncherError("`codex exec` returned a non-object result")
    return payload


def registered_worktrees(checkout: Path) -> set[Path]:
    listing = run("git", "worktree", "list", "--porcelain", cwd=checkout)
    return {
        Path(line.removeprefix("worktree ")).resolve()
        for line in listing.splitlines()
        if line.startswith("worktree ")
    }


def verify_result(
    payload: dict[str, object],
    checkout: Path,
    common_dir: Path,
    expected: Path,
    pr: int,
) -> Path:
    required = {"status", "worktree", "pr", "head", "message"}
    if set(payload) != required:
        raise LauncherError("the bootstrap result has an unexpected shape")
    if payload["pr"] != pr:
        raise LauncherError("the bootstrap result names a different pull request")
    if payload["status"] == "blocked":
        message = payload["message"]
        raise LauncherError(message if isinstance(message, str) else "worktree blocked")
    if payload["status"] != "ready":
        raise LauncherError("the bootstrap result has an invalid `status`")
    path_value = payload["worktree"]
    head_value = payload["head"]
    if not isinstance(path_value, str) or not Path(path_value).is_absolute():
        raise LauncherError("the bootstrap result has an invalid `worktree`")
    if not isinstance(head_value, str):
        raise LauncherError("the bootstrap result has an invalid `head`")
    worktree = Path(path_value).resolve()
    if worktree != expected.resolve():
        raise LauncherError("the bootstrap result names an unexpected worktree")
    if worktree not in registered_worktrees(checkout):
        raise LauncherError("the returned path is not a registered worktree")
    returned_common = Path(
        run(
            "git",
            "rev-parse",
            "--path-format=absolute",
            "--git-common-dir",
            cwd=worktree,
        )
    ).resolve()
    if returned_common != common_dir:
        raise LauncherError("the returned worktree belongs to another repository")
    if run("git", "status", "--porcelain", "--untracked-files=all", cwd=worktree):
        raise LauncherError("the returned worktree is not clean")
    branch = run("git", "symbolic-ref", "--quiet", "--short", "HEAD", cwd=worktree)
    if branch != f"github/{pr}":
        raise LauncherError("the returned worktree is on an unexpected branch")
    local_head = run("git", "rev-parse", "HEAD", cwd=worktree)
    remote_head = run(
        "gh",
        "pr",
        "view",
        str(pr),
        "--json",
        "headRefOid",
        "--jq",
        ".headRefOid",
        cwd=checkout,
    )
    if local_head != head_value or local_head != remote_head:
        raise LauncherError(
            "the returned worktree does not match the pull request head"
        )
    return worktree


def main() -> int:
    args = parse_args()
    checkout = Path.cwd().resolve()
    for executable in ("codex", args.agent):
        if shutil.which(executable) is None:
            print(
                f"review-pr: `{executable}` is not available on `PATH`", file=sys.stderr
            )
            return 1
    try:
        common_dir, expected = expected_paths(checkout, args.pr)
        payload = invoke_bootstrap(checkout, expected, args.pr)
        worktree = verify_result(payload, checkout, common_dir, expected, args.pr)
    except (LauncherError, OSError) as error:
        print(f"review-pr: {error}", file=sys.stderr)
        return 1
    prompt = f"Please review PR #{args.pr}."
    os.chdir(worktree)
    try:
        os.execvp(args.agent, (args.agent, prompt))
    except OSError as error:
        print(f"review-pr: {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
