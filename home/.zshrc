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
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

zstyle ':completion:*' special-dirs false

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


source_files() {

    declare -r -a FILES_TO_SOURCE=(
        ".bashrc.d/.bash_aliases"
        ".bashrc.d/.bash_exports"
        ".bashrc.d/.bash_functions"
        ".bashrc.d/.bash_colors"

        # zsh-specific files
        ".bashrc.d/.zsh_options"
        ".bashrc.d/.zsh_prompt"

        # For local settings that should
        # not be under version control.
        ".zsh.local"
    )

    declare -r CURRENT_DIRECTORY="$(pwd)"

    cd "$(dirname "$(readlink "${(%):-%x}")")" \
        && . "../setup/utils.sh"

    cd "${CURRENT_DIRECTORY}"

    # shellcheck disable=SC2034
    declare -r OS="$(get_os_name)"

    for f in ${FILES_TO_SOURCE[*]}; do

        file="${HOME}/${f}"

        [ -r "${file}" ] \
            && . "${file}"

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

# Clear system messages (system copyright notice, the date
# and time of the last login, the message of the day, etc.).

# clear
