---
name: reviewing-pull-requests
description: >-
  Review GitHub pull requests in a dedicated git worktree, returning findings
  in chat or leaving pending inline comments for the user to submit. Use when
  asked to review a pull request, look over a PR, or check changes on GitHub.
---

# Reviewing pull requests

A request for a read-only review or findings in chat takes precedence over the pending review default. Otherwise, create pending inline comments when the user requests them or invokes this skill by name.

## Publication boundaries

Every review you write stays `PENDING`. Omit `event` and the top-level `body`, leaving only inline `comments[]`. The user writes the verdict and submits the review themselves.

Keep existing pending reviews and their comments. Read the user's comments before drafting yours, omit duplicates, and reuse their phrasing for the same class of issue. Never delete a pending review to make room for another. Ask the user before resolving an existing review thread.

These operations publish or change the pull request's status and are forbidden:

- `gh pr review`, including `--approve`, `--request-changes`, and `--comment`.
- `gh pr comment`.
- `POST /pulls/{n}/reviews/{id}/events`.
- `POST /pulls/{n}/comments` and `POST /pulls/comments/{id}/replies`.
- `POST /issues/{n}/comments`.
- The GraphQL `submitPullRequestReview` mutation, or `addPullRequestReview` with an `event` argument.
- `gh pr merge` and `gh pr close`.

## Prepare the worktree

Establish the repository and pull request number first. If the repository is missing, clone it into the layout its siblings use, e.g. `gh repo clone [owner]/[repo] ~/Development/[owner]/[repo]/main`.

Pass the repository checkout, pull request number, and any requested worktree path to [`opening-review-worktrees`](../opening-review-worktrees/SKILL.md). Use its returned path for the review, and follow its rules for handling a blocked checkout. Keep the user's checkout untouched.

## Read the change

Read the description, diff, checks, and discussion with `gh pr {view,diff,checks} [number]` and `gh pr view [number] --comments`. Read inline threads as well:

```sh
gh api repos/[owner]/[repo]/pulls/[number]/comments \
    --jq '.[] | "\(.path):\(.line // .original_line) \(.user.login)\n\(.body)\n"'
```

Check answered and outdated threads against the code before repeating a finding. When `line` is `null`, use `original_line` to locate the outdated anchor.

Review against the pull request's base, including when that base is another branch under review. `gh pr diff` supplies that boundary. For a local diff:

```sh
base=$(gh pr view [number] --json baseRefName --jq '.baseRefName')
git fetch origin "$base"
git diff "origin/$base...HEAD"
```

Read the surrounding code and applicable repository guidance, including `AGENTS.md` and `CONTRIBUTING.md`. Delegate bounded questions about callers, sibling implementations, or tests to `explore` when the scope justifies it. Read the diff and threads yourself, and retain responsibility for the base, findings, and line anchors.

When the change reflows prose, inspect the affected comments and docstrings for recurring defects.

## Draft and deliver findings

Before drafting review comments, read [`writing-as-hartikainen`](../writing-as-hartikainen/SKILL.md) and its [`references/code-review.md`](../writing-as-hartikainen/references/code-review.md) register. Anchor each comment to a line inside the base-relative diff. Keep preferences and concerns you cannot establish in chat.

For pending comments, read [`references/pending-reviews.md`](references/pending-reviews.md) before drafting or writing the review. It contains the commands for inspecting an existing pending review, creating or appending comments, and verifying the result. Do not create an empty review when no findings warrant inline comments.

Report findings, supporting evidence, verification, and the approval recommendation in chat. Name the retained worktree and its cleanup command, `git worktree remove [path]`. If you wrote pending comments, confirm the review remains `PENDING` and the anchors match the intended lines. If you appended to the user's review, confirm their comments survived and say that the review awaits their submission.
