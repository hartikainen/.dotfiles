---
name: reviewing-pull-requests
description: >-
  Review GitHub pull requests in a dedicated git worktree and leave comments as
  a PENDING review that the user submits by hand. Use when asked to review a
  pull request, look over a PR, leave review comments, or check someone's
  changes on GitHub.
---

# Reviewing pull requests

Reviews are read locally and are never submitted. The user submits every review
themselves, so your job ends at a pending review plus a summary in chat. A
`beforeShellExecution` hook enforces this, and it will deny anything that
publishes, so following the workflow below is also the only way your commands
will run.

## Open a worktree for the review

Every review gets a worktree of its own, so reading a pull request never
disturbs what the user has checked out. Their branch stays put, their
uncommitted work stays where it is, and they keep working in the main checkout
while the review runs. A worktree shares the object store, so this costs a
checkout rather than a clone.

Work out which repository the pull request belongs to first, since one named by
URL may not be on disk at all. Clone a missing one into the layout its siblings
use, i.e. `gh repo clone [owner]/[repo] ~/Development/[owner]/[repo]/main`.
Then, from any checkout of that repository:

```sh
number=[number]
checkout=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
worktree="$(dirname "$checkout")/github/${number}"
git fetch origin "refs/pull/${number}/head"
git worktree add -b "github/${number}" "$worktree" FETCH_HEAD
cd "$worktree"
```

`--git-common-dir` names the main checkout's `.git` from anywhere in the
repository, including from another review's worktree, which is what keeps
review worktrees from nesting inside one another. `refs/pull/[number]/head`
resolves for a fork's pull request as readily as for a branch on the repository
itself, so it replaces `gh pr checkout`, which switches the branch of the
checkout you are standing in.

`github/[number]` matches the worktrees already on disk, e.g.
`~/Development/google-deepmind/xmanager/github/46`, and `git prune-merged` reaps
the branch once the merge lands on the local main branch. The derivation assumes
the checkout sits in a directory belonging to the repository, alongside its
sibling checkouts, so a repository cloned flat among unrelated ones takes
`[checkout].worktrees/github/[number]` instead.

Everything from here runs in the worktree, where `gh` resolves the pull request
from the remotes it shares with the main checkout.

An earlier review of the same pull request leaves its worktree behind, so `git
worktree add` refuses a path that is already taken. Remove the stale one and add
it again at the current head:

```sh
git worktree remove "$worktree"
git branch -D "github/${number}"
```

Never reach for `--force` there. `git worktree remove` refusing means the
directory holds modified or untracked files, i.e. work that is the user's rather
than yours, so say so and stop.

A worktree starts with tracked files only, i.e. no virtualenv, no build outputs,
and none of the gitignored local configuration, so anything you intend to run
has to be set up there first, and a build starts cold.

## Read the change locally

Fetch and read before writing anything. `gh pr view [number]` gives the
description and metadata, `gh pr diff [number]` gives the change itself, and
`gh pr checks [number]` shows CI state. Read the surrounding code in the
worktree rather than the diff in isolation, since it already stands at the pull
request's head.

A pull request is a change against its base, i.e. whatever branch it targets
rather than the repository's default branch, and `gh pr view [number] --json
baseRefName` names it. `gh pr diff` is base-relative already, but a local `git
diff` is not, so name the base and take the three-dot form:

```sh
base=$(gh pr view [number] --json baseRefName --jq '.baseRefName')
git fetch origin "$base"
git diff "origin/$base...HEAD"
```

Three dots diff against the merge base, which keeps commits that landed on the
base after the branch forked out of the change. Two dots hand you those commits
as though the author wrote them, which is how a review ends up questioning
someone else's work. Stacked pull requests are where this matters most: when the
base is itself a branch under review, everything the parent introduced belongs
to the parent's review, and a comment on it lands on the wrong pull request. The
same boundary bounds what you can comment on at all, since a thread has to
anchor to a line inside the diff.

Read what has already been said before adding to it. `gh pr view [number]
--comments` covers the timeline and the review verdicts, while the inline
threads sit behind their own endpoint:

```sh
gh api repos/[owner]/[repo]/pulls/[number]/comments \
    --jq '.[] | "\(.path):\(.line // .original_line) \(.user.login)\n\(.body)\n"'
```

Re-raising a point the author has already answered is worse than missing it
outright. Where their answer settles the question, cite it rather than asking
again, and check that an existing comment still applies before seconding it,
since bot reviews are usually written against an earlier push and the author may
have addressed them since. A thread whose `line` comes back null is outdated,
i.e. anchored to code the branch has moved out from under it, which is why the
recipe falls back to `original_line` and why an outdated thread deserves a look
at the current code before you echo it.

The comment responses are also the only record of what earlier revisions looked
like. A thread might give you information that the diff wouldn't. The user's own
comments get separate treatment under
[Leave comments as a pending review](#leave-comments-as-a-pending-review).

Delegate the bulk reading and keep the judgement. Judging a hunk usually means
reading well beyond it, i.e. the callers of a changed function, the other
implementations of an interface it touches, and the tests that already cover
it, and that is exactly what the `explore` subagent returns cheaply. Hand it
the paths and line ranges from the diff, and keep its reply as context for the
comments you write.

Read the diff and the threads yourself, though. A comment has to anchor to a
path and a line inside it, and a line number that has passed through another
context is how a comment lands on the wrong line. The `--jq` recipes above
already reduce the timeline to what you need, so relaying them through a
subagent buys nothing. The base resolution is yours for the same reason, since
the three-dot boundary decides which lines are yours to comment on at all, and
so is writing the comments, since the voice below depends on having read the
code each one is about.

Judge the change against the conventions the repository states for itself in
`AGENTS.md`, `CONTRIBUTING.md`, and anything under `.cursor/rules/`.

## Write the comment

Read `writing-as-hartikainen` and follow it for the voice, taking its
`github.md` register as the base. A review comment is a narrower register than
the issues and pull request descriptions that file is calibrated on, so it
overrides these points:

- No orienting opener. The comment starts on the observation.
- Prefix a minor point with `Nit:` and stop at the observation.
- Leave your own ranking of the change out. Whether a line is the most important
  one in the diff, or reads as belt-and-braces, is not an observation about the
  code.
- One paragraph is the ceiling for a nit and a single sentence is common, in
  place of the long multi-clause cadence. A finding that turns on evidence the
  author has to be shown may run longer, one ask per paragraph, so that no ask
  hides in the tail of another.
- Hedge inside the sentence (`I think`, `a bit`, `actually`), never as a
  sentence of its own. "Happy to be talked out of it", "two small things, both
  optional", and "not a blocker" are framing that masquerades as content. The
  one standalone line that earns its place is a confidence marker on a claim
  running on inference rather than on the diff, i.e. physics, datasheet
  reasoning, or behavior in code the diff never touches: `Take this with a grain
  of salt.` That tells the author how much weight to give the rest, where an
  optionality hedge only tells them you are nervous.
- Second person is fine and often shortest: `You're dropping timeout = "long"
  from here.`
- Ask rather than offer the fix. `Is that expected?` invites the reason you do
  not have, where `Could we carry it across?` assumes there was none. A recipe
  the author can reuse still earns its place, but a one-off proposal rarely
  does. The same holds for a diagnosis you cannot settle from the diff alone,
  e.g. that an ordering it changes was a live bug rather than a deliberate
  choice. Put it to them (`Was it a bug before?`) rather than asserting it and
  leaving them to accept it.
- Backtick identifiers, flags, paths, and values, but not bare quantities.
  Write `83 columns` and `78.6s`, not a backticked `83`. Identifiers stay
  backticked inside a quoted suggestion too, so the outer fence becomes double
  backticks: ``A mode switch resets `GOAL_PWM` to `PWM_LIMIT`.``
- Plain words over idiom, e.g. `synchronized` over `in lockstep`, `follow-ups`
  over `follow-ons`, and `Also,` over `Relatedly,`. US spelling throughout,
  e.g. `energized` rather than `energised`.
- Claim a risk in the first person, e.g. `I think this is an actual risk
  because ...`, rather than through a rhetorical contrast, e.g. `The risk feels
  concrete rather than hypothetical, because ...`.

Past the voice, the author knows this codebase. Write for a peer who will go
look, not for someone who needs the case proved to them.

Lead with the observation and stop. A second point becomes a question on its
own line rather than another paragraph: `Also, why move these?`, `Can you check
this?`, `Should we rename it too?`.

Reviews are read out of order and threads collapse, so a comment leaning on
another has to name it (`Related to the previous comment:`) rather than gesture
at "the same reasoning". Say `similar treatment` over `the same treatment` while
you are there, since the sibling fix is rarely identical.

Cut anything the author can see or run:

- Evidence you gathered to convince yourself. Local timings, column widths,
  diff statistics, and before-and-after counts belong in the chat summary.
- The text you are commenting on. The comment is anchored to the line. Quote
  only when the defect is invisible in isolation, e.g. a sentence you have to
  read whole to see the missing word.
- The pre-change version, which `git diff` already shows.
- Exhaustive citations. Name the files that share the problem and let the
  author grep, rather than listing every line number.
- Appeals to the repository's own conventions. The author has read
  `CONTRIBUTING.md`, so citing it turns a small observation into a charge.
- Scope disclaimers such as "to be clear, I only mean the prose", which defend
  against a misreading that will not happen.

Say a recurring issue once in your own words and reuse that wording verbatim at
the other sites (`Unnecessary line split here.`, then `Same unnecessary line
split here.`). Re-arguing it each time reads as padding.

Sweep every docstring and comment the change reflows before you stop looking.
One ragged paragraph in a rewrapped file usually means another, and the second
is the one you miss while writing up the first.

When a nit recurs across the whole change, stop enumerating and go after the
cause. Ask whether it belongs in the style guide or a lint rule, and hand the
author a recipe they can apply everywhere rather than a list of sites. One
comment that kills the class beats six that kill instances.

Reach for a `suggestion` fence whenever the change is concrete enough to write
out, since it applies in one click and replaces a paragraph of description.
Pair it with the general instruction when the pattern repeats ("please check
the other test files too").

Not every finding earns a comment. A broad "revert this choice across these
files" ask is a preference rather than a defect, and it will be cut. When you
cannot point at something that is wrong, put it in the chat summary instead.

## Leave comments as a pending review

GitHub decides whether a review is pending from one field. `POST
/repos/{owner}/{repo}/pulls/{n}/reviews` leaves the review in `PENDING` state
when `event` is absent, and submits it the moment `event` is set to `APPROVE`,
`REQUEST_CHANGES`, or `COMMENT`. Never pass `event`.

Never pass a top-level `body` either. The body is the review's verdict rather
than an observation about a line, it renders on the pull request page as soon as
the review exists, and it is what the user types into the submission dialog when
they decide the outcome. Writing it takes that decision out of their hands, so
leave it unset and let the inline `comments[]` be the only thing you create. The
summary goes in chat.

`gh pr review` has no pending mode, so `gh api` is the only route:

```sh
gh api --method POST repos/[owner]/[repo]/pulls/[number]/reviews \
    -F 'comments[][path]=src/simulation/jax/forward.py' \
    -F 'comments[][line]=42' \
    -F 'comments[][side]=RIGHT' \
    -F 'comments[][body]=This mutates `data` in place, which the caller does not expect.'
```

Keep every `comments[]` field on one flag, as above. `gh` collects `-f` and `-F`
into two separate lists and walks them one after the other, so interleaving the
two scrambles the array into objects that are each missing whatever the other
pass held, and the request comes back as a `422` reporting null `path` and
`body` values. `-F` serves both, since it coerces `line` to an integer and
leaves prose alone. A payload piped through `--input -` is invisible to the
guard, which has to deny it rather than assume `event` is absent.

Two constraints follow from the API. GitHub allows only one pending review per
user per pull request, so gather every comment first and create the review once.
REST has no endpoint for appending to a pending review either, i.e. inline
comments have to travel in the `comments[]` array at creation time, which leaves
GraphQL as the only way in once a review exists.

Check for an existing pending review before you write anything, since the user
may have started one by hand. Append to it rather than working around it, read
what is already there, and drop your own version of anything they have covered.
Their phrasing for a given class of issue is the phrasing to reuse at the other
sites. Never delete a pending review to make room for yours, since the comments
in it are theirs.

The create call answers `422 User can only have one pending review per pull
request` when one exists, so look first and take its `node_id` if it does:

```sh
gh api repos/[owner]/[repo]/pulls/[number]/reviews \
    --jq '.[] | select(.state == "PENDING") | {id, node_id}'
```

`addPullRequestReviewThread` then appends one comment per call against that id,
leaving the review pending because submission is a separate mutation:

```sh
gh api graphql \
    -f query='mutation($r:ID!,$p:String!,$l:Int!,$b:String!){addPullRequestReviewThread(input:{pullRequestReviewId:$r,path:$p,line:$l,side:RIGHT,body:$b}){thread{id}}}' \
    -f r='PRR_...' \
    -f p='src/simulation/jax/forward.py' \
    -F l=42 \
    -f b=$'This mutates `data` in place, which the caller does not expect.'
```

Comment bodies are backtick-heavy prose carrying apostrophes and blank lines,
which rules out plain single quotes (an apostrophe closes the string) and double
quotes (backticks and `$` expand). Reach for zsh ANSI-C quoting, `-f b=$'...'`,
where `\'` is a literal apostrophe and `\n` a newline while nothing else
expands.

## Never do these

Each of these publishes immediately and is denied by the hook:

- `gh pr review` in any form, including `--approve`, `--request-changes`, and `--comment`.
- `gh pr comment`, which posts to the timeline.
- `POST /pulls/{n}/reviews/{id}/events`, which submits a pending review.
- `POST /pulls/{n}/comments` and `POST /pulls/comments/{id}/replies`, which have no pending mode.
- `POST /issues/{n}/comments`.
- The GraphQL `submitPullRequestReview` mutation, or `addPullRequestReview` with an `event` argument.
- `gh pr merge` and `gh pr close`.

## Report back

Close with the summary in chat, not on GitHub: what you found, grouped by
severity, and whether you would approve. The review itself carries the inline
comments and nothing else, so chat is the only place the overall verdict
appears until the user writes their own. This is also where the evidence you
kept out of the comments goes, i.e. the timings you measured, the tests you
ran, and the equivalences you checked. It justifies the review to the user
without weighing down what the author reads. Confirm the review still reads
`"state": "PENDING"` and that every comment anchored to the line you meant, then
say plainly that the review is pending and waiting for the user to submit it.
Name the worktree you left behind and the command that drops it, i.e. `git
worktree remove [path]`, so the user can walk the code while they decide and
clean up when they are done. When you appended to a review of theirs, say so
and confirm their comments survived. Omit praise and nits that change nothing
for either the reader or the runtime.

```sh
gh api graphql -f query='query{repository(owner:"[owner]",name:"[repo]"){pullRequest(number:[number]){reviews(last:1,states:PENDING){nodes{state comments(first:30){nodes{path line}}}}}}}'
```
