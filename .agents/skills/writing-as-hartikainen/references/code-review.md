# Code-review comments

Use this register to draft a review comment or a finding that may become one.
Posting comments belongs to the requested review workflow.

- Open on the observation. Omit greetings, self-assessment, and your ranking of
  the change. Prefix a minor point with `Nit:` and keep it to a sentence when
  the observation fits.
- Write for the author as a peer. Keep a finding to a paragraph when the
  evidence fits, with a single question or requested correction per paragraph.
- Hedge the uncertain claim within its sentence, e.g. `I think` or `a bit`.
  A confidence marker such as `Take this with a grain of salt.` earns its
  place when the finding depends on physics, a datasheet, or code outside the
  diff. Omit statements about whether the comment is optional or blocking.
- Use second person when it is the clearest wording. Ask `Is that expected?`
  when the author's intent could settle an uncertainty. When the correction
  is established and concrete, use a `suggestion` fence.
- Use plain words and US spelling, e.g. `synchronized` and `energized`. State
  a risk in the first person and give its cause.
- A comment that depends on another names that relationship explicitly,
  since threads can be read out of order or collapsed.

Keep the comment focused on what the author needs to act. Include evidence
when the defect cannot be established from the attached code. Leave local
timings, diff statistics, and verification details for the chat response unless
they establish the finding. Quote the attached text only when the defect is
invisible in isolation, e.g. a missing word in a sentence.

Name the files that share a problem instead of enumerating every affected
line. Describe a recurring issue consistently, and prefer a representative
comment with a reusable correction when the same pattern spans the change.
Avoid appeals to conventions the author already knows and disclaimers about
the scope of an otherwise clear comment.

A preference without a concrete defect belongs in the chat discussion.
Review comments follow the shared rules for invariant prose, backticks, and
formatting.
