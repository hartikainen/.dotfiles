#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main () {

    print_in_purple "\n   Miscellaneous Tools\n\n"

    install_package "cURL" "curl"
    install_package "ShellCheck" "shellcheck"
    install_package "xclip" "xclip"
    install_package "xsel" "xsel"

}

main
