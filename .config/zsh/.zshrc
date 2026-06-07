#!/bin/env zsh

# History safety: configure HISTFILE and append-on-exit behaviour BEFORE
# the `TERM == "dumb"` early-return below. Otherwise any `zsh -ic '...'`
# subshell (scripts, Makefiles, agent tooling — all of which set
# `TERM=dumb`) falls back to `/etc/zshrc`'s defaults of HISTSIZE=2000,
# SAVEHIST=1000 with no APPEND_HISTORY, and zsh's documented default
# without APPEND_HISTORY is to *replace* the history file on shell exit
# with the in-memory list (capped at SAVEHIST). APPEND_HISTORY flips
# that to append, so an exiting shell can no longer truncate the file.
# `HISTFILE` is only used by interactive shells, so no `export` needed.
mkdir -p "${XDG_STATE_HOME}/zsh"
HISTFILE="${XDG_STATE_HOME}/zsh/history"
# HISTSIZE caps the *in-memory* history (what `fzf-history-widget` /
# Ctrl+R has to scan); SAVEHIST caps what's written to disk. Decoupling
# them keeps Ctrl+R snappy (only the most recent ~HISTSIZE commands are
# searched interactively) while preserving a much longer archive on
# disk that you can still reach via `grep $HISTFILE`, `fc -R N`, or
# `~/.dotfiles/setup/recover_zsh_history.py`.
HISTSIZE=10000
SAVEHIST=50000
setopt APPEND_HISTORY EXTENDED_HISTORY

# Dumb subshells (agent tooling, `zsh -ic ...` from scripts, etc.) still
# shouldn't pollute interactive history. Unsetting `HISTFILE` disables
# both loading and saving for this shell while leaving the global config
# above intact for real interactive sessions.
if [[ $TERM == "dumb" ]]; then
    unset HISTFILE
    SAVEHIST=0
    unsetopt zle
    PS1='$ '
    return
fi

# Set the cursor to a block style
echo -ne "\e[2 q"

# Oh-my-zsh ships application data (themes, plugins, the installer's own
# clone), not user config, so `XDG_DATA_HOME` is the right base.
export ZSH="${XDG_DATA_HOME}/oh-my-zsh"

ZSH_THEME="robbyrussell"

HIST_STAMPS="%d-%m-%y %T"
mkdir -p "${XDG_CACHE_HOME}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
# Keep the completion dump in the XDG cache.
ZSH_COMPDUMP="${XDG_CACHE_HOME}/zsh/.zcompdump-${HOST}-${ZSH_VERSION}"

plugins=(
    docker
    docker-compose
    # docker-machine
    python
    pip
    autopep8
    web-search
    # brew
)

# `XDG_*_HOME` vars are already exported by `.profile` (sourced from `.zshenv`).
# Only variables needed by external commands or non-interactive sub shells
# should be exported.
export XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_DATA_HOME

# export "${CARGO_HOME:=${XDG_DATA_HOME}/cargo}"

# Add Homebrew's site-functions to fpath before oh-my-zsh runs compinit, so
# brew-installed completions are picked up without a second compinit pass.
# `$HOMEBREW_PREFIX` is set by `brew shellenv` in `.zprofile`; using it avoids
# the ~100-300ms subshell cost of `$(brew --prefix)` on every shell startup.
if [ -n "$HOMEBREW_PREFIX" ]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

[ -f "${ZSH}/oh-my-zsh.sh" ] && source "${ZSH}/oh-my-zsh.sh"
command -v fzf &>/dev/null && source <(fzf --zsh)

zstyle ':completion:*' special-dirs false

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source_files() {

    declare -r -a FILES_TO_SOURCE=(
        "${XDG_CONFIG_HOME}/bash/aliases"
        "${XDG_CONFIG_HOME}/bash/exports"
        "${XDG_CONFIG_HOME}/bash/functions"
        "${XDG_CONFIG_HOME}/bash/colors"

        # zsh-specific files
        "${XDG_CONFIG_HOME}/zsh/options"

        # For local settings that should
        # not be under version control.
        "${XDG_CONFIG_HOME}/zsh/local"
    )

    . "${DOTFILES_DIR}/setup/utils.sh"

    for file in "${FILES_TO_SOURCE[@]}"; do
        [ -r "${file}" ] && source "${file}"
    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source_files
unset -f source_files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# # Directly execute the command (Ctrl-X Ctrl-R)
# bind "$(bind -s | grep '^"\\C-r"' | sed 's/"/"\\C-x/;s/"$/\\C-m"/')"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && command -v oh-my-posh >/dev/null; then
    eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/oh-my-posh.toml)"
fi

WORDCHARS='*?_-[]~&;!#$%^(){}<>\n'
autoload -Uz select-word-style
select-word-style normal
zstyle ':zle:*' word-style normal

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
