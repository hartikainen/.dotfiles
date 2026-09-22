---
name: opening-review-worktrees
description: >-
  Prepare or validate a GitHub pull request checkout for `review-pr`, a review
  workflow, or a user opening a PR worktree. Handles checkout setup only.
---

# Open a review worktree

Prepare the checkout and return it to the caller, which handles the review.

Resolve the repository checkout and pull request number from the request. Ask when either is ambiguous. Honor a caller-supplied worktree path exactly. Otherwise derive the main checkout from `git rev-parse --path-format=absolute --git-common-dir`: a checkout named `main` uses its sibling `github/<number>` directory, and a flat checkout uses `<checkout>.worktrees/github/<number>`. This is the layout used by `review-pr`.

Fetch `refs/pull/<number>/head` from `origin`, then inspect the chosen path.

- If the path does not exist, create `github/<number>` there with `git worktree add -b github/<number> <path> FETCH_HEAD`.
- If the local branch exists without a worktree, add it only when it already points at the fetched head. Otherwise return `blocked`.
- If the path exists, require it to be registered for this repository on `github/<number>`, clean under `git status --porcelain --untracked-files=all`, and at the fetched head. Return `blocked` on any mismatch.
- Never remove, reset, clean, switch, or update an existing worktree. The caller asks the user before changing one.
- Do not inspect the pull request diff, run tests, or begin the review.

When the caller supplies an output schema, return only its required object:

```json
{
  "status": "ready",
  "worktree": "/absolute/path/to/github/123",
  "pr": 123,
  "head": "0123456789abcdef0123456789abcdef01234567",
  "message": ""
}
```

Use `status: blocked` and a concise `message` when a precondition fails. Keep `worktree`, `pr`, and `head` populated with the values you established, using an empty `head` only when the PR head could not be fetched.

For a direct user request without a schema, report the checkout path and head, or the mismatch that prevents using it.
