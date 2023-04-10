#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r DOOM_INSTALL_DIR="${XDG_CONFIG_HOME}/emacs"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_doom_emacs() {

    if [ ! -f "${DOOM_INSTALL_DIR}/bin/doom" ]; then
        execute \
            "git clone --depth 1 https://github.com/doomemacs/doomemacs ${DOOM_INSTALL_DIR}" \
            "Emacs (clone doom)"
        execute "bash -i -c '${DOOM_INSTALL_DIR}/bin/doom install -!'"
    else
        print_success "Skip doom install (already installed)"
    fi

}

upgrade_doom_emacs() {

    execute "bash -i -c '${DOOM_INSTALL_DIR}/bin/doom upgrade'"
    execute "bash -i -c '${DOOM_INSTALL_DIR}/bin/doom sync'"

}

create_emacs_conda_environment() {

    execute \
        'bash -i -c "conda create --name emacs \"python>=3.10\" || true"' \
        "conda create --name emacs 'python>=3.10'"

    local EMACS_CONDA_PACKAGES=(
        "jedi"
        "autopep8"
        "yapf"
        "black"
        "flake8"
        "rope"
    )

    pip_install_command="pip install -U ${EMACS_CONDA_PACKAGES[*]}"
    execute \
        "bash -i -c 'conda activate emacs && $pip_install_command'" \
        "pip install ${EMACS_CONDA_PACKAGES[*]}"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Emacs\n\n"

    "./$(get_os_name)/emacs.sh"

    print_in_purple "\n   Doom Emacs\n\n"

    install_doom_emacs
    upgrade_doom_emacs

    print_in_purple "\n   Create Emacs Conda environment\n\n"

    create_emacs_conda_environment

}

main
