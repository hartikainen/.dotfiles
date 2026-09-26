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

# Nix profiles supply packages independently of the source checkout.
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
fi
if [ -f "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
    . "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
case ":${PATH}:" in
    *":${HOME}/.nix-profile/bin:"*) ;;
    *) export PATH="${HOME}/.nix-profile/bin:${PATH}" ;;
esac

# Pick up `~/.local/bin` (and similar) added to PATH by `uv`, `rustup`, etc.
# Wrapped in `if`/`fi` rather than `[ -f ... ] && . ...` so that, when the
# file is absent, `.profile` doesn't inherit the `[ -f ]` test's exit
# status. POSIX shells use the exit status of the last command run, and
# callers like `sh -c '. ~/.profile && ...'` would otherwise short-circuit.
if [ -f "${HOME}/.local/bin/env" ]; then
    . "${HOME}/.local/bin/env"
fi
