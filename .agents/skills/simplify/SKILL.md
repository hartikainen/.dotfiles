---
name: simplify
description: Simplify code while preserving required behavior. Use when asked to simplify or clean up code, or for the final cleanup pass on substantial code changes.
---

# Simplify code

Make one focused pass that improves clarity and removes unnecessary complexity. Leaving the code unchanged is a valid result.

## Establish scope

Use the caller's target files or diff. During an implementation task, default to that task's changes. Inspect the working tree and applicable repository instructions before editing. Preserve unrelated staged and unstaged work. Ask for a target when the scope is ambiguous. A request for review or suggestions alone does not authorize edits.

Read the changed code, relevant callers, and existing checks to identify the behavior and contracts that must remain intact. Look for established helpers and patterns near the affected code.

## Simplify

- Remove redundant branches, intermediate state, and wrappers that add no useful boundary.
- Reuse existing helpers when their semantics match. Keep separate concepts separate even when their code looks similar.
- Remove abstractions, configuration, dependencies, and fallback paths introduced for hypothetical requirements when the current requirements do not need them.
- Prefer clear names and readable control flow. Do not trade clarity for fewer lines or speculative performance gains.

Preserve required validation, error handling, security checks, public interfaces, side effects, and compatibility. Treat uncertain behavior as a reason to investigate or leave it intact. Keep unrelated refactors and behavior changes outside the cleanup. Follow the repository's delegation policy if a separate reviewer is warranted.

## Verify and finish

Inspect the resulting diff for scope and behavior changes. Run the relevant checks after edits, and correct regressions caused by the cleanup. Do not weaken tests to accommodate a behavior change. Stop after one pass unless a concrete finding requires a correction.

Follow the caller's commit and publication rules. Briefly report what became simpler, what was verified, and any unresolved concern. If no change improves clarity, say so without manufacturing an edit.
