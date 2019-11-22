#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -a EMACS_SETTINGS_REMOTE="git@github.com:hartikainen/myemacs.git"
declare -a EMACS_SETTINGS_DIR="${HOME}/.emacs.d"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

clone_emacs_settings() {

    [ -d "${EMACS_SETTINGS_DIR}" ] || execute \
        "git clone ${EMACS_SETTINGS_REMOTE} ${EMACS_SETTINGS_DIR}"

    print_success "Emacs (clone settings)"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Emacs\n\n"

    "./$(get_os_name)/emacs.sh"

    printf "\n"

    clone_emacs_settings

}

main
