#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "../../utils.sh" &&
    . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    update
    # upgrade

    ./build-essentials.sh

    ./git.sh

    ./zsh.sh
    ./../oh_my_zsh.sh
    # ./fzf.sh

    # ./image_tools.sh
    # ./misc.sh
    ./misc_tools.sh
    ./yq.sh
    ./tmux.sh
    ./../tmux_plugins.sh
    # ./../emacs.sh

    # ./cleanup.sh

}

main
