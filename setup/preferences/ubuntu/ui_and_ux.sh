#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   UI & UX\n\n"

    # Change screenshots save path
    execute "gsettings set 'org.gnome.gnome-screenshot' 'auto-save-directory' 'file:///${HOME}/Desktop/screenshots'" \
            "Change screenshots save path to '${HOME}/Desktop/screenshots'"

    execute "gsettings set com.canonical.indicator.bluetooth visible true" \
            "Show bluetooth icon from the menu bar"

    execute "gsettings set com.canonical.indicator.sound visible true" \
            "Show volume icon from the menu bar"

    execute "gsettings set com.canonical.indicator.power icon-policy 'charge' && \
             gsettings set com.canonical.indicator.power show-time false" \
            "Hide battery icon from the menu bar when the battery is not in use"

    execute "gsettings set org.gnome.desktop.interface clock-show-date true" \
            "Show date in the menu bar"

    execute "gsettings set com.canonical.indicator.datetime custom-time-format 'Week %U, %a, %D %k:%M' && \
             gsettings set com.canonical.indicator.datetime time-format 'custom'" \
            "Use custom date format in the menu bar"

    # execute "gsettings set org.gnome.desktop.background picture-options 'stretched'" \
    #     "Set desktop background image options"

    execute "gsettings set org.gnome.libgnomekbd.keyboard layouts \"[ 'us', 'fi' ]\"" \
            "Set keyboard languages"

}

main
