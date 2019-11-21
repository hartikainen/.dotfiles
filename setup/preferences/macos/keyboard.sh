#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   Keyboard\n\n"


KEYBOARD_VENDOR=$(ioreg -Src IOHIDInterface | awk '$2 == "\"VendorID\"" { print $4 }') # 1452
KEYBOARD_PRODUCT=$(ioreg -Src IOHIDInterface | awk '$2 == "\"ProductID\"" { print $4 }') # 610

if [ -z "${KEYBOARD_VENDOR}" && -z "${KEYBOARD_PRODUCT}" ]; then
    KEYBOARD_NUMBER=0 # TODO(hartikainen): Not sure if this can be hard-coded
    KEYBOARD_ID="${KEYBOARD_VENDOR}-${KEYBOARD_PRODUCT}-${KEYBOARD_ID}"

    execute "defaults -currentHost write -g 'com.apple.keyboard.modifiermapping.${KEYBOARD_ID}' -array-add '<dict><key>HIDKeyboardModifierMappingDst</key><integer>2</integer><key>HIDKeyboardModifierMappingSrc</key><integer>0</integer></dict>'" \
            "Remap CAPS LOCK to CTRL"
fi

execute "defaults write -g AppleKeyboardUIMode -int 3" \
    "Enable full keyboard access for all controls"

execute "defaults write -g ApplePressAndHoldEnabled -bool false" \
    "Disable press-and-hold in favor of key repeat"

execute "defaults write -g 'InitialKeyRepeat_Level_Saved' -int 10" \
    "Set delay until repeat"

execute "defaults write -g 'InitialKeyRepeat' -int 0.1" \
    "Set delay until repeat"

execute "defaults write -g KeyRepeat -int 0.01" \
    "Set the key repeat rate to fast"

# execute "defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false" \
#     "Disable automatic capitalization"

# execute "defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false" \
#     "Disable automatic correction"

# execute "defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false" \
#     "Disable automatic period substitution"

# execute "defaults write -g NSAutomaticDashSubstitutionEnabled -bool false" \
#     "Disable smart dashes"

# execute "defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false" \
#     "Disable smart quotes"
