#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   Keyboard\n\n"

execute "defaults write -g AppleKeyboardUIMode -int 3" \
    "Enable full keyboard access for all controls"

execute "defaults write -g ApplePressAndHoldEnabled -bool false" \
    "Disable press-and-hold in favor of key repeat"

execute "defaults write -g InitialKeyRepeat_Level_Saved -int 20" \
    "Set delay until repeat"

execute "defaults write -g InitialKeyRepeat -int 15" \
    "Set delay until repeat"

execute "defaults write -g KeyRepeat -int 1" \
    "Set the key repeat rate to fast"

execute "defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>'" \
    'Disable "Select the previous input source" keybinding'

execute "defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>655360</integer></array><key>type</key><string>standard</string></dict></dict>'" \
    'Enable and set "Select next source in Input menu" to Shift + Alt + Space'

execute 'defaults write -g com.apple.keyboard.fnState -bool true' \
    'Enable the "Use F1, F2, etc. keys as standard function keys" setting'

execute "defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
    '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>0</integer><key>KeyboardLayout Name</key><string>U.S.</string></dict>' \
    '<dict><key>Bundle ID</key><string>com.apple.CharacterPaletteIM</string><key>InputSourceKind</key><string>Non Keyboard Input Method</string></dict>' \
    '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>17</integer><key>KeyboardLayout Name</key><string>Finnish</string></dict>'" \
    "Set input sources (U.S. and Finnish)"

execute "defaults write com.apple.TextInputMenu visible -bool true" \
    "Show input menu in menu bar"

# __swap_ctrl_caps_command="$(printf \
#     "hidutil property --set '{%s: [%s, %s] }'" \
#     '"UserKeyMapping"' \
#     '{"HIDKeyboardModifierMappingSrc": 0x700000039, "HIDKeyboardModifierMappingDst": 0x7000000e0 }' \
#     '{"HIDKeyboardModifierMappingSrc": 0x7000000e0, "HIDKeyboardModifierMappingDst": 0x700000039 }' \
# )"
# execute "${__swap_ctrl_caps_command}" "Swap Control <-> Caps Lock"
# unset -f __swap_ctrl_caps_command

# execute "defaults write -g NSAutomaticCapitalizationEnabled -bool false" \
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
