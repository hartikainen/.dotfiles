#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

execute "defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0 && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0 && \

         defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true && \
         defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true" \
        "Set 'Swipe between full-screen apps' action to 4 fingers instead of 3 fingers'"
