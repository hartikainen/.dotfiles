#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    update

    execute "sudo snap install -y emacs"

}

main
