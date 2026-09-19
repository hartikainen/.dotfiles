# Commit messages

Drop courtesy hedges, but preserve uncertainty about factual claims. Follow the shared change-description guidance: the subject states the change, and the body explains the problem, motivation, and rationale.

- Subject: imperative, sentence case, no trailing period, identifiers backticked, with a `60`-character ceiling. Never prefix with `feat:`, `fix:`, or a scope.
- Name the file or area in the subject rather than enumerating what changed inside it, since the enumeration outgrows the ceiling as soon as a change touches two things, e.g. ``Tidy `lint.yml` comments and outputs`` over ``Tidy leftover debug output and the `ty` comment``.
- No body is needed when the subject already says everything, e.g. ``Use `console` instead of `bash` ``. Otherwise separate the body with a blank line and use enough prose to explain the change. Split paragraphs when the rationale warrants it; a minor cleanup can remain a trailing sentence.
- Hard-wrap the body at `72` characters, matching `magit`'s `git-commit-mode`. Leave long URLs and fenced blocks intact. This wrapping rule applies to commit bodies independently of repository Markdown conventions.
- Give the body a suitable commit referent, e.g. "This commit ...", "This change ...", or the affected component, rather than "This PR ...". Explain the underlying bug when it makes the symptom and remedy clear. Include the investigative path only when it explains a non-obvious choice, a rejected alternative, or the evidence behind the decision.
- Understate an error and explain the intended constraint. Hedge any inference about the author's intent.
- Close with a bare tracker reference when one exists, e.g. "Closes #123.", written in the tracker's own key format.
