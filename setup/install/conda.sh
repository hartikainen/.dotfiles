#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r LOCAL_SHELL_CONFIG_FILE="${HOME}/.bash.local"
declare -r CONDA_DIRECTORY="${HOME}/miniconda"
declare -r MINICONDA_LATEST_URL="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


configure_conda() {

    declare -r CONFIGS="
# Conda
export PATH=\"${CONDA_DIRECTORY}/bin:\${PATH}\"
"

    if ! grep -Fxq "export PATH=\"${CONDA_DIRECTORY}/bin:\${PATH}\"" ${LOCAL_SHELL_CONFIG_FILE}; then
        execute \
            "printf '%s' '${CONFIGS}' >> ${LOCAL_SHELL_CONFIG_FILE} \
                 && . ${LOCAL_SHELL_CONFIG_FILE}"
    fi

    print_success "Miniconda (configure)"

}

install_conda() {

    # Install `conda` and add the necessary
    # configs in the local shell config file.

    tmp_file="$(mktemp /tmp/XXXXX)"

    download "${MINICONDA_LATEST_URL}" "${tmp_file}"
    # -b for batch/silent mode
    execute "bash ${tmp_file} -b -p $HOME/miniconda" \
            "Miniconda (install)"

    configure_conda

}

update_conda() {

    . "${LOCAL_SHELL_CONFIG_FILE}"

    execute \
        "conda update -n base conda" \
        "Miniconda (update)"

}

main() {

    print_in_purple "\n   Conda\n\n"

    [ -d "$CONDA_DIRECTORY" ] || install_conda

    update_conda
}

main
