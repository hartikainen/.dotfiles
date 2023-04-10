#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r CONDA_DIRECTORY="${HOME}/conda"

case "$(get_os_name)" in
    "macos")
        declare -r CONDA_FILENAME="Miniconda3-latest-MacOSX-$(uname -m).sh"
        ;;
    "ubuntu"|"debian")
        declare -r CONDA_FILENAME="Miniconda3-latest-Linux-$(uname -m).sh"
        ;;
    *)
        print_error "OS not supported"
        exit 1
        ;;
esac

declare -r CONDA_LATEST_URL="https://repo.continuum.io/miniconda/${CONDA_FILENAME}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


install_conda() {

    # Install `conda` and add the necessary
    # configs in the local shell config file.

    case "$(get_os_name)" in
        "macos") tmp_file="$(mktemp "$(mktemp -t conda-install).sh")" ;;
        "ubuntu"|"debian") tmp_file="$(mktemp conda-install-XXXXXX.sh)" ;;
        *) print_error "OS not supported" && exit 1 ;;
    esac


    download "${CONDA_LATEST_URL}" "${tmp_file}"
    # -b for batch/silent mode
    execute "bash ${tmp_file} -u -b -f -p ${CONDA_DIRECTORY}" "install"

    rm "${tmp_file}"

}

update_conda() {

    execute 'bash -i -c "conda update -y -n base conda"' "update"

}

main() {

    print_in_purple "\n   Conda\n\n"

    [ -d "${CONDA_DIRECTORY}" ] && [ ! -z "$(ls -A ${CONDA_DIRECTORY})" ] || install_conda

    update_conda

}

main
