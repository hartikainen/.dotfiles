#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


main() {

    print_in_purple "\n   Image Tools\n\n"

    install_package "GIMP" "gimp"
    install_package "ImageMagick" "imagemagick"

}

main
