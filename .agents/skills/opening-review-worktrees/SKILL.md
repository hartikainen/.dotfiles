---
name: opening-review-worktrees
description: >-
  Prepare a dedicated GitHub pull request worktree for an interactive agent.
  Use when `review-pr` asks for a worktree or when the user asks to open an
  agent session in a pull request checkout. Do not use for the review itself.
---

# Open a review worktree

Prepare the checkout and stop. The interactive agent performs the review in a
separate session.

The request provides a pull request number, the repository checkout, and the
only acceptable worktree path. Fetch `refs/pull/<number>/head` from `origin`,
then inspect that exact path.

- If the path does not exist, create `github/<number>` there with `git worktree
  add -b github/<number> <path> FETCH_HEAD`.
- If the local branch exists without a worktree, add it only when it already
  points at the fetched head. Otherwise return `blocked`.
- If the path exists, require it to be registered for this repository on
  `github/<number>`, clean under `git status --porcelain
  --untracked-files=all`, and at the fetched head. Return `blocked` on any
  mismatch.
- Never remove, reset, clean, switch, or update an existing worktree. The
  caller asks the user before changing one.
- Do not inspect the pull request diff, run tests, or begin the review.

Return only the object required by the supplied output schema:

```json
{
  "status": "ready",
  "worktree": "/absolute/path/to/github/123",
  "pr": 123,
  "head": "0123456789abcdef0123456789abcdef01234567",
  "message": ""
}
```

Use `status: blocked` and a concise `message` when a precondition fails. Keep
`worktree`, `pr`, and `head` populated with the values you established, using
an empty `head` only when the PR head could not be fetched.
