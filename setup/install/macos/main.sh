#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    ./xcode.sh
    ./homebrew.sh
    ./bash.sh
    ./git.sh

    ./iterm2.sh

    ./zsh.sh
    ./../oh_my_zsh.sh

    ./../conda.sh

    ./browsers.sh
    ./gpg.sh
    ./image_tools.sh
    ./video_tools.sh
    ./misc.sh
    ./misc_tools.sh
    ./tmux.sh
    ./../emacs.sh

    ./cleanup.sh

}

main
