#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    ./xcode.sh
    ./homebrew.sh
    ./iterm2.sh
    ./bash.sh

    ./../conda.sh

    ./browsers.sh
    ./git.sh
    ./gpg.sh
    ./image_tools.sh
    ./misc.sh
    ./misc_tools.sh
    ./tmux.sh
    ./../emacs.sh

    ./cleanup.sh

}

main
