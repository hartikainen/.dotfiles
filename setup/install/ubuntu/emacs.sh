#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main () {

    add_ppa "kelleyk/emacs"

    update

    execute "sudo apt remove --autoremove -y emacs emacs-common"
    install_package "Emacs 28" "emacs28-nativecomp"

}

main
