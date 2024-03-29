#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

create_bash_local() {

    if [ -z ${XDG_CONFIG_HOME+x} ]; then
        echo "$(basename -- "${BASH_SOURCE[0]}"):
The \$XDG_CONFIG_HOME variable must be set for this setup script to function
properly."
        exit 1
    fi

    declare -r FILE_PATH="${XDG_CONFIG_HOME}/bash/local"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ ! -e "${FILE_PATH}" ] || [ -z "${FILE_PATH}" ]; then
        printf "%s\n\n" "#!/bin/bash" >> "${FILE_PATH}"
    fi

    print_result $? "${FILE_PATH}"

}

create_zsh_local() {

    declare -r FILE_PATH="${XDG_CONFIG_HOME}/zsh/local"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ ! -e "${FILE_PATH}" ] || [ -z "${FILE_PATH}" ]; then
        printf \
            "%s\n\n%s\n\n" \
            "#!/bin/zsh" \
            '[ -f "${XDG_CONFIG_HOME}/bash/local" ] && source "${XDG_CONFIG_HOME}/bash/local"' \
            >> "${FILE_PATH}"
    fi

    print_result $? "${FILE_PATH}"

}

create_gitconfig_local() {

    declare -r FILE_PATH="${XDG_CONFIG_HOME}/git/config.local"
    declare GIT_NAME=""
    declare GIT_EMAIL=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ ! -e "${FILE_PATH}" ] || [ -z "${FILE_PATH}" ]; then

        ask_for_confirmation "Do you want to set git user details now?"
        if answer_is_yes; then
            dotfilesDirectory=""
            while [ -z "${GIT_NAME}" ]; do
                ask "Please specify git name (e.g. <firstname> <lastname>): "
                GIT_NAME="$(get_answer)"
            done

            while [ -z "${GIT_EMAIL}" ]; do
                ask "Please specify git email (e.g. <firstname>.<lastname>@<provider>.com): "
                GIT_EMAIL="$(get_answer)"
            done
        fi

        printf "%s\n" \
"[commit]

    # Sign commits using GPG.
    # https://help.github.com/articles/signing-commits-using-gpg/

    # gpgsign = true


[user]

    name = ${GIT_NAME}
    email = ${GIT_EMAIL}
    # signingkey =" \
        >> "${FILE_PATH}"
    fi

    print_result $? "${FILE_PATH}"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n • Create local config files\n\n"

    create_bash_local
    create_zsh_local
    create_gitconfig_local

}

main
