#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Privacy\n\n"

    execute "gsettings set com.canonical.Unity.Lenses remote-content-search 'none'" \
            "Turn off 'Remote Search' so that search terms in Dash do not get sent over the internet"

}

main
