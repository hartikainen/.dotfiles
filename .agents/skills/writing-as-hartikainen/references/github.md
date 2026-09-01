# GitHub issues, discussions, and pull request descriptions

Hedging courteous. Time dated: these are read once and then archived, so `currently`, `for now`, and "this used to …" all belong here, as does the before/after framing that a comment in the tree has to avoid.

- First-person singular ("I think", "I've been using").
- The orienting line that opens the core cadence is a greeting or a pointer here: "Hi!", "Hey,", "Hey folks,", "For context, see …".
- Helpful, collaborative, slightly self-deprecating about the limits of your own report ("a bit limited in its details", "my attempts so far have been a bit clumsy").
- Always offer the workaround you found, and signal willingness to contribute.
- Frame bug reports as "I expected X, but observed Y".
- Close feature requests by inviting discussion rather than demanding action.
- Community idioms: "Hey folks,", "out of left field", "I'd love to hear what you all think", "I'd also be interested in contributing", "best of both worlds".
- Follow issue/PR templates verbatim when present (`### Intro`, `### My setup`, `### What's happening? What did you expect?`, `### Steps for reproduction`, `### Alternatives`, `### Additional context`, `### Confirmations`). Headers are functional dividers, transitions between them abrupt.
- Wrap long code/repro/example blocks in `<details><summary>…</summary>` to keep prose scannable.
- Use blockquotes (`>`) to quote docs/upstream verbatim, then follow with your own interpretation ("I think this is a bug: either the documentation is wrong…").
- Cross-reference generously ("Fixes #49", "See #47").

## Pull request descriptions

- Same voice, but terse. Open with what the change does and why in a sentence or two, then let the diff carry the mechanism.
- Describe the tree as it stands in the present tense and in the first-person plural, then mark the change as a change: "We currently have four workflows that each define their own copy of the deploy-key setup", and later "After this change, the keys reach the script through `env`". Do not narrate the state before the change in the past tense ("Four workflows defined their own copy") against a bare present for the result ("the keys now reach the script through `env`"), which leaves the reader working out which side of the change each sentence sits on.
- Numbers are welcome in a way they are not in a comment in the tree, since the description ages out alongside the review.
