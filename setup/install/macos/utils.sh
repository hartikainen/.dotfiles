#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

brew_update() {

    if ! cmd_exists "brew"; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    execute "brew update" "Homebrew (update)"

}

brew_upgrade() {

    if ! cmd_exists "brew"; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    execute "brew upgrade" "Homebrew (upgrade)"

}

brew_bundle_install() {

    if ! cmd_exists "brew"; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    execute "brew bundle --global check || brew bundle --global install" "Homebrew (bundle)"

}
