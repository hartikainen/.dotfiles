#!/bin/env zsh

[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return

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
export EDITOR="emacs" VISUAL="emacs"

# export "${CARGO_HOME:=${XDG_DATA_HOME}/cargo}"

[ -f "${ZSH}/oh-my-zsh.sh" ] && source "${ZSH}/oh-my-zsh.sh"
[ -f "${XDG_CONFIG_HOME}/fzf/fzf.sh" ] && source "${XDG_CONFIG_HOME}/fzf/fzf.sh"
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
        "${XDG_CONFIG_HOME}/zsh/conda_prompt"

        # For local settings that should
        # not be under version control.
        "${XDG_CONFIG_HOME}/zsh/local"
    )
    
    local DOTFILES_ROOT="$(realpath "${XDG_CONFIG_HOME}/../..")"
    . "${DOTFILES_ROOT}/setup/utils.sh"

    for file in "${FILES_TO_SOURCE[@]}"; do
        [ -r "${file}" ] && source "${file}"
    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source_files
unset -f source_files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Configure fzf

# Unset vars to prevent them from being appended to multiple times if bash
# shells are nested and as a result .bashrc is sourced multiple times
unset FZF_ALT_C_OPTS FZF_CTRL_R_OPTS FZF_DEFAULT_OPTS

# View full path in preview window (?)
export FZF_ALT_C_OPTS="${FZF_ALT_C_OPTS:+$FZF_ALT_C_OPTS }--preview 'echo {}' --preview-window down:5:hidden:wrap --bind '?:toggle-preview'"

# View full command in preview window (?)
export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--preview 'echo {}' --preview-window down:5:hidden:wrap --bind '?:toggle-preview'"

# # Exact-match rather than fuzzy matching by default (use ' to negate)
# export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--exact"

# Prevent fzf from reducing height to 40% by default
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--no-height"

# # Directly execute the command (Ctrl-X Ctrl-R)
# bind "$(bind -s | grep '^"\\C-r"' | sed 's/"/"\\C-x/;s/"$/\\C-m"/')"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Enable `conda`-command.

__conda_setup="$("${HOME}/conda/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    echo 'Unable to provide `conda` command.'
fi
unset __conda_setup

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
