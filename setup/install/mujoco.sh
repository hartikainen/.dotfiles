#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r MUJOCO_VERSION="150"
declare -r MUJOCO_PATH="${HOME}/.mujoco"
declare -r MUJOCO_URL="https://www.roboti.us/download/mjpro${MUJOCO_VERSION}_linux.zip"

declare -r LOCAL_SHELL_CONFIG_FILE="${HOME}/.bash.local"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


configure_mujoco() {

    declare -r CONFIGS="
# Mujoco
export MUJOCO_PATH=${MUJOCO_PATH}
export MUJOCO_VERSION=${MUJOCO_VERSION}
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH:+\${LD_LIBRARY_PATH}:}\${MUJOCO_PATH}/mjpro\${MUJOCO_VERSION}/bin
"

    if grep -Fxq "${CONFIGS}" "${LOCAL_SHELL_CONFIG_FILE}"; then
        execute \
            "printf '%s' '${CONFIGS}' >> ${LOCAL_SHELL_CONFIG_FILE} \
                 && . ${LOCAL_SHELL_CONFIG_FILE}"
    fi

    print_success "Mujoco (configure)"

}

install_mujoco() {

    # Install `mujoco` and add the necessary
    # configs in the local shell config file.

    tmp_file="$(mktemp /tmp/XXXXX.zip)"
    download "${MUJOCO_URL}" "${tmp_file}"

    mkdir -p ${MUJOCO_PATH}
    print_result $? "Create '${MUJOCO_PATH}'" "true"

    # extract "${tmp_file}" "${MUJOCO_PATH}"
    unzip -q ${tmp_file} -d ${MUJOCO_PATH}
    print_result $? "Extract archive" "true"

    configure_mujoco

}

main() {

    print_in_purple "\n   Mujoco\n\n"

    [ -d "${MUJOCO_PATH}" ] || install_mujoco

}

main
