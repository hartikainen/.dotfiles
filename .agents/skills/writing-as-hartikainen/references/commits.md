# Commit messages

Hedging dropped. Use invariant prose. State the change and the constraint it satisfies, without an orienting opener or an explanatory sweep.

- Subject: imperative, sentence case, no trailing period, identifiers backticked, with a `60`-character ceiling. Never prefix with `feat:`, `fix:`, or a scope.
- Name the file or area in the subject rather than enumerating what changed inside it, since the enumeration outgrows the ceiling as soon as a change touches two things, e.g. ``Tidy `lint.yml` comments and outputs`` over ``Tidy leftover debug output and the `ty` comment``.
- No body at all is correct when the subject already says everything, e.g. ``Use `console` instead of `bash` ``. Otherwise one short paragraph is the default, after a blank line. One paragraph stays the budget when the change touches two things, so the secondary cleanup earns a trailing sentence, e.g. ``Also cleans up the `Run ty type check` comment.``, rather than a paragraph and a justification of its own.
- Hard-wrap the body at `72` characters, matching `magit`'s `git-commit-mode`. Leave long URLs and fenced blocks intact. This wrapping rule applies to commit bodies independently of repository Markdown conventions.
- Open the body with the symptom in plain language, then explain the constraint that determines the change.
- Record the observation that explains the change, then say what the change does rather than explaining the underlying bug. Include the investigative path only when it explains a non-obvious choice, a rejected alternative, or the evidence behind the decision.
- Understate an error and explain the intended constraint. Hedge any inference about the author's intent.
- Close with a bare tracker reference when one exists, e.g. "Closes #123.", written in the tracker's own key format.
