#!/bin/bash
#
# Debian's `yq` package is the Python jq wrapper, which shares the name and
# almost nothing else: it has no `-o toml`, so `setup/codex/config.sh` cannot
# use it. This installs the Go implementation from its own releases instead.

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "../../utils.sh" &&
    . "./utils.sh"

declare -r YQ_VERSION="v4.53.6"
declare -r YQ_BINARY="/usr/local/bin/yq"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

yq_architecture() {

    case "$(uname -m)" in
        x86_64) printf "amd64" ;;
        aarch64 | arm64) printf "arm64" ;;
        *) return 1 ;;
    esac

}

installed_version() {
    "${YQ_BINARY}" --version 2>/dev/null | grep -o "v[0-9.]*$"
}

install_yq() {

    local architecture
    if ! architecture="$(yq_architecture)"; then
        print_error "yq (unsupported architecture $(uname -m))"
        return 1
    fi

    local -r url="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${architecture}"

    local tmpFile
    tmpFile="$(mktemp)"

    if ! download "${url}" "${tmpFile}" &>/dev/null; then
        rm -f "${tmpFile}"
        print_error "yq (download ${YQ_VERSION})"
        return 1
    fi

    execute \
        "sudo install -m 755 '${tmpFile}' '${YQ_BINARY}' && rm -f '${tmpFile}'" \
        "yq ${YQ_VERSION}"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   yq\n\n"

    if [ "$(installed_version)" = "${YQ_VERSION}" ]; then
        print_success "yq ${YQ_VERSION}"
        return 0
    fi

    install_yq

}

main
