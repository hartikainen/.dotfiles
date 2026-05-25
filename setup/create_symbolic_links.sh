#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Files symlinked directly into $HOME (not under ~/.config).
declare -r -a TOP_LEVEL_FILES=(
    ".bashrc"
    ".zshenv"
    ".Brewfile"
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

    # Per-file links for everything tracked under `.config/`. We prefer
    # `git ls-files` because it automatically:
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
    done < <(list_config_files "${dotfilesRoot}")

}

list_config_files() {

    local root="$1"

    if command -v git &> /dev/null \
        && git -C "${root}" rev-parse --is-inside-work-tree &> /dev/null; then
        git -C "${root}" ls-files -z --recurse-submodules -- '.config/**'
    else
        (cd "${root}" && find ".config" -type f -print0)
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n • Create symbolic links\n\n"

    create_symlinks "$@"

}

main "$@"
