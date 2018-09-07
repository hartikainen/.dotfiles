#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    update
    upgrade

    ./build-essentials.sh

    ./../conda.sh

    ./browsers.sh
    ./git.sh
    ./image_tools.sh
    ./misc.sh
    ./misc_tools.sh
    ./tmux.sh
    ./../emacs.sh

    ./cleanup.sh

}

main
