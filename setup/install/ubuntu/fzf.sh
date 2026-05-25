#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "../../utils.sh" &&
    . "./utils.sh"

declare -r FZF_DIRECTORY="${XDG_CONFIG_HOME:=${HOME}/.config}/fzf"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_fzf() {

    execute "git clone \
                 --depth 1 \
                 https://github.com/junegunn/fzf.git \
                 ${FZF_DIRECTORY}" \
        "fzf (clone to ${FZF_DIRECTORY})"

    # Download the fzf binary only (no configuration files needed).
    fzf_configure_command="${FZF_DIRECTORY}/install --bin"

    execute "$fzf_configure_command" "fzf (install)"

}

update_fzf() {

    execute "cd ${FZF_DIRECTORY} && git pull" "fzf (git pull)"
    execute "${FZF_DIRECTORY}/install --bin" "fzf (install/update)"

}

main() {

    print_in_purple "\n   fzf\n\n"

    [ -d "${FZF_DIRECTORY}" ] || install_fzf

    update_fzf

}

main
