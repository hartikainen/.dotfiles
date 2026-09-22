---
name: maintaining-pr-stacks
description: >-
  Maintain named GitHub pull requests in a local linear stack until tests pass,
  Codex reviews complete, and feedback is addressed. Create and reorder fixups
  on their owning branches, rebase descendants, push with exact leases, and
  resolve addressed threads. Use when the user asks to maintain their PR stack
  or handle comments on their stacked PR branches.
---

# Maintain a pull request stack

A request to maintain named PRs authorizes repeated correction, fixup commit, reordering, descendant rebase, exact-lease push, and silent thread resolution cycles for those PRs until the completion conditions below hold. The user need not repeat those permissions or approve each follow-up cycle. Explicit limits in the user's request take precedence. This does not authorize merging, closing PRs, submitting reviews, publishing replies, or touching other branches.

## Establish the stack boundary

Read every named PR with `gh pr view`, including `baseRefName`, `headRefName`, `headRefOid`, `reviews`, `comments`, and `statusCheckRollup`. Read all paginated review threads through GraphQL, including each thread's `id`, `isResolved`, `path`, `line`, `comments`, `author`, `createdAt`, and `updatedAt`. Timeline comments and review bodies must be assessed, but only review threads can be resolved.

Identify the repository's Codex review integration and how it records a review request, an in-progress review, and completion for a head commit. Track check runs and Codex review state against each PR's head OID. A review or passing check on an earlier head does not establish completion for the pushed head.

Map each PR head to its local branch and order the named branches from the bottom upward using PR base refs and commit ancestry. Stop when the branches are missing, nonlinear, checked out in another active worktree, or do not map unambiguously to the named PRs.

Before editing, record:

- The local tip and fetched remote tip of every affected branch.
- The PR head OID reported by GitHub.
- Every worktree holding an affected branch and its `git status --porcelain`.
- The commits present locally but absent from the observed remote tip.

Require clean worktrees and no pre-existing unpushed commits. Preserve the initial branch so that you can restore the user's checkout after the cycle.

## Judge the feedback

Read the current code rather than trusting the thread's original line. Classify each open thread as:

- Addressed during this cycle.
- Addressed by code already present at the observed PR head.
- Unresolved or no longer applicable for a reason that still needs the user's judgment.

Leave uncertain threads open. Assess actionable feedback in general comments and review bodies by the same criteria, recording whether it is addressed or needs judgment. These items have no thread resolution state; include their disposition in the final response.

For actionable feedback or a failing check, inspect the code and failure logs, use the PR diff boundary to find the owning branch, then identify the non-fixup commit that introduced the behavior. If the target commit is ambiguous, report the ambiguity instead of guessing. Correct failures attributable to the named stack and run relevant focused checks. Treat infrastructure failures and unrelated failures as blockers when they cannot be resolved within scope; do not weaken checks to make them pass.

## Create and propagate fixes

Read `writing-as-hartikainen` and its `references/commits.md` register before creating a commit. Process branches from the bottom upward:

1. Switch to the owning branch and make the smallest complete correction.
2. Run the relevant focused tests.
3. Stage only the files belonging to that correction.
4. Create the commit with `git commit --fixup=<target-commit>`.
5. Reorder the fixup immediately after its target commit (and any existing fixups for that target) on the owning branch before propagating it. Keep fixups as separate commits; do not autosquash them unless requested. Use an interactive rebase with `pick` entries to move them without folding them into their targets. Preserve the relative order of other commits and keep the rebase within the owning PR's diff boundary.
6. For each named descendant, run `git rebase --onto <updated-parent> <observed-parent> <descendant>` before applying that descendant's fixes.

Verify the reordered branch's final tree matches the tree before reordering, and record the resulting commit OIDs and local tips after each rebase. Do not push if the trees differ; correct the reordering or report the blocker.

A conflict means the automatic propagation is no longer trustworthy. Abort the rebase you started, restore the initial branch when safe, and report the conflict without resolving it by guesswork.

Re-read every local ref and fetch every remote ref before pushing. Compare local refs with the recorded results of this cycle and remote refs with the observed remote OIDs. If either moved outside this cycle, discard the stale assumptions and audit the stack again. Preserve this cycle's work and never reset over the movement.

Push all affected branches in one atomic command. Use one exact lease per ref, `--force-with-lease=refs/heads/<branch>:<observed-remote-oid>`, and explicit `<local>:refs/heads/<remote>` refspecs. The pushed difference may contain only fixups created in this cycle and rewrites required to reorder and propagate them. Do not push a pre-existing local commit. Record the accepted remote OIDs as the baseline for the next cycle.

## Keep review comments pending

Read `reviewing-pull-requests` before writing any review finding of your own. Add every such comment to an existing or created `PENDING` review, verify that the review remains `PENDING`, and never submit it. Report anything that cannot anchor to the PR diff in chat instead of publishing it elsewhere.

Replies to existing review threads have no pending mode on GitHub. Never reply to a thread, including with a fixed revision, because the reply would publish immediately.

## Resolve addressed threads silently

Wait until GitHub reports the pushed head before changing a thread.

Use the helper beside this skill rather than calling a resolution mutation directly:

```sh
python3 ~/.agents/skills/maintaining-pr-stacks/scripts/resolve-review-thread.py \
    --thread PRRT_kwDOExample
```

The helper resolves without commenting and is idempotent. Do not resolve an unresolved finding. The user's maintenance request supplies the approval that `reviewing-pull-requests` requires before resolving the named threads.

## Monitor until complete

Snapshot head OIDs, check runs, thread IDs, comment IDs, review IDs, and timestamps. Poll the named PRs while checks or Codex reviews are pending, and read follow-up feedback when it appears. Continue correction, propagation, push, and resolution cycles without asking for approval again. After each push, wait for GitHub to report the pushed heads and reassess checks and Codex reviews for those heads. Do not infer review completion from silence, an empty review list, or the absence of unresolved threads.

Finish only after a fresh read confirms all of the following for every named PR at its observed head:

- Tests and required checks pass, with no pending or failing applicable runs. Accept skipped or neutral checks only when the repository treats them as non-blocking; they are not evidence that a required test ran successfully.
- Codex review has completed for that head, with no review still queued or running. Use the integration's completion evidence, including a supported no-findings outcome.
- All actionable review feedback is addressed, addressed threads are resolved, and no comment remains awaiting a correction or the user's judgment.

Do not impose a fixed watch deadline unless the user supplies one. Stop early for a user interruption or a blocker requiring input or unavailable access (including an unresolvable check failure, ambiguous feedback, a rebase conflict, or a review integration whose completion state cannot be obtained). A queued or running review is a reason to keep monitoring. Complete independent work first. If review requires a public trigger comment, request authorization for that comment instead of publishing it under the maintenance permission. If monitoring cannot continue, report the incomplete state and the condition needed to resume; do not claim completion.

Restore the initial checkout when safe. In the final response, list every fixup with its full resulting OID, target branch, and change. Name the rebased and pushed branches, test and Codex review results with their head OIDs, resolved threads, and any unresolved comments or blockers with the next action.
