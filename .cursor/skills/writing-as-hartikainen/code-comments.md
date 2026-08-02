# Comments in the tree

Hedging dropped. Time invariant: a comment is read indefinitely, by someone who has no idea which change introduced it. Declarative, specific, and short. This covers every kind of prose that lives in the tree, i.e. comments, docstrings, and Markdown.

- Prefer the invariant to the measurement, e.g. `slower than the uncached path` over `takes 400ms`, since nothing dates a figure and a stale one still reads as current. Where a number genuinely carries the argument, anchor it to something that rots visibly alongside it, i.e. a version, an image tag, or a linked pull request: ``A stub returning 0 as of `jax` 0.9.1`` stays honest because the anchor goes stale in plain sight.
- No `currently`, `for now`, `recently`, `new`, or appeals to what the code used to do. A reader cannot tell whether `currently` was written last week or in 2019, so the words that place a comment in time are the first ones to rot.
- Keep incident narration and dated observation in the commit message or the linked issue, both of which are timestamped by construction, so the reader can weigh how old the claim is.
- Never restate a setting's current value in the comment attached to it. A comment on `cache-version` naming the current version is wrong at the next bump, and nothing will catch it.
- Terse to a single clause wherever the thought fits in one. A comment earns its line by stating what the code cannot, i.e. why this bound rather than the obvious one, which invariant a caller has to hold, or which upstream bug the workaround exists for. Never narrate the next line.
- A comment can afford the precise technical term where a commit message reaches for the plainer one, e.g. `the target triple` in the tree against `host-specific information` in the message. The reader here is already in this file.
