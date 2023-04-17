#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   UI & UX\n\n"

execute "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true && \
         defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true" \
   "Avoid creating '.DS_Store' files on network or USB volumes"

execute "defaults write com.apple.menuextra.battery ShowPercent -string 'YES'" \
    "Show battery percentage from the menu bar"

execute "sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true" \
    "Show language menu in the top right corner of the boot screen"

execute "defaults write com.apple.CrashReporter UseUNC 1" \
    "Make crash reports appear as notifications"

execute "defaults write com.apple.LaunchServices LSQuarantine -bool false" \
    "Disable 'Are you sure you want to open this application?' dialog"

execute "defaults write com.apple.print.PrintingPrefs 'Quit When Finished' -bool true" \
    "Automatically quit the printer app once the print jobs are completed"

execute "defaults write com.apple.screencapture disable-shadow -bool true" \
    "Disable shadow in screenshots"

execute "defaults write com.apple.screencapture location -string '$HOME/Desktop/screenshots'" \
    "Save screenshots to ~/Desktop/screenshots"

execute "defaults write com.apple.screencapture type -string 'png'" \
    "Save screenshots as PNGs"

execute "defaults write -g AppleFontSmoothing -int 2" \
    "Enable subpixel font rendering on non-Apple LCDs"

execute "defaults write -g AppleShowScrollBars -string 'Always'" \
    "Always show scrollbars"

execute "defaults write -g NSAutomaticWindowAnimationsEnabled -bool false" \
    "Disable window opening and closing animations."

execute "defaults write -g NSDisableAutomaticTermination -bool true" \
    "Disable automatic termination of inactive apps"

execute "defaults write -g NSNavPanelExpandedStateForSaveMode -bool true" \
    "Expand save panel by default"

execute "defaults write -g NSTableViewDefaultSizeMode -int 2" \
    "Set sidebar icon size to medium"

execute "defaults write -g NSUseAnimatedFocusRing -bool false" \
    "Disable the over-the-top focus ring animation"

execute "defaults write -g NSWindowResizeTime -float 0.001" \
    "Accelerated playback when adjusting the window size."

execute "defaults write -g PMPrintingExpandedStateForPrint -bool true" \
    "Expand print panel by default"

execute "defaults write -g QLPanelAnimationDuration -float 0" \
    "Disable opening a Quick Look window animations."

execute "defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false" \
    "Disable resume system-wide"

execute "sudo systemsetup -setrestartfreeze on" \
    "Restart automatically if the computer freezes"

# Change the settings directly in the core brightness plist (defaults doesn't deal with nested data structures well)
__current_user_uid="$(dscl . -read "/Users/$(whoami)/" "GeneratedUID" | sed -e "s/^GeneratedUID: /CBUser-/")"
__CoreBrightness_plist="/private/var/root/Library/Preferences/com.apple.CoreBrightness.plist"

execute "sudo /usr/libexec/PlistBuddy -c \
             'Set :${__current_user_uid}:CBBlueReductionStatus:BlueReductionEnabled 1' \
             '${__CoreBrightness_plist}' && \
         sudo /usr/libexec/PlistBuddy -c \
             'Set :${__current_user_uid}:CBBlueReductionStatus:BlueReductionMode 2' \
             '${__CoreBrightness_plist}' && \
         sudo /usr/libexec/PlistBuddy -c \
             'Set :${__current_user_uid}:CBBlueReductionStatus:BlueLightReductionSchedule:DayStartHour 6' \
             '${__CoreBrightness_plist}' && \
         sudo /usr/libexec/PlistBuddy -c \
             'Set :${__current_user_uid}:CBBlueReductionStatus:BlueLightReductionSchedule:NightStartHour 1'8\
             '${__CoreBrightness_plist}'" \
         "Set Night Shift schedule"

unset __current_user_uid
unset __CoreBrightness_plist

for service_name in "SystemUIServer" "cfprefsd" "corebrightnessd"; do
    killall "$service_name"  &> /dev/null;
done
