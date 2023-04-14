#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

write_preferences() {

    if [ -z ${XDG_CONFIG_HOME+x} ]; then
        echo "$(basename -- "${BASH_SOURCE[0]}"):
The \$XDG_CONFIG_HOME variable must be set for this setup script to function
properly."
        exit 1
    fi

    execute "defaults write com.googlecode.iterm2 PrefsCustomFolder -string '${XDG_CONFIG_HOME}/iterm2'"
    execute "defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -int 1"

}

main() {

    print_in_purple "\n   iTerm2\n\n"

    write_preferences

}

main
