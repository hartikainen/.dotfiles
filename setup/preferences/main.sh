#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main () {

    print_in_purple "\n • Preferences\n"

    "./$(get_os_name)/main.sh"

}

main
