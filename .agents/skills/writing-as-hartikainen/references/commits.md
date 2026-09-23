# Commit messages

Read [change-descriptions.md](change-descriptions.md) for content and tone. Drop courtesy hedges while preserving factual uncertainty.

- Use a concise, imperative subject line in sentence case, without a trailing period, within the 60-character limit. Start with a verb. Do not add a conventional-commit prefix or scope.
- Give the subject line a concrete change and scope. Name the affected component when enumerating individual edits would obscure their shared purpose.
- Omit the body when the subject communicates the change and no rationale is needed. Otherwise separate it with a blank line.
- Follow the repository's commit-body wrapping convention, including any commit-specific `.dir-locals.el` or `.editorconfig` settings. Use 72 characters when no convention is specified. Leave long URLs and fenced blocks intact.
- Put a relevant tracker reference at the end in the tracker's own key format.
