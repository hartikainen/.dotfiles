#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n • Nvidia Drivers\n\n"

    # "./$(get_os_name)/nvidia_drivers.sh"
    "./$(get_os_name)/cuda.sh"

}

main
