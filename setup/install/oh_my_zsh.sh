#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

if [ -z ${XDG_DATA_HOME+x} ]; then
    echo "$(basename -- "${BASH_SOURCE[0]}"):
The \$XDG_DATA_HOME variable must be set for this setup script to function
properly."
    exit 1
fi

declare -r OH_MY_ZSH_DIRECTORY="${XDG_DATA_HOME}/oh-my-zsh"
declare -r OH_MY_ZSH_LATEST_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


install_oh_my_zsh() {

    if [ -z ${XDG_CONFIG_HOME+x} ]; then
        echo "
$(basename -- "${BASH_SOURCE[0]}"):
The \$XDG_CONFIG_HOME variable must be set for this setup script to function
properly."
        exit 1
    fi

    tmp_file="$(mktemp /tmp/XXXXX)"

    download "${OH_MY_ZSH_LATEST_URL}" "${tmp_file}"

    ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
    local omz_options=""
    omz_options=$(printf 'RUNZSH=no KEEP_ZSHRC=yes ZSH=%s ZDOTDIR=%s' \
        "${OH_MY_ZSH_DIRECTORY}" "${ZDOTDIR}")

    execute "${omz_options} sh ${tmp_file}" "oh-my-zsh (install)"

}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   oh-my-zsh\n\n"

    [ -d "${OH_MY_ZSH_DIRECTORY}" ] || install_oh_my_zsh

    execute 'zsh -ic "omz update"' \
            "oh-my-zsh (update)"

}

main
