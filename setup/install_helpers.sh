#!/bin/bash
#
# Install-time helpers shared by `setup/dotfiles.sh` and `setup/setup.sh`.
# Not sourced at runtime by any shell — that's `setup/utils.sh`.
#
# Assumes `setup/utils.sh` has already been sourced (provides
# `print_*`, `execute`, `ask*`, `is_supported_version`, `get_os_name`,
# `get_os_version`, `cmd_exists`).

declare -r GITHUB_REPOSITORY="hartikainen/.dotfiles"

declare -r DOTFILES_ORIGIN="git@github.com:${GITHUB_REPOSITORY}.git"
declare -r DOTFILES_TARBALL_URL="https://github.com/${GITHUB_REPOSITORY}/tarball/main"
declare -r DOTFILES_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/main/setup"

# Default install directory. `download_dotfiles` may rewrite this (with
# user confirmation) and that is intentionally observable to the caller.
declare dotfilesDirectory="${HOME}/.dotfiles"
declare skipQuestions=false

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Download helpers
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

download() {

    local url="$1"
    local output="$2"

    if command -v "curl" &> /dev/null; then
        curl -LsSo "$output" "$url" &> /dev/null
        return $?
    elif command -v "wget" &> /dev/null; then
        wget -qO "$output" "$url" &> /dev/null
        return $?
    fi

    return 1

}

# Used by entry scripts when running via `curl | bash` and `utils.sh`
# isn't available locally yet.
download_utils() {

    local tmpFile
    tmpFile="$(mktemp /tmp/dotfiles_utils.XXXXX)"

    download "${DOTFILES_RAW_URL}/utils.sh" "$tmpFile" \
        && . "$tmpFile" \
        && rm -rf "$tmpFile" \
        && return 0

    return 1

}

download_dotfiles() {

    local tmpFile=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    print_in_purple "\n • Download and extract archive\n\n"

    tmpFile="$(mktemp /tmp/XXXXX)"

    download "$DOTFILES_TARBALL_URL" "$tmpFile"
    print_result $? "Download archive" "true"
    printf "\n"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ! $skipQuestions; then

        ask_for_confirmation "Do you want to store the dotfiles in '$dotfilesDirectory'?"

        if ! answer_is_yes; then
            dotfilesDirectory=""
            while [ -z "$dotfilesDirectory" ]; do
                ask "Please specify another location for the dotfiles (path): "
                dotfilesDirectory="$(get_answer)"
            done
        fi

        # Ensure the `dotfiles` directory is available.

        while [ -e "$dotfilesDirectory" ]; do
            ask_for_confirmation "'$dotfilesDirectory' already exists, do you want to overwrite it?"
            if answer_is_yes; then
                rm -rf "$dotfilesDirectory"
                break
            else
                dotfilesDirectory=""
                while [ -z "$dotfilesDirectory" ]; do
                    ask "Please specify another location for the dotfiles (path): "
                    dotfilesDirectory="$(get_answer)"
                done
            fi
        done

        printf "\n"

    else

        rm -rf "$dotfilesDirectory" &> /dev/null

    fi

    mkdir -p "$dotfilesDirectory"
    print_result $? "Create '$dotfilesDirectory'" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Extract archive into the `dotfiles` directory.

    extract "$tmpFile" "$dotfilesDirectory"
    print_result $? "Extract archive" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    rm -rf "$tmpFile"
    print_result $? "Remove archive"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    cd "$dotfilesDirectory/setup" \
        || return 1

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# OS gate
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

verify_os() {

    declare -r MINIMUM_MACOS_VERSION="12.6"
    declare -r MINIMUM_UBUNTU_VERSION="16.04"

    local os_name
    os_name="$(get_os_name)"
    local os_version
    os_version="$(get_os_version)"

    if [ "$os_name" = "macos" ]; then
        if is_supported_version "$os_version" "$MINIMUM_MACOS_VERSION"; then
            return 0
        fi
        printf "Sorry, this script is intended only for macOS %s+\n" "$MINIMUM_MACOS_VERSION"
    elif [ "$os_name" = "ubuntu" ]; then
        if is_supported_version "$os_version" "$MINIMUM_UBUNTU_VERSION"; then
            return 0
        fi
        printf "Sorry, this script is intended only for Ubuntu %s+\n" "$MINIMUM_UBUNTU_VERSION"
    elif [ "$os_name" = "debian" ]; then
        return 0
    else
        printf "Sorry, this script is intended only for macOS, Ubuntu, and Debian.\n"
    fi

    return 1

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# High-level orchestration
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Common preamble for entry scripts. Loads `utils.sh`, verifies the OS,
# parses `-y`, and — when running via `curl | bash` — downloads the
# tarball and `cd`s into its `setup/` dir so subsequent steps run from
# the unpacked repo.
#
# The single argument is the entry script's filename (e.g. "setup.sh"),
# which is used to detect the `curl | bash` case.
install_bootstrap() {

    local entryName="$1"
    shift

    if [ -x "utils.sh" ]; then
        . "./utils.sh" || return 1
    else
        download_utils || return 1
    fi

    verify_os || return 1

    skip_questions "$@" && skipQuestions=true

    if ! printf "%s" "${BASH_SOURCE[1]:-}" | grep -q "${entryName}"; then
        download_dotfiles || return 1
    fi

    return 0

}

# All the dotfile-only setup steps. No `sudo`, no package installs, no
# system preferences, no reboot. Safe to run on any machine. Both
# `dotfiles.sh` and `setup.sh` call this.
#
# Must be called from `${dotfilesDirectory}/setup` (which is where
# `install_bootstrap` leaves us).
do_dotfile_setup() {

    ./create_directories.sh

    ./create_symbolic_links.sh "$@"

    # Pick up XDG defaults so the rest of this script (and the install /
    # preferences scripts that may follow) see them. `~/.profile` is the
    # source of truth now; previously this hack sourced `~/.bashrc`.
    if [ -z "${XDG_CONFIG_HOME+x}" ] || [ -z "${XDG_DATA_HOME+x}" ]; then
        if [ -f "${HOME}/.profile" ]; then
            . "${HOME}/.profile"
        fi
    fi

    if [ -z "${XDG_CONFIG_HOME+x}" ] || [ -z "${XDG_DATA_HOME+x}" ]; then
        printf '\n%s\n' '$XDG_CONFIG_HOME and $XDG_DATA_HOME variables must be set for this setup script to function properly.'
        return 1
    fi

    export XDG_CONFIG_HOME XDG_DATA_HOME

    ./create_local_config_files.sh

    # `set_github_ssh_key.sh` is fundamentally interactive (prompts for
    # an email, opens a browser tab, waits for the user to add the key
    # on GitHub). Skip it under `-y` so CI / scripted re-runs don't
    # hang. Running interactively keeps the original behavior.
    if ! $skipQuestions; then
        ./set_github_ssh_key.sh
    fi

    if cmd_exists "git"; then

        if [ "$(git config --get remote.origin.url)" != "$DOTFILES_ORIGIN" ]; then
            ./initialize_git_repository.sh "$dotfilesDirectory" "$DOTFILES_ORIGIN"
        fi

        if ! $skipQuestions; then
            ./update_content.sh
        fi

    fi

}
