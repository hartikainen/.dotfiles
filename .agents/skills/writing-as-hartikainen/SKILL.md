---
name: writing-as-hartikainen
description: >-
  Draft or edit prose in hartikainen's voice for code comments, documentation,
  commit messages, GitHub, papers, and emails.
---

# Writing as hartikainen

Use this skill for prose written on the user's behalf. Internal search findings, tool diagnostics, and agent handoffs follow their task's result format.

## Registers

Read the register for the artifact being written:

- GitHub issues, discussions, and pull request descriptions: [github.md](references/github.md).
- Commit messages: [commits.md](references/commits.md).
- Code comments, docstrings, and repository Markdown: [code-comments.md](references/code-comments.md).
- Papers, theses, and abstracts: [academic.md](references/academic.md).
- Code-review comments: [code-review.md](references/code-review.md).
- Emails and other prose without a specialized register: this file alone.

Choose the register by purpose (a paper stored in a repository still uses the academic register). The review register covers drafting comments; the `reviewing-pull-requests` workflow handles preparing a review on GitHub.

## Shared voice

- Use first-person, present-tense prose. Courtesy is the default; registers can drop courtesy hedges. Preserve epistemic hedging when a claim is uncertain, and put the hedge beside that claim.
- Prefer concrete nouns, precise verbs, and active sentences. Explain an unfamiliar term before relying on it. Avoid invented labels, stock transitions, marketing language, and intensifiers that add no information.
- Write invariant prose in every register. Avoid `currently`, `for now`, `recently`, `new`, and appeals to what the code used to do. Prefer an invariant to a measurement. Anchor a necessary number to a version, image tag, or linked pull request.
- Wrap identifiers, symbols, versions, values, functions, flags, and paths in backticks. Compress sibling identifiers with shell-style braces, e.g. `Mj{Model,Data}` or `jax.{jit,vmap}`.
- Use parentheses for asides and no bolding for emphasis. Use the Oxford comma and `e.g.` or `i.e.` in asides. Separate independent sentences with periods; use semicolons only when they clarify a complex list.

## Syntax & Cadence

- Give each paragraph a purpose: introduce the point, support it, and end on its consequence or constraint. Let longer sentences express a dependency rather than accumulate unrelated clauses.
- Name the referent when `this`, `that`, `these`, or `those` could point to several things. Write "This mismatch forces a rebuild."
- Let parallel sentence structure carry comparisons. Keep modifiers next to what they modify, and avoid a sentence announcing what the structure already shows.

## Claims & Citations

- Link the issue, pull request, or documentation that establishes the claim. State the consequence relevant to the reader instead of re-deriving the source.
- Scope a supported claim precisely. Hedge uncertainty about the fact, not confidence within an established scope.
- Add detail when it supplies evidence or reasoning the reader needs and cannot get from the attached artifact. Omit repetitive mechanism narration.
- Give temporary workarounds an exit condition tied to an upstream tracker or dependency change.

## Markdown Aesthetics

- Prefer paragraphs. Use lists for parallel points or sequential steps, and headings only when they help navigation.
- Fence code with the matching language tag, e.g. `python`, `console`, `diff`, or `sh`.
- Put links beside the claims they support and point to the exact file, commit, documentation, or issue.

## Extending this skill

Put artifact-specific feedback in its register and shared guidance here. Refine an existing rule before adding another, and keep examples public and necessary to explain the distinction.
