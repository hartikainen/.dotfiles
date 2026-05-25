#!/bin/sh
#
# ~/.profile: read by login shells (`bash` via `~/.bash_profile`, plain
# `sh`/`dash`, and many display managers). Holds env vars that should be
# visible to every process, regardless of shell.
#
# Keep this file POSIX-portable — no bashisms (`[[`, arrays, `local`,
# `command -v` is fine), no zshisms. Bash- or zsh-specific work belongs
# in `~/.bash_profile` / `~/.zshenv`.

# XDG base directory defaults. https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
export XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_DATA_HOME

# Root of the dotfiles checkout. Used by the rc files to locate
# `setup/utils.sh`. Defaults to whichever directory `${HOME}/.bash_profile`
# is a symlink into (which is how `create_symbolic_links.sh` wires it up),
# falling back to `${HOME}/.dotfiles`. Override by exporting `DOTFILES_DIR`
# from your environment.
if [ -z "${DOTFILES_DIR:-}" ] && [ -L "${HOME}/.bash_profile" ]; then
    DOTFILES_DIR="$(dirname "$(readlink "${HOME}/.bash_profile")")"
fi
: "${DOTFILES_DIR:=${HOME}/.dotfiles}"
export DOTFILES_DIR

# Pick up `~/.local/bin` (and similar) added to PATH by `uv`, `rustup`, etc.
# Wrapped in `if`/`fi` rather than `[ -f ... ] && . ...` so that, when the
# file is absent, `.profile` doesn't inherit the `[ -f ]` test's exit
# status. POSIX shells use the exit status of the last command run, and
# callers like `sh -c '. ~/.profile && ...'` would otherwise short-circuit.
if [ -f "${HOME}/.local/bin/env" ]; then
    . "${HOME}/.local/bin/env"
fi
