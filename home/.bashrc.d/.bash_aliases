#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../setup/utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias cd..="cd .."

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

alias :q="exit"
alias c="clear"
alias ch="history -c && > ~/.bash_history"
alias e="vim --"
alias g="git"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ll="ls -l"
alias m="man"
alias map="xargs -n1"
alias n="npm"
alias path='printf "%b\n" "${PATH//:/\\n}"'
alias q="exit"
alias rm="rm -rf --"
alias t="tmux"
alias y="yarn"

# alias emacs="emacs26"
alias emacs="emacs26 -nw"
alias emacsw="emacs -w"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Load OS specific aliases.

. ".bash_aliases.$(get_os)"
