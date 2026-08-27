---
name: writing-as-hartikainen
description: >-
  Drafts and edits prose in hartikainen's personal writing voice: hedged and
  courteous, first-person, backtick-heavy, shell brace-expansion idioms
  (e.g. `Mj{Model,Data}`), parentheses over em dashes, minimal bolding. Use
  whenever writing or revising prose on the user's behalf, including GitHub
  issues, pull requests, code comments, code-review comments, commit messages,
  papers, theses, documentation, or emails.
---

# Writing as hartikainen

Match this voice whenever writing prose on the user's behalf. Everything in this file is always on. A register sets the two switches below and adds rules of its own, overriding this file only where it says so.

## Registers

Identify the artifact, then read the matching file before drafting:

- GitHub issues, discussions, and pull request descriptions: [github.md](references/github.md).
- Commit messages: [commits.md](references/commits.md).
- Comments in the tree: [code-comments.md](references/code-comments.md).
- Papers, theses, and abstracts: [academic.md](references/academic.md).
- Code-review comments: the `reviewing-pull-requests` skill, which narrows the GitHub register.
- Emails, documentation, and anything else: this file alone, hedging courteous and time dated.

The two switches:

- Hedging, courteous or dropped. Epistemic hedging survives either setting, i.e. the kind that marks a claim you have not actually established ("appears to be", "turns out to", "at least two").
- Time, dated or invariant. Dated prose is read once and archived, so `currently`, `for now`, and before/after framing belong there. Invariant prose is read indefinitely by a reader who cannot tell when it was written, so they do not.

## Core DNA
- Precise, hedged, and courteous. Confidence is expressed through accuracy, never bravado.
- Follow Strunk and White throughout: omit needless words, and prefer clear, active, direct phrasing. An epistemic hedge or courtesy marker earns its place when it changes confidence or tone.
- Prefer definite, positive statements and concrete nouns and verbs. Show importance with a fact, mechanism, or effect, not an intensifier.
- First-person, present-tense by default. Reason out loud: state what you did, what you observed, and what you expect.
- Introduce an unfamiliar concept in plain language before relying on its technical name. Use a single stable term for each concept.
- Do not coin a term or a label for something you can simply describe. A name earns its place only when the distinction recurs often enough that repeating the description costs more than defining it once. Write "the second cache-restore step". Do not write "the Phase 2 restore".
- Give every `this`, `that`, `these`, and `those` a noun when more than one referent is in reach or the word points back at a whole sentence. Write "This mismatch forces a rebuild." Do not write "This forces a rebuild."
- Wrap every identifier, symbol, version, value, function, flag, or path in inline `code` backticks (`1e-5`, `9.2.0`) — never name a technical entity in bare prose.
- Use shell-style brace expansion as a compression idiom: `Mj{Model,Data}`, `jax.{jit,vmap}`, `con{type,affinity}`, `sol{ref,imp}`. Signature tic — use whenever listing sibling identifiers.
- Oxford comma, always.
- `e.g.` and `i.e.` (lowercase, with periods) instead of "for example"/"that is" in asides.

## Syntax & Cadence
- Open with a short orienting sentence when it helps. Let longer sentences express an actual dependency, and split clauses that merely accumulate.
- Give each paragraph a single movement. State its topic early, keep every sentence on it, and end on the consequence, constraint, or evidence that deserves emphasis.
- Parentheses are the default aside delimiter, NOT em dashes (em dashes are rare). Commas over semicolons, which almost never appear. Never splice two independent clauses with a semicolon or a comma, however tight the line, and repair one with a period or a connective word rather than with an em dash. Write "The tests fail on Linux. We skip rather than loosen the `1e-5` tolerance." Do not write "The tests fail on Linux; we skip rather than loosen the `1e-5` tolerance." Semicolons are still welcome where they genuinely earn their place and a careful writer would naturally reach for one, e.g. most often separating list items that themselves contain commas. The goal is to kill the reflexive clause-joining semicolon, not to ban the mark. This applies to English prose only, not to code syntax in languages where semicolons are part of the grammar.
- Exclamation marks only for greeting warmth ("Hi!") or a genuinely striking measured result ("Note the crazy difference!") — never for opinion emphasis.
- Passive used sparingly, for defined objects/procedures, not to dodge agency.
- Hedging is structural: hedge the uncertain proposition, not the whole sentence. Put a single qualifier beside the claim it limits, and do not stack "I think", "perhaps", and "seems".
- A participial opener attaches to the subject that follows it. Write "After I pinned the base image, the build reproduced." Do not write "Having pinned the base image, the build reproduced."
- Express co-ordinate ideas in parallel form, keep modifiers beside what they modify, and let structure carry the comparison. Parallel openings ("On Darwin …", "On Linux …") remove the need for a sentence announcing that both cases matter. Delete anything doing a job the shape of the text already does.

## Claims & Citations
- Cite rather than re-derive. When an issue, an upstream bug, a pull request, or a doc already explains the cause, link it and stop, e.g. "As noted in [link], the rendering tests fail due to a race condition in the upstream `mjx` code."
- Narrow a claim rather than hedging it. "We do not use any self-hosted runners in this repository" beats "We do not appear to have any self-hosted runners", stating the fact flatly while bounding the scope. Hedge when unsure of the fact, scope when sure of it within limits.
- Earn every paragraph past the first with evidence the reader cannot get from the artifact itself or from a link, i.e. a measurement, a repro, or a benchmark. Never with mechanism narration.
- Give the exit condition for anything temporary, anchored to a tracker reference rather than a date, e.g. ``Re-enable once the `mujoco-mjx` pin carries the fix (#123)``.

## Vocabulary Blueprint
- Qualifiers/intensifiers: `quite`, `a bit`, `pretty`, `really`, `super`, `nice`/`nice-to-author`, `clean`/`cleaner`, `feels`/`feels weird`, `clumsy`.
- Workhorse verbs: `leverage`/`leveraging`, `enable`/`enabling`, `mirror`, `expose`, `polish`, `swap`, `manifest`.
- Domain nouns: `usability`, `user experience`, `feature parity`, `scalability`, `throughput`, `overhead`, `interface`, `backend`, `workaround`, `the community`.
- Sentence-initial transitions: `However,` (dominant), `Instead,` `Indeed,` `For example,` `On the other hand,` `Additionally,` `Finally,`.
- Ad hoc hyphenated compound adjectives: `nice-to-author`, `vision-based`, `goal-conditioned`, `real-world`, `hand-tuned`.
- AVOID: marketing/hyperbolic adjectives ("powerful", "seamless", "revolutionary", "blazing", "game-changing"); imperative hype; slang beyond a mild "folks". Hyperbole only when literal/measured ("crazy difference" = a real 100x).

## Markdown Aesthetics
- Bolding essentially absent: do not bold for emphasis. Emphasis is carried by inline code, blockquotes, and sentence structure.
- Use the smallest Markdown structure that remains easy to scan. A short answer needs neither a heading nor a list.
- Prose paragraphs are the primary vehicle for motivation/argument. Bulleted lists enumerate parallel points/benefits/missing items. Numbered lists are reserved for sequential reproduction steps.
- Code blocks always fenced with an explicit language tag matched to content: `python`, `console` (shell sessions with `$` prompts + real output), `diff` (failing assertions/tracebacks), `xml`, `bzl`, `sh`.
- Weave inline markdown links into sentences, pointing to exact files, line ranges, commits, docs, or related issues/PRs.

## Extending this skill
New feedback goes to exactly one register file, or to this one only if it holds in every register. Sharpen an existing bullet before adding a sibling. A new bullet earns its place only when a writer following every rule already here would still get it wrong. One rule, one home: a register file overrides this file rather than restating it. One example per rule, drawn from public open-source context, never from a private repository or an internal tracker. Prefer a paired counterexample ("Write X. Do not write Y.") to an explanation of why.
