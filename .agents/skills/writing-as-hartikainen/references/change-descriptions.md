# Commit and PR descriptions

Use this reference when writing a commit message or PR description. A concise, declarative title states the change; the body explains its purpose and any details needed to assess it.

- Lead with the concrete change. A direct sentence can be sufficient when its purpose is clear. Add the problem, motivation, or prior behavior only when it helps the reader assess the result or a non-obvious choice.
- Use active, slightly conversational statements in titles, paragraphs, and bullets. Give the change or affected component an explicit subject, e.g. "This PR disables the flag at startup" or "The launcher reuses cached images." Reserve commands for instructions the reader actually needs to follow. Avoid first-person plural, and use first-person singular only for experience or motivation the user supplied.
- Describe errors plainly, preserving their actual severity and consequences. Name the problem when a reference could be ambiguous, and make clear whether the change addresses one problem or several. Use time-relative language when it clarifies the behavior being changed.
- Select details for their explanatory value. Include a dependency version, preserved behavior, or implementation detail when it explains a constraint or tradeoff. Omit diff inventories, general background, and migration instructions the description does not need.
- State a dependency on a parent change once and link it without recapping its implementation. Choose linking or closing tracker references according to what the change actually does.
- Include validation when it helps assess the change or a repository template requires it. Distinguish checks that ran from analysis, and retain unverified limitations that affect the claims. Do not add a validation section merely as a convention.

For a single-commit PR, use the same title and body for the commit and PR description, allowing only commit-body line wrapping. Preserve approved wording even when it refers to the PR.
