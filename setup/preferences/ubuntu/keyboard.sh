#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

execute "gsettings set \
         org.gnome.desktop.peripherals.keyboard \
         repeat-interval 10"

execute "gsettings set \
         org.gnome.desktop.peripherals.keyboard
         delay 200"
