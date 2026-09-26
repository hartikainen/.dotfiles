# Working through tasks

Work within the agreed scope and applicable safety and approval requirements.

- Finish the requested result, including relevant checks and corrections. State any part you cannot complete or verify.
- Read the files and skill references needed for the task. Follow the project's delegation policy. When delegation is authorized, use a configured specialist for bounded, independent work and check its findings before relying on them.
- Complete required checks, then broaden verification only for an unresolved concern. A prose edit does not need an unrelated test suite.
- Use context for routine choices. Ask when missing input changes correctness, scope, or authorization. If an instruction requires a pause, quote and link its source, and continue any preparation it permits.

# Branches and commits

A request to implement, add, or fix something authorizes local commits for that work. Do not ask for commit approval again unless the user limits that permission.

- For work on an existing branch, use that branch. Commit corrections with `git commit --fixup=<target-commit>`, targeting the branch commit responsible for the behavior. Split corrections with different targets into separate fixups. Additions that do not correct an existing branch commit belong in ordinary focused commits. Ask if the owning branch or fixup target is ambiguous.
- For a stack maintained with `maintaining-pr-stacks`, follow that skill. The maintenance request authorizes fixups on the owning branches, descendant rebases, and pushes to the verified PR head remote with exact `--force-with-lease` values. Keep all named local stack branches updated with their parents, and verify that their tips match the accepted remote tips after each push.
- For independent work starting from `main`, fetch the intended remote and create a clean worktree and topic branch from its `main` tip before editing. Use the repository's branch and worktree naming conventions. Keep the user's existing checkout and local changes intact.
- Keep commits limited to a coherent, reviewable change. Inspect the diff, stage only the task's files or hunks, and run the relevant checks before committing. Preserve unrelated staged and unstaged changes. Do not include temporary artifacts or unfinished work in a completion commit.
- Commit permission alone does not authorize pushing. Outside the stack maintenance workflow, push only when the user has authorized it.

# Prose written on my behalf

Before writing a commit message, a code comment, a docstring, documentation, a pull request description, a review comment, or a GitHub issue, use the `writing-as-hartikainen` skill and read the register it names for that artifact. Draft from the skill, not from memory of it.

# Writing conventions

- Wrap every identifier, path, flag, and value in backticks. Use parentheses, not em dashes, and never use bolding for emphasis.
- Write invariant prose. Do not use `currently`, `for now`, `recently`, or `new`, and do not appeal to what the code used to do. Prefer an invariant to a measurement. Anchor every number to a version, image tag, or linked pull request that rots visibly beside it.
- Never create a plan, summary, report, or migration Markdown file unless I ask.

# Responses to me in this chat

- Lead with the finding and the observed evidence. Do not restate my request.
- Prefer concise paragraphs. Use lists or tables when they make the material easier to scan or compare. Use concrete words and direct statements.
- Preserve material caveats, rationale, and the next action. Omit repetition, generic reassurance, sycophantic agreement, apologies, and self-assessment.
- Use at most one brief commentary line before a tool call.
