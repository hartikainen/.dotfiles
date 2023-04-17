#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   Terminal\n\n"

execute "defaults write com.apple.terminal FocusFollowsMouse -string true" \
    "Make the focus automatically follow the mouse"

execute "defaults write com.apple.terminal SecureKeyboardEntry -bool true" \
    "Enable 'Secure Keyboard Entry'"

execute "defaults write com.apple.terminal StringEncodings -array 4" \
    "Only use UTF-8"

execute "./set_terminal_theme.applescript" \
    "Set custom terminal theme"

# TODO(hartikainen): Use Touch ID for sudo?
# if ! grep -q -F 'auth sufficient pam_tid.so' "/etc/pam.d/sudo"; then
#     sudo sed -i '' $'2i\\\nauth sufficient pam_tid.so\\\n' "/etc/pam.d/sudo"
# fi
