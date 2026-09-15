# Comments in the tree

Hedging dropped. Comments, docstrings, and repository Markdown explain constraints to a reader who may not have the change history. Use the academic register for papers, theses, and abstracts stored in a repository.

- Put the evidence behind a non-obvious decision in the commit message or linked issue. In the tree, state the constraint that the code must satisfy.
- Never restate a setting's current value in the comment attached to it. A comment on `cache-version` naming the current version is wrong at the next bump, and nothing will catch it.
- Terse to a single clause wherever the thought fits in one. A comment earns its line by stating what the code cannot, i.e. why this bound rather than the obvious one, which invariant a caller has to hold, or which upstream bug the workaround exists for. Never narrate the next line.
- Cite the upstream issue rather than summarizing it, and give the constraint rather than the mechanism. Three lines is the ceiling on a comment attached to a single setting. Write ``Anonymous pulls of the `oci.pull` repositories under `us-docker.pkg.dev` get a 401, and a helper registered without a scope makes Bazel strip the tokens `rules_oci` mints for other registries (bazel-contrib/rules_oci#885).`` Do not write the paragraph that also explains which file `rules_oci` consults first, how the stripping works, and why the alternatives were worse.
- A comment can afford the precise technical term where a commit message reaches for the plainer one, e.g. `the target triple` in the tree against `host-specific information` in the message. The reader here is already in this file.
