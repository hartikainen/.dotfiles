#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   UI & UX\n\n"

    # Change screenshots save path
    execute "gsettings set 'org.gnome.gnome-screenshot' 'auto-save-directory' 'file:///${HOME}/Desktop/screenshots'" \
            "Change screenshots save path to '${HOME}/Desktop/screenshots'"

    execute "gsettings set org.gnome.desktop.interface clock-show-date true" \
            "Show date in the menu bar"

    # execute "gsettings set org.gnome.desktop.background picture-options 'stretched'" \
    #     "Set desktop background image options"

    execute "gsettings set org.gnome.libgnomekbd.keyboard layouts \"[ 'us', 'fi' ]\"" \
            "Set keyboard languages"

}

main
