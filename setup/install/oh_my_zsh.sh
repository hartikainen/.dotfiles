#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r OH_MY_ZSH_DIRECTORY="${HOME}/.oh-my-zsh"
declare -r OH_MY_ZSH_LATEST_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


install_oh_my_zsh() {

    tmp_file="$(mktemp /tmp/XXXXX)"

    download "${OH_MY_ZSH_LATEST_URL}" "${tmp_file}"
    execute "RUNZSH=no ZSH=${OH_MY_ZSH_DIRECTORY} sh ${tmp_file}" \
            "oh-my-zsh (install)"

}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   oh-my-zsh\n\n"

    [ -d "${OH_MY_ZSH_DIRECTORY}" ] || install_oh_my_zsh

    # This should be defined by oh-my-zsh
    zsh -c upgrade_oh_my_zsh

}

main
