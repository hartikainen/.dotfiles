#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   fzf\n\n"

    brew_install "ripgrep" "ripgrep"
    brew_install "fzf (install)" "fzf"

    # To install key bindings and fuzzy completion for fzf. We set
    # `--no-{bash,zsh,fish}` because we assume that those are already
    # configured by the user.
    fzf_configure_command=$(printf '
        %s/opt/fzf/install \
        --xdg \
        --no-bash \
        --no-zsh \
        --no-fish
    ' "$(brew_prefix)")

    execute "$fzf_configure_command" "fzf (configure)"

}

main
