#!/usr/bin/env zsh

# No need to export anything here, as `.zshenv` is sourced for every shell
# (unless invoked as `zsh -f`).

# These could also be assigned on export in `.zshrc` but we prefer assigning
# this early. These get exported in `.zshrc`.
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

# Root of the dotfiles checkout. Used by `.zshrc`/`.bashrc` and the files
# they source to locate `setup/utils.sh`. Defaults to whichever directory
# `${HOME}/.zshenv` is a symlink into (which is how `create_symbolic_links.sh`
# wires it up), falling back to `${HOME}/.dotfiles`. Override by exporting
# `DOTFILES_DIR` from your environment.
if [ -z "${DOTFILES_DIR:-}" ] && [ -L "${HOME}/.zshenv" ]; then
    DOTFILES_DIR="$(dirname "$(readlink "${HOME}/.zshenv")")"
fi
: "${DOTFILES_DIR:=${HOME}/.dotfiles}"

# `ZDOTDIR` has to be set here to be able to store other zsh dotfiles outside of
# `HOME`.
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
