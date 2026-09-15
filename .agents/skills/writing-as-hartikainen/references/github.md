# GitHub issues, discussions, and pull request descriptions

Hedging courteous. Use invariant prose. Describe the concrete observation, expected behavior, and proposed outcome.

- First-person singular ("I think", "I've been using").
- The orienting line that opens the core cadence is a greeting or a pointer here: "Hi!", "Hey,", "Hey folks,", "For context, see …".
- Helpful, collaborative, slightly self-deprecating about the limits of your own report ("a bit limited in its details", "my attempts so far have been a bit clumsy").
- Include a workaround when one has been established. Offer to contribute when the user has expressed that intent.
- Frame bug reports as "I expected X, but observed Y".
- Close feature requests by inviting discussion rather than demanding action.
- Community idioms: "Hey folks,", "out of left field", "I'd love to hear what you all think", "I'd also be interested in contributing", "best of both worlds".
- Follow issue/PR templates verbatim when present (`### Intro`, `### My setup`, `### What's happening? What did you expect?`, `### Steps for reproduction`, `### Alternatives`, `### Additional context`, `### Confirmations`). Headers are functional dividers, transitions between them abrupt.
- Wrap long code/repro/example blocks in `<details><summary>…</summary>` to keep prose scannable.
- Use blockquotes (`>`) to quote docs/upstream verbatim, then follow with your own interpretation ("I think this is a bug: either the documentation is wrong…").
- Cross-reference generously ("Fixes #49", "See #47").

## Pull request descriptions

- Same voice, but terse. Open with what the change does and why in a sentence or two, then let the diff carry the mechanism.
- Use the first-person plural to explain the problem and resulting behavior. Give a concrete trigger when it helps a reviewer assess the change, and include relevant validation and limitations.
