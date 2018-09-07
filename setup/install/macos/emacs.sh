#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    brew_install "Emacs" "brew install emacs --with-cocoa --with-gnutls --with-rsvg --with-imagemagick"

}

main
