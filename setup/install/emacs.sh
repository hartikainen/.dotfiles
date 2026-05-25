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

    if [ -e "$HOME/.emacs.d" ]; then
        echo "Found '$HOME/.emacs.d'. Moving it to '$HOME/.emacs.d.backup'"
        mv "$HOME/.emacs.d" "$HOME/.emacs.d.backup"
    fi

    if [ -e "$HOME/.emacs.el" ]; then
        echo "Found '$HOME/.emacs.el'. Moving it to '$HOME/.emacs.el.backup'"
        mv "$HOME/.emacs.el" "$HOME/.emacs.el.backup"
    fi

    if [ -e "$HOME/.emacs" ]; then
        echo "Found '$HOME/.emacs'. Moving it to '$HOME/.emacs.backup'"
        mv "$HOME/.emacs" "$HOME/.emacs.backup"
    fi

}

upgrade_doom_emacs() {

    execute "${DOOM_INSTALL_DIR}/bin/doom upgrade -! && true"
    execute "${DOOM_INSTALL_DIR}/bin/doom sync -! && true"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Doom Emacs\n\n"

    install_doom_emacs
    upgrade_doom_emacs

}

main
