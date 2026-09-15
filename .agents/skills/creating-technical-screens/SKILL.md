---
name: creating-technical-screens
description: >-
  Build a candidate-specific technical screen from a prompt and resume in the
  user's screen repository, with an interviewer document and runnable code.
---

# Creating technical screens

A screen is one interviewer document plus the runnable code it refers to, built
for a single candidate out of the prompt and their resume. The screens already
in the repository are the specification, so most of this is imitation, and the
two decisions that are not yours to make are gated below, i.e. the format
before anything is written and the document before any code is.

Start from a checkout of the repository that holds the screens. If the request
arrives from somewhere else, and which repository is meant is not obvious, ask
rather than guess.

## Open a worktree for the candidate

Each candidate gets a worktree of their own, cut from `origin/main`, so drafting
never disturbs what is checked out anywhere else. The branch is
`kristian/technical-screen/[candidate-slug]`, i.e. the candidate's name
lowercased with hyphens for spaces, and the worktree path mirrors the branch
under the directory that holds the repository's checkouts:

```sh
slug=[candidate-slug]
checkout=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
branch="kristian/technical-screen/${slug}"
worktree="$(dirname "$checkout")/${branch}"
git fetch origin main
git worktree add -b "$branch" "$worktree" origin/main
cd "$worktree"
```

`--git-common-dir` resolves the main checkout from anywhere in the repository,
including from another candidate's worktree, so the derivation holds wherever
you happen to start. One worktree covers everything for that candidate, so a
second exercise for the same person is another topic directory inside it rather
than a second worktree.

## Find the library and read the closest screen

The screens are not on `main`. Each one lives on the branch that introduced it,
so list the namespace and read from there:

```sh
for ref in $(git for-each-ref --format='%(refname:short)' \
        refs/heads/kristian/interviews \
        'refs/heads/kristian/technical-screen/*'); do
    git ls-tree -r --name-only "$ref" \
        | rg '/technical-screen\.md$' \
        | sed "s|^|${ref}:|"
done
```

Every hit is a `[branch]:[path]` pair that `git show` takes directly, and the
path gives you the layout, i.e. an interviews root, then a track, then a topic
that joins the library to the domain with a `+`. Read the whole of the screen
closest to what the prompt asks for, along with its code files, before drafting
anything. Those carry the section skeleton, the rubric tags, the register, and
the level of detail, none of which is worth restating here and all of which
moves as the library grows.

Copy the resume into the worktree, into a `resumes/` directory beside the
tracks, named for the slug. It has to stay out of git, which the repository's
own exclude file handles rather than a `.gitignore` a colleague would see:

```sh
root=[interviews-root]
mkdir -p "${root}/resumes"
cp [resume] "${root}/resumes/${slug}.pdf"
exclude="$(git rev-parse --path-format=absolute --git-common-dir)/info/exclude"
pattern="/${root}/resumes/"
grep -qxF "$pattern" "$exclude" || echo "$pattern" >> "$exclude"
git check-ignore -v "${root}/resumes/${slug}.pdf"
```

That exclude file is shared by every worktree of the repository and is itself
never committed, so the line goes in once and covers every screen after it.
Anchoring the pattern with a leading slash is what keeps it from matching a
`resumes/` directory elsewhere in the tree, and a per-worktree exclude is not an
option, since git reads this file only from the common directory. `check-ignore`
naming the rule confirms it, and `git status` coming back clean with the resume
in place is the check that actually matters. The candidate's name reaching git
through the branch and the document is expected. The resume itself never does.

## Ask which format to use

Stop and ask before writing anything. The library already holds several formats
and the reference screens name them, so put the ones that are plausible for this
candidate to the user, each with what it buys and what it fails to measure, and
let them choose. A resume on its own rarely settles it, and the prompt usually
says what to probe rather than how.

## Draft the document, then wait

Write `technical-screen.md` on its own and hand it over before writing a line of
code. It is the artifact the user actually reviews, the code follows from it
almost mechanically, and an exercise that is wrong for the candidate is far
cheaper to fix in prose than in three files and a test suite.

Read `writing-as-hartikainen` and its repository Markdown register. Explain why
the exercise suits the candidate, what it cannot establish, and which follow-up
would distinguish ambiguous answers. Use first-person, invariant prose and
plain rubric labels.

Ground every tailored claim in the resume, and quote it rather than paraphrase
where the exercise leans on it. Building an exercise around a strength the
candidate never actually claimed is the failure mode here, and it is invisible
once the document reads fluently.

## Write the code files, then prove they work

Take the file names from the reference screen exactly. Between them the files
divide into what the candidate sees, an interviewer copy annotated against the
rubric, a reference solution, and runnable checks, and the reference screen's
docstrings say which is which and which of them are never shared. Dependencies
are declared inline with PEP 723 and pinned, so every file runs under `uv run`
with nothing installed beforehand.

Then check the exercise rather than assume it:

```sh
uv run technical-screen-code-tests.py [reference-solution]
uv run technical-screen-code-tests.py
```

The reference has to pass everything, and the candidate starter has to fail in
the order the exercise intends, so that the first failure is the first thing you
want them to reach for. A starter that passes, or one that fails in the wrong
order, is a broken exercise however well the document reads. Fix it and run both
again.

## Commit and report back

Commit on the branch and stop there. Pushing is the user's call, and a screen
usually changes once more between drafting and the call.

Close in chat with the worktree path, the branch, the topic directory, and the
verification output, i.e. which checks the reference passed and where the
starter failed first. Say plainly what the screen does not measure, since that
is the part the user has to weigh against the rest of the loop. The debrief
written after the call belongs beside the exercise, named for the slug.
