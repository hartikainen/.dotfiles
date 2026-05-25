#!/bin/bash

# ~/.bash_logout: executed by bash(1) when a login shell exits.

# When leaving the console, clear the screen to increase privacy. This
# is mainly relevant for Linux TTYs; on macOS and inside terminal
# emulators `/usr/bin/clear_console` doesn't exist and this is a no-op.

if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi
