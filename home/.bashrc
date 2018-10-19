#!/bin/bash

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# if [ -d "${HOME}/.bashrc.d" ]; then
#     for file in $(/bin/ls "${HOME}/.bashrc.d/*.bashrc"); do
#         source $file;
#     done
# fi

source_bash_files() {

    declare -r -a COMMON_FILES_TO_SOURCE=(
        ".bashrc.d/.bash_aliases"
        ".bashrc.d/.bash_autocomplete"
        ".bashrc.d/.bash_exports"
        ".bashrc.d/.bash_functions"
        ".bashrc.d/.bash_colors"
    )

    declare -r -a BASH_FILES_TO_SOURCE=(
        ".bashrc.d/.bash_options"
        ".bashrc.d/.bash_prompt"
    )

    declare -r -a ZSH_FILES_TO_SOURCE=(
        ".bashrc.d/.zsh_options"
        ".bashrc.d/.zsh_prompt"
    )

    declare -r -a LOCAL_FILES_TO_SOURCE=(
        ".bash.local"  # For local settings that should
                       # not be under version control.
    )

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    declare -r CURRENT_DIRECTORY="$(pwd)"

    if [ -n "$ZSH_VERSION" ]; then
        # For zsh

        declare -r -a FILES_TO_SOURCE=(
            "${COMMON_FILES_TO_SOURCE[@]}"
            "${ZSH_FILES_TO_SOURCE[@]}"
            "${LOCAL_FILES_TO_SOURCE[@]}"
        )

        cd "$(dirname "$(readlink "${(%):-%x}")")" \
            && . "../setup/utils.sh"
    else

        declare -r -a FILES_TO_SOURCE=(
            "${COMMON_FILES_TO_SOURCE[@]}"
            "${BASH_FILES_TO_SOURCE[@]}"
            "${LOCAL_FILES_TO_SOURCE[@]}"
        )

        # For bash
        cd "$(dirname "$(readlink "${BASH_SOURCE[0]}")")" \
            && . "../setup/utils.sh"
    fi

    cd "${CURRENT_DIRECTORY}"

    # shellcheck disable=SC2034
    declare -r OS="$(get_os)"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # for f in ${!FILES_TO_SOURCE[*]}; do
    for f in ${FILES_TO_SOURCE[*]}; do

        file="${HOME}/${f}"

        [ -r "${file}" ] \
            && . "${file}"

    done

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source_bash_files
unset -f source_bash_files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
