#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    update
    upgrade

    ./build-essentials.sh

    ./git.sh

    ./zsh.sh
    ./../oh_my_zsh.sh

    ./../conda.sh

    ./browsers.sh
    ./image_tools.sh
    ./misc.sh
    ./misc_tools.sh
    ./tmux.sh
    ./../emacs.sh

    ./cleanup.sh

}

main
