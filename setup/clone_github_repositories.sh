#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "utils.sh"

declare -a REPOSITORIES_DIR="${HOME}/github"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

clone_repositories() {

    [ -d "${REPOSITORIES_DIR}" ] || execute "mkdir ${REPOSITORIES_DIR}"

    declare -a REPOSITORY_URLS=(
        "git@github.com:haarnoja/softqlearning-private"
    )

    for repository_url in "${REPOSITORY_URLS[@]}"; do
        left_trimmed_url="${repository_url##git@github.com:}"
        trimmed_url="${left_trimmed_url%.git*}"
        repository_name="$(basename "${trimmed_url}")"
        user_name="$(basename "${trimmed_url%/${repository_name}}")"

        user_dir="${REPOSITORIES_DIR}/${user_name}"
        repository_dir="${user_dir}/${repository_name}"

        [ -d "${repository_dir}" ] \
            && print_success "Already exists: ${repository_url} (at ${repository_dir})" \
            && continue

        [ -d "${user_dir}" ] || execute "mkdir -p ${user_dir}"

        execute "git clone ${repository_url} ${repository_dir}"

    done

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n • Clone github repositories\n\n"

    clone_repositories

}

main
