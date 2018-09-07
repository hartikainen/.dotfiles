#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Image Tools\n\n"

    brew_install "GIMP" "lisanet-gimp" "caskroom/cask" "cask"
    brew_install "ImageMagick" "imagemagick --with-webp"

}

main
