#!/bin/env zsh

[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return

# Set the cursor to a block style
echo -ne "\e[2 q"

# Path to your oh-my-zsh installation. TODO(hartikainen): should this be `XDG_CONFIG_HOME`?
export ZSH="${XDG_DATA_HOME}/oh-my-zsh"

ZSH_THEME="robbyrussell"

HIST_STAMPS="%d-%m-%y %T"
# `HISTFILE` is used only by interactive shells, that is, sub shells and
# external commands don't need this var. Thus, we don't need to export it.
mkdir -p "${XDG_STATE_HOME}/zsh"
HISTFILE="${XDG_STATE_HOME}/zsh/history"
mkdir -p "${XDG_CACHE_HOME}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"

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
[ -f "${XDG_CONFIG_HOME}/fzf/fzf.zsh" ] && source "${XDG_CONFIG_HOME}/fzf/fzf.zsh"

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
    
    local DOTFILES_ROOT="$(realpath "${XDG_CONFIG_HOME}/..")"
    . "${DOTFILES_ROOT}/setup/utils.sh"

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

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/oh-my-posh.toml)"
fi

WORDCHARS='"*?_-[]~&;!#$%^(){}<>\n'
autoload -Uz select-word-style
select-word-style normal
zstyle ':zle:*' word-style normal

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
