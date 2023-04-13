#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

initialize_git_repository() {

    declare -r DOTFILES_DIRECTORY="$1"
    declare -r GIT_ORIGIN="$2"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if [ -z "$DOTFILES_DIRECTORY" ]; then
        print_error "Please provide the path to the dotfiles directory."
        exit 1
    fi

    if [ -z "$GIT_ORIGIN" ]; then
        print_error "Please provide a git origin URL."
        exit 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ! is_git_repository; then
        # Run the git init commands in the root of the dotfiles directory.
        git_init_command=$(printf \
            'cd "%s" && git init && git remote add origin "%s"' \
            "$DOTFILES_DIRECTORY" \
            "$GIT_ORIGIN")
        bash -c "$git_init_command"
        print_result "$?" "Initialize the Git repository"
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • Initialize Git repository\n\n"
    initialize_git_repository "$@"
}

main "$@"
