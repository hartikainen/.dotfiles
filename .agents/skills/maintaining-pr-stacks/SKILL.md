---
name: maintaining-pr-stacks
description: >-
  Maintain named GitHub pull requests in a local linear stack by addressing
  review feedback with fixup commits, rebasing descendants, pushing with exact
  leases, resolving addressed threads, and watching for follow-up activity.
  Use when the user asks to handle comments on their own stacked PR branches.
---

# Maintain a pull request stack

This workflow mutates the user's branches and GitHub review threads. A request
to maintain named PRs authorizes those operations for the named PRs only. It
does not authorize merging, closing PRs, submitting reviews, or touching other
branches.

## Establish the stack boundary

Read every named PR with `gh pr view`, including `baseRefName`, `headRefName`,
`headRefOid`, `reviews`, `comments`, and `statusCheckRollup`. Read all paginated
review threads through GraphQL, including each thread's `id`, `isResolved`,
`path`, `line`, `comments`, `author`, `createdAt`, and `updatedAt`. Timeline
comments and review bodies must be assessed, but only review threads can be
resolved.

Map each PR head to its local branch and order the named branches from the
bottom upward using PR base refs and commit ancestry. Stop when the branches
are missing, nonlinear, checked out in another active worktree, or do not map
unambiguously to the named PRs.

Before editing, record:

- The local tip and fetched remote tip of every affected branch.
- The PR head OID reported by GitHub.
- Every worktree holding an affected branch and its `git status --porcelain`.
- The commits present locally but absent from the observed remote tip.

Require clean worktrees and no pre-existing unpushed commits. Preserve the
initial branch so that you can restore the user's checkout after the cycle.

## Judge the feedback

Read the current code rather than trusting the thread's original line. Classify
each open thread as:

- Addressed during this cycle.
- Addressed by code already present at the observed PR head.
- Unresolved or no longer applicable for a reason that still needs the user's
  judgment.

Leave uncertain threads open. A general comment without a review thread stays
open by construction and belongs in the report.

For an actionable thread, use its PR diff boundary to find the owning branch,
then identify the non-fixup commit that introduced the behavior. If the target
commit is ambiguous, report the ambiguity instead of guessing.

## Create and propagate fixes

Read `writing-as-hartikainen` and its `references/commits.md` register before creating a
commit. Process branches from the bottom upward:

1. Switch to the owning branch and make the smallest complete correction.
2. Run the relevant focused tests.
3. Stage only the files belonging to that correction.
4. Create the commit with `git commit --fixup=<target-commit>`.
5. For each named descendant, run `git rebase --onto <updated-parent>
   <observed-parent> <descendant>` before applying that descendant's fixes.

A conflict means the automatic propagation is no longer trustworthy. Abort
the rebase you started, restore the initial branch when safe, and report the
conflict without resolving it by guesswork.

Re-read every local ref and fetch every remote ref before pushing. If a ref has
moved since its recorded OID, assume the user rebased or squashed the stack,
discard the stale plan, and audit the updated stack again. Never reset over the
movement.

Push all affected branches in one atomic command. Use one exact lease per ref,
`--force-with-lease=refs/heads/<branch>:<observed-remote-oid>`, and explicit
`<local>:refs/heads/<remote>` refspecs. The pushed difference may contain only
fixups created in this cycle and descendant rewrites required to propagate
them. Do not push a pre-existing local commit.

## Keep review comments pending

Read `reviewing-pull-requests` before writing any review finding of your own.
Add every such comment to an existing or created `PENDING` review, verify that
the review remains `PENDING`, and never submit it. Report anything that cannot
anchor to the PR diff in chat instead of publishing it elsewhere.

Replies to existing review threads have no pending mode on GitHub. Never reply
to a thread, including with a fixed revision, because the reply would publish
immediately.

## Resolve addressed threads silently

Wait until GitHub reports the pushed head before changing a thread.

Use the helper beside this skill rather than calling a resolution mutation
directly:

```sh
python3 ~/.agents/skills/maintaining-pr-stacks/scripts/resolve-review-thread.py \
    --thread PRRT_kwDOExample
```

The helper resolves without commenting and is idempotent. Do not resolve an
unresolved finding. The user's maintenance request supplies the approval that
`reviewing-pull-requests` requires before resolving the named threads.

## Report and watch

List every fixup commit with its full OID, target branch, and change. Name the
rebased and pushed branches, tests, resolved threads, unresolved comments, and
a proposed resolution for each remaining item.

Snapshot thread IDs, comment IDs, review IDs, and timestamps, then monitor the
named PRs for up to `60 minutes`. When activity appears, report a concise
summary and proposed resolution, then wait for the user's approval. Do not
start another edit, push, reply, or resolution cycle without that approval. If
the deadline passes without activity, report that once and stop.
