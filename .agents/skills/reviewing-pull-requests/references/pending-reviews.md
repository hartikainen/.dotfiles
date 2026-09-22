# Pending review API

Use these commands for the pending review workflow in [`SKILL.md`](../SKILL.md). Keep that skill's publication boundaries throughout.

## Inspect an existing review

Look for a pending review before drafting comments:

```sh
gh api repos/[owner]/[repo]/pulls/[number]/reviews \
    --jq '.[] | select(.state == "PENDING") | {id, node_id}'
```

The inventory returns identifiers only. Use the review's `id` or `node_id` to read its comment bodies, authors, paths, and line anchors, including every page, before drafting. Use its `node_id` when appending.

GitHub rejects creation while the user has a pending review on the pull request. Gather comments before creating a review, since REST creation accepts inline comments in `comments[]` and appending to an existing pending review uses GraphQL.

## Create a pending review

Use `gh api` with each `comments[]` field exposed as a command argument:

```sh
gh api --method POST repos/[owner]/[repo]/pulls/[number]/reviews \
    -F 'comments[][path]=src/simulation/jax/forward.py' \
    -F 'comments[][line]=42' \
    -F 'comments[][side]=RIGHT' \
    -F 'comments[][body]=This mutates `data` in place, which the caller does not expect.'
```

Use `-F` for every `comments[]` field. `gh` collects `-f` and `-F` into separate lists, so mixing them splits the array into incomplete comment objects. `-F` coerces `line` to an integer and leaves prose alone.

Keep the payload in command arguments. The hooks cannot inspect a payload piped through `--input -`, so they deny that form.

## Append to a pending review

`addPullRequestReviewThread` appends a comment against the review's `node_id`. Submission is a separate mutation.

```sh
gh api graphql \
    -f query='mutation($r:ID!,$p:String!,$l:Int!,$b:String!){addPullRequestReviewThread(input:{pullRequestReviewId:$r,path:$p,line:$l,side:RIGHT,body:$b}){thread{id}}}' \
    -f r='PRR_...' \
    -f p='src/simulation/jax/forward.py' \
    -F l=42 \
    -f b=$'This mutates `data` in place, which the caller does not expect.'
```

For bodies containing apostrophes or blank lines, use zsh ANSI-C quoting, `-f b=$'...'`. Within that form, `\'` is a literal apostrophe and `\n` is a newline, while backticks and `$` do not expand. Double quotes permit command and parameter expansion.

## Verify the result

Confirm the review remains `PENDING`, every added comment anchors to the intended line, and the user's existing comments survived:

```sh
gh api graphql -f query='query{repository(owner:"[owner]",name:"[repo]"){pullRequest(number:[number]){reviews(last:1,states:PENDING){nodes{state comments(first:30){nodes{path line}}}}}}}'
```

Page through the comment connection when the response does not cover every comment. Report the result in chat for the user to review and submit.
