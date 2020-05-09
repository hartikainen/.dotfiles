#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r LOCAL_SHELL_CONFIG_FILE="${HOME}/.bash.local"
declare -a EMACS_SETTINGS_REMOTE="git@github.com:hartikainen/myemacs.git"
declare -a EMACS_SETTINGS_DIR="${HOME}/.emacs.d"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

clone_emacs_settings() {

    [ -d "${EMACS_SETTINGS_DIR}" ] || execute \
        "git clone ${EMACS_SETTINGS_REMOTE} ${EMACS_SETTINGS_DIR}"

    print_success "Emacs (clone settings)"
}

create_emacs_conda_environment() {

    # Need to source this to activate conda
    . "${LOCAL_SHELL_CONFIG_FILE}"

    execute \
        "conda create --name emacs 'python>=3.7' || true" \
        "Emacs (create conda env)"

    local EMACS_CONDA_PACKAGES=(
        "jedi"
        "autopep8"
        "yapf"
        "black"
        "flake8"
        "rope"
    )

    execute \
        "conda activate emacs && pip install ${EMACS_CONDA_PACKAGES[*]}" \
        "Emacs (install conda packages)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Emacs\n\n"

    "./$(get_os_name)/emacs.sh"

    printf "\n"

    clone_emacs_settings

    create_emacs_conda_environment

}

main
