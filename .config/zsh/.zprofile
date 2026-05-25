#!/usr/bin/env zsh

# Only login shells read `.zprofile` and most Linux terminals don’t start login
# shells by default. Apple’s `Terminal.app` does, however.

# The following are used by Apple in `/etc/zshrc`, which is sourced before
# `.zshrc`. Wouldn't have to go in `.zprofile` otherwise. We could put them
# under `.zshenv`, but we prefer to keep that file as small as possible.
export SHELL_SESSION_DIR="${XDG_STATE_HOME}/zsh/sessions"
export SHELL_SESSION_FILE="${SHELL_SESSION_DIR}/${TERM_SESSION_ID}"
