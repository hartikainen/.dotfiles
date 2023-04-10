#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   fzf\n\n"

    brew_install "fzf" "fzf"
    brew_install "ripgrep" "ripgrep"
    # To install useful key bindings and fuzzy completion:
    execute "$(brew --prefix)/opt/fzf/install --xdg --all"

}

main
