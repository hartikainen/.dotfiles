#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Image Tools\n\n"

    brew_install "GIMP" "gimp" "--cask"
    brew_install "ImageMagick" "imagemagick"

}

main
