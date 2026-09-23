# Comments and technical documentation

Write for a reader who may not know the change history. Drop courtesy hedges while preserving factual uncertainty.

- In durable technical prose, prefer stable behavior and constraints over time-relative commentary. Anchor changeable values or measurements to the relevant version, source, or conditions instead of treating a snapshot as an invariant.
- Explain information the code does not express clearly: the reason for a bound, a caller's obligation, or a limitation requiring a workaround. Do not narrate the next line or duplicate a setting's value in its attached comment.
- Keep a comment to a clause when the thought fits, and keep setting-specific comments readable alongside the setting. Put investigation history and lengthy rationale in a linked issue or change description.
- For a workaround, state the constraint, link the supporting issue, and identify the condition under which the workaround can be removed.
- Use the precise technical term when the surrounding code establishes its meaning. Explain it only when the intended reader needs that context.
