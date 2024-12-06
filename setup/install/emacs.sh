#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r DOOM_INSTALL_DIR="${XDG_CONFIG_HOME}/emacs"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_doom_emacs() {

    if [ ! -f "${DOOM_INSTALL_DIR}/bin/doom" ]; then
        execute \
            "git clone --depth 1 https://github.com/doomemacs/doomemacs ${DOOM_INSTALL_DIR}" \
            "Emacs (clone doom)"
        execute "bash -i -c '${DOOM_INSTALL_DIR}/bin/doom install -! && true'"
    else
        print_success "Skip doom install (already installed)"
    fi

}

upgrade_doom_emacs() {

    execute "bash -i -c '${DOOM_INSTALL_DIR}/bin/doom upgrade && true'"
    execute "bash -i -c '${DOOM_INSTALL_DIR}/bin/doom sync && true'"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Emacs\n\n"

    "./$(get_os_name)/emacs.sh"

    print_in_purple "\n   Doom Emacs\n\n"

    install_doom_emacs
    upgrade_doom_emacs

}

main
