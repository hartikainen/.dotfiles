#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    ./xcode.sh
    ./homebrew.sh

    brew_bundle_install

    ./../oh_my_zsh.sh
    ./../emacs.sh

}

main
