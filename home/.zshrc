#!/bin/env zsh

[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

ZSH_THEME="robbyrussell"

HIST_STAMPS="%d-%m-%y %T"

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

[ -f "${ZSH}/oh-my-zsh.sh" ] && source "${ZSH}/oh-my-zsh.sh"

if [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
