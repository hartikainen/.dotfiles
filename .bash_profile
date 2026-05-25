#!/bin/bash
#
# ~/.bash_profile: read by bash when invoked as a login shell (SSH on
# Linux, macOS Terminal.app, `sudo -i`, etc.). Bash reads this in
# preference to `~/.bash_login` and `~/.profile`, so if you want
# `~/.profile` to run for bash you have to source it from here.

# Silence the "default shell is now zsh" notice Apple started printing
# in macOS 10.15. Bash-specific, so it lives here rather than in
# `~/.profile`.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Env vars (XDG_*, DOTFILES_DIR, `~/.local/bin/env`).
[ -f "${HOME}/.profile" ] && . "${HOME}/.profile"

# Interactive setup (aliases, prompt, completion, history, ...).
[ -f "${HOME}/.bashrc" ] && . "${HOME}/.bashrc"
