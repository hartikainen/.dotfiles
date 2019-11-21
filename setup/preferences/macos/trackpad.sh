#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "TODO: check these! (e.g. defaults read com.apple.AppleMultitouchTrackpad)"
exit(0)

print_in_purple "\n   Trackpad\n\n"

execute "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 0 && \
         defaults write com.apple.AppleMultitouchTrackpad Clicking -int 0 && \
         defaults -currentHost write -g com.apple.mouse.tapBehavior -int 0" \
    "Disable 'Tap to click'"

execute "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -int 1 && \
         defaults -currentHost write -g com.apple.trackpad.enableSecondaryClick -bool true && \
         defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0 && \
         defaults -currentHost write -g com.apple.trackpad.trackpadCornerClickBehavior -int 0" \
        "Map 'click or tap with two fingers' to the secondary click"

exceute "defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0 && \
         defaults write com.apple.trackpad.threeFingerDragGesture -int 1 && \
         defaults write com.apple.trackpad.threeFingerTapGesture -int 2" \
         "Set 'Swipe between full-screen apps' action to 4 fingers instead of 3 fingers'"
