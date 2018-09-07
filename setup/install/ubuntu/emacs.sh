#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main () {

    add_ppa "kelleyk/emacs"

    update

    install_package "Emacs 26" "emacs26"

}

main
