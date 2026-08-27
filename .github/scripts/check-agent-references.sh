#!/bin/bash
#
# Verify that every path named inside an agent rule, skill, or subagent
# definition resolves in this repository.
#
# The agent config layer points at files by path, both in prose (`read
# $HOME/.../SKILL.md`) and in JSON (`hooks.json` command entries). Nothing
# else checks those references. When a tracked file moves, the pointers stay
# behind, the agent's read fails, and it drafts from memory instead — which is
# the one outcome the instruction exists to prevent. The failure is silent at
# every layer below this check.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
declare -r repoRoot="$PWD"

# Directories holding agent configuration. `agent.md` is a file rather than a
# directory, and `grep -r` accepts both.
declare -r -a SCANNED=(
    ".agents"
    ".cursor"
    ".codex"
    "agent.md"
)

status=0

report() {
    printf '%s:%s: %s\n' "$1" "$2" "$3" >&2
    status=1
}

present_paths() {

    local path

    for path in "${SCANNED[@]}"; do
        [ -e "${repoRoot}/${path}" ] && printf '%s\n' "${path}"
    done

    return 0

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# `$HOME/...` references. This repo mirrors `$HOME`, so every such path has a
# counterpart at the same relative path here. The character class stops at the
# escaped quotes that wrap the commands in `.codex/hooks.json`.

check_home_references() {

    local -a paths=("$@")
    local match file line ref rel

    while IFS= read -r match; do

        file="${match%%:*}"
        match="${match#*:}"
        line="${match%%:*}"
        ref="${match#*:}"

        rel="${ref#\$HOME/}"

        [ -e "${repoRoot}/${rel}" ] ||
            report "${file}" "${line}" "\$HOME reference does not resolve: ${ref}"

    done < <(grep -rnoE '\$HOME/[A-Za-z0-9._/-]+' "${paths[@]}" 2>/dev/null)

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Relative Markdown links, i.e. the register files a skill routes to. These
# resolve against the directory holding the linking file, not the repo root.

check_relative_links() {

    local -a paths=("$@")
    local match file line target

    while IFS= read -r match; do

        file="${match%%:*}"
        match="${match#*:}"
        line="${match%%:*}"
        target="${match#*:}"

        # Strip the surrounding `](` and `)`, then any `#anchor` fragment.
        target="${target#](}"
        target="${target%)}"
        target="${target%%#*}"

        case "${target}" in
            "" | http*://* | mailto:* | \#*) continue ;;
        esac

        [ -e "$(dirname "${repoRoot}/${file}")/${target}" ] ||
            report "${file}" "${line}" "link does not resolve: ${target}"

    done < <(grep -rnoE '\]\([^)]+\)' \
        --include='*.md' \
        --include='*.mdc' \
        "${paths[@]}" 2>/dev/null)

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    # `mapfile` is bash 4, and macOS ships bash 3.2.
    local -a paths=()
    local path
    while IFS= read -r path; do
        paths+=("${path}")
    done < <(present_paths)

    [ "${#paths[@]}" -gt 0 ] || return 0

    check_home_references "${paths[@]}"
    check_relative_links "${paths[@]}"

    [ "${status}" -eq 0 ] &&
        printf 'All agent references resolve.\n'

    return "${status}"

}

main "$@"
