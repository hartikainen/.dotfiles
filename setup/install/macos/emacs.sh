#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    brew_install \
        "Emacs >= 26" \
        "emacs" \
        "homebrew/cask" \
        "cask" \
        "--with-cocoa \
         --with-gnutls \
         --with-rsvg \
         --with-imagemagick"

}

main
