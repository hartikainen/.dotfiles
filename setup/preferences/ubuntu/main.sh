#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    ./privacy.sh
    ./terminal.sh
    ./ui_and_ux.sh

}

main
