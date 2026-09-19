#!/bin/bash
#
# Dotfile-only entry point. Creates symlinks, writes local config files,
# initializes the git repo, and (optionally) sets up the GitHub SSH key.
#
# Prompts to install missing configuration dependencies. System preferences
# and the full package selection belong to `setup/setup.sh`.
#
# Run locally after cloning:
#     bash setup/dotfiles.sh [-y]
# Or remotely (downloads + unpacks the dotfiles first):
#     bash -c "$(curl -LsS https://raw.githubusercontent.com/hartikainen/.dotfiles/main/setup/dotfiles.sh)"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Self-bootstrap: load `install_helpers.sh` from disk or, when invoked
# via `curl | bash`, from raw.githubusercontent.com. We need a tiny
# inline downloader because we don't have any helpers yet.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare -r INSTALL_HELPERS_URL="https://raw.githubusercontent.com/hartikainen/.dotfiles/main/setup/install_helpers.sh"

_load_install_helpers() {

    local scriptDir
    scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)"

    if [ -n "$scriptDir" ] && [ -f "${scriptDir}/install_helpers.sh" ]; then
        cd "$scriptDir" || return 1
        # shellcheck source=./install_helpers.sh
        . "./install_helpers.sh"
        return $?
    fi

    local tmpFile
    tmpFile="$(mktemp /tmp/dotfiles_install_helpers.XXXXX)"

    if command -v curl >/dev/null; then
        curl -LsSo "$tmpFile" "$INSTALL_HELPERS_URL"
    elif command -v wget >/dev/null; then
        wget -qO "$tmpFile" "$INSTALL_HELPERS_URL"
    else
        printf "Need curl or wget to bootstrap.\n" >&2
        return 1
    fi || return 1

    # shellcheck source=/dev/null
    . "$tmpFile" || return 1
    rm -rf "$tmpFile"

}

main() {

    _load_install_helpers || exit 1

    install_bootstrap "dotfiles.sh" "$@" || exit 1

    do_dotfile_setup false "$@" || exit 1

}

main "$@"
