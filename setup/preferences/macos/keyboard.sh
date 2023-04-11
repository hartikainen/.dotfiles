#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   Keyboard\n\n"

execute "defaults write -g AppleKeyboardUIMode -int 3" \
    "Enable full keyboard access for all controls"

execute "defaults write -g ApplePressAndHoldEnabled -bool false" \
    "Disable press-and-hold in favor of key repeat"

execute "defaults write -g 'InitialKeyRepeat_Level_Saved' -int 20" \
    "Set delay until repeat"

execute "defaults write -g 'InitialKeyRepeat' -int 15" \
    "Set delay until repeat"

execute "defaults write -g KeyRepeat -int 1" \
    "Set the key repeat rate to fast"

# execute "plutil -replace \
#          'AppleSymbolicHotKeys.60.enabled' \
#          -bool false \
#          '${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist'" \
#     'Disable "Select the previous input source" keybinding'

# execute "plutil -replace \
#          'AppleSymbolicHotKeys.61.enabled' \
#          -bool false \
#          '${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist'" \
#     'Disable "Select nest source in Input menu" keybinding'

# execute "defaults write \
#          '${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist' \
#          'AppleSymbolicHotKeys' \
#          -dict-add 60 \
#          '{enabled = 0; value = { parameters = (); type = standard; };}'" \
#     'Disable "Select the previous input source" keybinding'

# execute "defaults write \
#          '${HOME}/Library/Preferences/com.apple.symbolichotkeys.plist' \
#          'AppleSymbolicHotKeys' \
#          -dict-add 61 \
#          '{enabled = 0; value = { parameters = (); type = standard; };}'" \
#     'Disable "Select nest source in Input menu" keybinding'

execute 'defaults write -g com.apple.keyboard.fnState -bool true' \
    'Enable the "Use F1, F2, etc. keys as standard function keys" setting'

# __set_input_sources_command="$(printf \
#     "defaults write com.apple.HIToolbox.plist AppleEnabledInputSources -array '%s' '%s' '%s'" \
#     '{InputSourceKind="Keyboard Layout"; "KeyboardLayout ID"=0; "KeyboardLayout Name"="U.S.";}' \
#     '{"Bundle ID" = "com.apple.CharacterPaletteIM"; InputSourceKind = "Non Keyboard Input Method";}' \
#     '{InputSourceKind="Keyboard Layout"; "KeyboardLayout ID"=17; "KeyboardLayout Name"="Finnish";}' \
# )"
# execute "${__set_input_sources_command}" "Set input sources ('U.S.' and 'Finnish')"
# unset -f __set_input_sources_command

# __swap_ctrl_caps_command="$(printf \
#     "hidutil property --set '{%s: [%s, %s] }'" \
#     '"UserKeyMapping"' \
#     '{"HIDKeyboardModifierMappingSrc": 0x700000039, "HIDKeyboardModifierMappingDst": 0x7000000e0 }' \
#     '{"HIDKeyboardModifierMappingSrc": 0x7000000e0, "HIDKeyboardModifierMappingDst": 0x700000039 }' \
# )"
# execute "${__swap_ctrl_caps_command}" "Swap Control <-> Caps Lock"
# unset -f __swap_ctrl_caps_command

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

# To make the settings take effect.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
