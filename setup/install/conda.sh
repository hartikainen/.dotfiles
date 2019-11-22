#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r LOCAL_SHELL_CONFIG_FILE="${HOME}/.bash.local"
declare -r CONDA_DIRECTORY="${HOME}/conda"

if [ "$(get_os_name)" == "macos" ]; then
    # https://repo.anaconda.com/miniconda/
    CONDA_FILENAME="Miniconda3-latest-MacOSX-x86_64.sh"
elif [ "$(get_os_name)" == "ubuntu" ]; then
    CONDA_FILENAME="Miniconda3-latest-Linux-x86_64.sh"
fi
declare -r CONDA_LATEST_URL="https://repo.continuum.io/miniconda/${CONDA_FILENAME}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


configure_conda() {

    declare -r CONFIGS="# Conda
source ${CONDA_DIRECTORY}/etc/profile.d/conda.sh
conda activate base"

    num_lines=$(echo "${CONFIGS}" | wc -l)
    matching_lines=$(grep -Exq "${CONFIGS}" "${LOCAL_SHELL_CONFIG_FILE}")
    num_matching_lines=$(echo "${matching_lines}" | wc -l)

    if [ "${num_lines}" -ne "${num_matching_lines}" ]; then
        echo "does not exist yet"
        printf "\n%s\n" "${CONFIGS}" >> ${LOCAL_SHELL_CONFIG_FILE} \
            && . ${LOCAL_SHELL_CONFIG_FILE}
    else
        echo "exists"
        echo "${LOCAL_SHELL_CONFIG_FILE}"
    fi

    print_success "Conda (configure)"

}

install_conda() {

    # Install `conda` and add the necessary
    # configs in the local shell config file.

    tmp_file="$(mktemp /tmp/XXXXX)"

    download "${CONDA_LATEST_URL}" "${tmp_file}"
    # -b for batch/silent mode
    execute "bash ${tmp_file} -b -p $HOME/conda" \
            "Conda (install)"

    configure_conda

}

update_conda() {

    . "${LOCAL_SHELL_CONFIG_FILE}"

    execute \
        "conda update -n base conda" \
        "Conda (update)"

}

main() {

    print_in_purple "\n   Conda\n\n"

    [ -d "${CONDA_DIRECTORY}" ] || install_conda

    update_conda
}

main
