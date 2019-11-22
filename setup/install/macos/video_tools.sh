#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Video Tools\n\n"

    brew_install "ffmpeg" "ffmpeg"
    brew_install "youtube-dl" "youtube-dl"

}

main
