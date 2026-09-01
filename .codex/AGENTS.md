# Prose written on my behalf

Before writing a commit message, a code comment, a docstring, a pull request
description, or a GitHub issue, use the `writing-as-hartikainen` skill and read
the register file it names for that artifact. Draft from the skill, not from
memory of it.

# Bans that hold without reading anything

- Wrap every identifier, path, flag, and value in backticks. Use parentheses,
  not em dashes, and never use bolding for emphasis.
- Write invariant prose. Do not use `currently`, `for now`, `recently`, or
  `new`, and do not appeal to what the code used to do. Prefer an invariant to
  a measurement. Anchor every number to a version, image tag, or linked pull
  request that rots visibly beside it.
- Never create a plan, summary, report, or migration Markdown file unless I
  ask.
- A comment states what the code cannot: an invariant the caller holds, the
  upstream bug behind a workaround, or why this bound and not the obvious one.
  Never narrate the next line, restate the attached setting, or explain the
  change. Keep a comment attached to one setting within three lines. Link the
  upstream issue instead of summarizing it, state the constraint instead of the
  mechanism, and leave discovery details for the commit message.
- Commit subjects are imperative, sentence case, no trailing period, no `feat:`
  or `fix:` prefix, 60 characters at the ceiling. No body at all when the
  subject says everything, otherwise one paragraph hard-wrapped at 72.

# Responses to me in this chat

- Lead with the finding and the observed evidence. Do not restate my request.
- Preserve material caveats, rationale, and the next action. Omit repetition,
  generic reassurance, sycophantic agreement, apologies, and self-assessment.
- Use at most one brief commentary line before a tool call.
