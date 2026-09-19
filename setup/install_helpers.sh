#!/bin/bash
#
# Install-time helpers shared by `setup/dotfiles.sh` and `setup/setup.sh`.
# Not sourced at runtime by any shell — that's `setup/utils.sh`.
#
# Assumes `setup/utils.sh` has already been sourced (provides
# `print_*`, `execute`, `ask*`, `is_supported_version`, `get_os_name`,
# `get_os_version`, `cmd_exists`).

GITHUB_REPOSITORY="hartikainen/.dotfiles"

DOTFILES_ORIGIN="git@github.com:${GITHUB_REPOSITORY}.git"
DOTFILES_TARBALL_URL="https://github.com/${GITHUB_REPOSITORY}/tarball/main"
DOTFILES_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/main/setup"

# Default install directory. `download_dotfiles` may rewrite this (with
# user confirmation) and that is intentionally observable to the caller.
dotfilesDirectory="${HOME}/.dotfiles"
skipQuestions=false

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Download helpers
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

download() {

    local url="$1"
    local output="$2"

    if command -v "curl" &>/dev/null; then
        curl -LsSo "$output" "$url" &>/dev/null
        return $?
    elif command -v "wget" &>/dev/null; then
        wget -qO "$output" "$url" &>/dev/null
        return $?
    fi

    return 1

}

# Used by entry scripts when running via `curl | bash` and `utils.sh`
# isn't available locally yet.
download_utils() {

    local tmpFile
    tmpFile="$(mktemp /tmp/dotfiles_utils.XXXXX)"

    # shellcheck source=utils.sh
    download "${DOTFILES_RAW_URL}/utils.sh" "$tmpFile" &&
        . "$tmpFile" &&
        rm -rf "$tmpFile" &&
        return 0

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

        rm -rf "$dotfilesDirectory" &>/dev/null

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

    cd "$dotfilesDirectory/setup" ||
        return 1

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

config_yq_usable() (

    set -o pipefail
    printf 'root = ["value"]\n[table]\nflag = true\n' |
        yq eval-all -p toml -o toml 'select(fileIndex == 0) * {"extra": true}' - |
        yq -e -p toml -o json \
            '(.root | length) == 1 and .root[0] == "value" and
                .table.flag == true and .extra == true' -

)

missing_config_dependencies() {

    cmd_exists jq || printf '%s\n' jq
    config_yq_usable >/dev/null 2>&1 || printf '%s\n' yq
    return 0

}

install_config_dependencies() {

    local dependency
    local needsYq=false
    local -a packages=()

    case "$(get_os_name)" in
        ubuntu | debian)
            for dependency in "$@"; do
                case "${dependency}" in
                    jq) packages+=(jq) ;;
                    yq) needsYq=true ;;
                esac
            done

            if $needsYq && ! cmd_exists curl && ! cmd_exists wget; then
                packages+=(curl)
            fi

            if [ "${#packages[@]}" -gt 0 ]; then
                sudo apt-get update || return 1
                sudo apt-get install -y "${packages[@]}" || return 1
            fi

            if $needsYq; then
                bash ./install/ubuntu/yq.sh || return 1
            fi
            ;;
        macos)
            if ! cmd_exists brew; then
                print_error 'Install Homebrew before installing `jq` and `yq`'
                return 1
            fi
            brew install "$@" || return 1
            ;;
        *)
            print_error 'No configuration dependency installer for this platform'
            return 1
            ;;
    esac

    hash -r

}

ensure_config_dependencies() {

    local installDependencies="$1"
    local dependency
    local -a missing=()
    while IFS= read -r dependency; do
        missing+=("${dependency}")
    done < <(missing_config_dependencies)

    [ "${#missing[@]}" -gt 0 ] || return 0

    print_warning "Missing or incompatible configuration dependencies: ${missing[*]}"
    if ! $installDependencies; then
        if $skipQuestions; then
            print_error 'Run `setup/dotfiles.sh` without `-y` to approve dependency installation'
            return 1
        fi
        ask_for_confirmation "Install ${missing[*]} using the platform installer (may require sudo)?"
        if ! answer_is_yes; then
            print_error 'Configuration dependencies are required; setup stopped'
            return 1
        fi
    fi

    install_config_dependencies "${missing[@]}" || return 1
    if [ -n "$(missing_config_dependencies)" ]; then
        print_error 'Required configuration dependencies are unavailable; check `PATH`'
        return 1
    fi

}

# The first argument authorizes dependency installation for the full bootstrap.
# Call from the `setup` directory prepared by `install_bootstrap`.
do_dotfile_setup() {

    ensure_config_dependencies "$1" || return 1
    shift

    ./create_directories.sh || return 1

    ./create_symbolic_links.sh "$@" || return 1

    # Pick up XDG defaults so the rest of this script (and the install /
    # preferences scripts that may follow) see them. `~/.profile` is the
    # source of truth now; previously this hack sourced `~/.bashrc`.
    if [ -z "${XDG_CONFIG_HOME+x}" ] || [ -z "${XDG_DATA_HOME+x}" ]; then
        if [ -f "${HOME}/.profile" ]; then
            . "${HOME}/.profile" || return 1
        fi
    fi

    if [ -z "${XDG_CONFIG_HOME+x}" ] || [ -z "${XDG_DATA_HOME+x}" ]; then
        printf '\n%s\n' '$XDG_CONFIG_HOME and $XDG_DATA_HOME variables must be set for this setup script to function properly.'
        return 1
    fi

    export XDG_CONFIG_HOME XDG_DATA_HOME

    ./create_local_config_files.sh "$@" || return 1

    ./cursor/cli_config.sh apply || return 1

    ./codex/config.sh apply || return 1

    # `set_github_ssh_key.sh` is fundamentally interactive (prompts for
    # an email, opens a browser tab, waits for the user to add the key
    # on GitHub). Skip it under `-y` so CI / scripted re-runs don't
    # hang. Running interactively keeps the original behavior.
    if ! $skipQuestions; then
        ./set_github_ssh_key.sh || return 1
    fi

    if cmd_exists "git"; then

        if [ "$(git config --get remote.origin.url)" != "$DOTFILES_ORIGIN" ]; then
            ./initialize_git_repository.sh "$dotfilesDirectory" "$DOTFILES_ORIGIN" || return 1
        fi

        if ! $skipQuestions; then
            ./update_content.sh || return 1
        fi

    fi

    return 0

}
