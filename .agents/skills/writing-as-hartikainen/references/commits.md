# Commit messages

Read [change-descriptions.md](change-descriptions.md) for content and tone. Drop courtesy hedges while preserving factual uncertainty.

- Use an imperative subject in sentence case, without a trailing period, within the `60`-character limit. Do not add a conventional-commit prefix or scope.
- Give the subject a concrete action and scope. Name the affected file or area when enumerating individual edits would obscure their shared purpose.
- Omit the body when the subject communicates the change and no rationale is needed. Otherwise separate it with a blank line.
- Hard-wrap the body at `72` characters to match `magit`'s `git-commit-mode`. Leave long URLs and fenced blocks intact.
- Put a relevant tracker reference at the end in the tracker's own key format.
