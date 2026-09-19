# GitHub issues, discussions, and pull request descriptions

## Issues and discussions

Hedging courteous. Use invariant prose. Describe the concrete observation, expected behavior, and proposed outcome.

- First-person singular ("I think", "I've been using").
- The orienting line that opens the core cadence is a greeting or a pointer here: "Hi!", "Hey,", "Hey folks,", "For context, see …".
- Helpful, collaborative, slightly self-deprecating about the limits of your own report ("a bit limited in its details", "my attempts so far have been a bit clumsy").
- Include a workaround when one has been established. Offer to contribute when the user has expressed that intent.
- Frame bug reports as "I expected X, but observed Y".
- Close feature requests by inviting discussion rather than demanding action.
- Community idioms: "Hey folks,", "out of left field", "I'd love to hear what you all think", "I'd also be interested in contributing", "best of both worlds".
- Follow issue templates verbatim when present (`### Intro`, `### My setup`, `### What's happening? What did you expect?`, `### Steps for reproduction`, `### Alternatives`, `### Additional context`, `### Confirmations`). Headers are functional dividers, transitions between them abrupt.
- Wrap long code/repro/example blocks in `<details><summary>…</summary>` to keep prose scannable.
- Use blockquotes (`>`) to quote docs/upstream verbatim, then follow with your own interpretation ("I think this is a bug: either the documentation is wrong…").
- Cross-reference generously ("Fixes #49", "See #47").

## Pull request descriptions

Follow the shared change-description guidance for active, conversational bodies with enough context and rationale. The issue/discussion greeting and invariant-prose rules above do not apply here.

- Use a concise imperative title. Explain the existing behavior, problem or personal motivation, and resulting change in the body rather than issuing a series of commands.
- Prefer "This PR ..." when introducing what the change does. Name the issue or say "both issues" when the referent would otherwise be ambiguous. First-person singular is welcome for user-supplied experience, e.g. "I was experimenting with ...".
- A brief parent reference such as "Depends on #162" is enough when the parent supplies the context. Avoid repeating that dependency in several places or recapping its implementation.
- Follow the repository's PR template when present; otherwise use paragraphs and add structure only when it helps the reader.
