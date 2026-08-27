#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Files symlinked directly into $HOME (not under ~/.config). These have
# to live at the top of $HOME because the corresponding tool (bash, zsh,
# brew bundle) only looks for them there.
declare -r -a TOP_LEVEL_FILES=(
    ".profile"
    ".bash_profile"
    ".bashrc"
    ".bash_logout"
    ".zshenv"
    ".Brewfile"
)

# Directories whose tracked contents are linked file-by-file into the
# corresponding path under $HOME. `.cursor` holds Cursor's user-level
# subagents and skills, and `.codex` holds the portable part of Codex's
# user-level configuration. Runtime state under `~/.codex` stays untracked and
# untouched.
#
# Note that this repo mirrors $HOME, so its own `.cursor/`, `.agents/`, and
# `.codex/` directories double as project config whenever the dotfiles are
# open in the corresponding agent. Each tracked file may then be loaded once
# from the user layer and once from the project layer. Paths inside hooks have
# to resolve in both contexts, so their commands use `$HOME`.
declare -r -a LINKED_DIRECTORIES=(
    ".config"
    ".cursor"
    ".codex"
)

# Codex follows symlinked skill directories, while a real skill directory
# containing a symlinked `SKILL.md` is not discovered. Link each tracked skill
# as a directory so its entry point and supporting files stay together.
declare -r -a LINKED_CHILD_DIRECTORIES=(
    ".agents/skills"
)

# Roots swept for links left behind by a tracked file that moved. `link_file`
# only ever visits paths the manifest names, so nothing removes a link whose
# source is gone. CI never sees these because it starts from an empty `$HOME`
# and links every path fresh; they accumulate only in a `$HOME` that has been
# through more than one revision of the tree.
declare -r -a PRUNED_ROOTS=(
    ".config"
    ".cursor"
    ".codex"
    ".agents"
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

link_file() {

    local sourceFile="$1"
    local targetFile="$2"
    local skipQuestions="$3"

    local targetDir
    targetDir="$(dirname "${targetFile}")"
    [ -d "${targetDir}" ] || mkdir -p "${targetDir}"

    if [ ! -e "${targetFile}" ] && [ ! -L "${targetFile}" ]; then

        execute \
            "ln -sfn \"${sourceFile}\" \"${targetFile}\"" \
            "${targetFile} → ${sourceFile}"

    elif [ -L "${targetFile}" ] && [ "$(readlink "${targetFile}")" = "${sourceFile}" ]; then

        print_success "${targetFile} → ${sourceFile}"

    elif $skipQuestions; then

        rm -rf "${targetFile}"
        execute \
            "ln -sfn \"${sourceFile}\" \"${targetFile}\"" \
            "${targetFile} → ${sourceFile}"

    else

        ask_for_confirmation "'${targetFile}' already exists, do you want to overwrite it?"
        if answer_is_yes; then
            rm -rf "${targetFile}"
            execute \
                "ln -sfn \"${sourceFile}\" \"${targetFile}\"" \
                "${targetFile} → ${sourceFile}"
        else
            print_error "${targetFile} → ${sourceFile}"
        fi

    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Migrate from the legacy whole-directory `~/.config` symlink to a real
# directory containing per-file symlinks. If `~/.config` is currently a
# symlink (regardless of where it points), remove it so we can populate
# it with individual file symlinks below. Any non-tracked files that
# previously lived under the symlink target are left untouched in the
# repo — the user can move them out manually if desired.

migrate_config_symlink() {

    local configDir="${HOME}/.config"

    if [ -L "${configDir}" ]; then
        local linkTarget
        linkTarget="$(readlink "${configDir}")"
        print_warning "Removing legacy ~/.config symlink (was → ${linkTarget})"
        rm -f "${configDir}"
    fi

    [ -d "${configDir}" ] || mkdir -p "${configDir}"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Remove symlinks under the managed roots that point into this repository but
# no longer resolve. Only broken links are touched, and only those aimed at
# `${dotfilesRoot}`, so a dangling link into any other tree is left alone.

prune_orphaned_symlinks() {

    local dotfilesRoot="$1"

    local -a roots=()
    local dir
    for dir in "${PRUNED_ROOTS[@]}"; do
        [ -d "${HOME}/${dir}" ] && roots+=("${HOME}/${dir}")
    done

    # Collect first and delete afterwards, so the tree stays intact while
    # `find` is still walking it.
    local -a orphans=()
    local link target

    while IFS= read -r link; do

        target="$(readlink "${link}")" || continue

        case "${target}" in
            "${dotfilesRoot}"/*) ;;
            *) continue ;;
        esac

        # `-e` follows the link, so it is false exactly when the source is gone.
        [ -e "${link}" ] && continue

        orphans+=("${link}")

    done < <(
        find "${HOME}" -maxdepth 1 -type l
        [ "${#roots[@]}" -gt 0 ] && find "${roots[@]}" -type l
    )

    [ "${#orphans[@]}" -gt 0 ] || return 0

    for link in "${orphans[@]}"; do
        target="$(readlink "${link}")"
        rm -f "${link}"
        print_warning "Removed orphaned link ${link} → ${target}"
        prune_empty_parents "$(dirname "${link}")"
    done

}

# Walk up from a directory that just lost an orphan, dropping the levels that
# the removal emptied. `rmdir` refuses a directory holding anything else, so a
# level with unrelated content stops the walk on its own.

prune_empty_parents() {

    local dir="$1"

    while [ "${dir}" != "${HOME}" ] && [ "${dir}" != "/" ]; do
        rmdir "${dir}" 2>/dev/null || break
        print_warning "Removed empty directory ${dir}"
        dir="$(dirname "${dir}")"
    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

create_symlinks() {

    local skipQuestions=false
    skip_questions "$@" && skipQuestions=true

    local dotfilesRoot
    dotfilesRoot="$(cd .. && pwd)"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    migrate_config_symlink

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Top-level files (linked directly into $HOME).

    local name
    for name in "${TOP_LEVEL_FILES[@]}"; do
        link_file \
            "${dotfilesRoot}/${name}" \
            "${HOME}/${name}" \
            "${skipQuestions}"
    done

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Per-file links for everything tracked under `LINKED_DIRECTORIES`. We
    # prefer `git ls-files` because it automatically:
    #   - excludes gitignored files (e.g. `.config/zsh/local`,
    #     `.config/git/config.local`, `.zcompdump*`),
    #   - includes submodule contents (e.g. `.config/doom/**`),
    #   - picks up newly-added tracked files on the next setup run.
    # Falls back to `find` for the tarball install path, where the
    # checkout isn't a git working tree yet (only tracked files are
    # present in the tarball, so no exclusions are necessary).

    local rel
    while IFS= read -r -d '' rel; do
        link_file \
            "${dotfilesRoot}/${rel}" \
            "${HOME}/${rel}" \
            "${skipQuestions}"
    done < <(list_linked_files "${dotfilesRoot}")

    # Directory links for structures that Codex discovers as units.

    while IFS= read -r rel; do
        link_file \
            "${dotfilesRoot}/${rel}" \
            "${HOME}/${rel}" \
            "${skipQuestions}"
    done < <(list_linked_child_directories "${dotfilesRoot}")

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # After linking, so a path the manifest still names has already been
    # recreated and is no longer a candidate.

    prune_orphaned_symlinks "${dotfilesRoot}"

}

list_linked_files() {

    local root="$1"

    local -a pathspecs=()
    local dir
    for dir in "${LINKED_DIRECTORIES[@]}"; do
        pathspecs+=("${dir}/**")
    done

    if command -v git &>/dev/null &&
        git -C "${root}" rev-parse --is-inside-work-tree &>/dev/null; then
        git -C "${root}" ls-files -z --recurse-submodules -- "${pathspecs[@]}"
    else
        # Only pass directories that exist, so a checkout missing one of
        # them doesn't turn into a `find` error.
        local -a presentDirs=()
        for dir in "${LINKED_DIRECTORIES[@]}"; do
            [ -d "${root}/${dir}" ] && presentDirs+=("${dir}")
        done
        [ "${#presentDirs[@]}" -gt 0 ] || return 0
        (cd "${root}" && find "${presentDirs[@]}" -type f -print0)
    fi

}

list_linked_child_directories() {

    local root="$1"
    local linkedRoot

    for linkedRoot in "${LINKED_CHILD_DIRECTORIES[@]}"; do
        if command -v git &>/dev/null &&
            git -C "${root}" rev-parse --is-inside-work-tree &>/dev/null; then
            git -C "${root}" ls-files -- "${linkedRoot}/**" |
                while IFS= read -r rel; do
                    local child="${rel#"${linkedRoot}/"}"
                    child="${child%%/*}"
                    [ -n "${child}" ] && printf "%s/%s\n" "${linkedRoot}" "${child}"
                done |
                sort -u
        elif [ -d "${root}/${linkedRoot}" ]; then
            local sourceDir
            for sourceDir in "${root}/${linkedRoot}"/*; do
                [ -d "${sourceDir}" ] || continue
                printf "%s\n" "${sourceDir#"${root}/"}"
            done
        fi
    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n • Create symbolic links\n\n"

    create_symlinks "$@"

}

main "$@"
