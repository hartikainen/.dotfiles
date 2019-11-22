#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


copy_profiles() {

    dynamic_profiles_dir_path="${HOME}/Library/Application Support/iTerm2/DynamicProfiles"

    for profile_file_path in $(ls ./iterm2_profiles/*.json); do
        profile_file_name=$(basename "${profile_file_path}")

        if [ -f "${dynamic_profiles_dir_path}/${profile_file_name}" ]; then
            ask_for_confirmation \
                "'${profile_file_name}' already exists, do you want to overwrite it?"

            if answer_is_yes; then
                rm "${dynamic_profiles_dir_path}/${profile_file_name}"
                cp "${profile_file_path}" "${dynamic_profiles_dir_path}/${profile_file_name}"
            else
                echo "Skipping '${profile_file_name}'"
            fi
        else
            cp "${profile_file_path}" "${dynamic_profiles_dir_path}/${profile_file_name}"
        fi

    done

}


main() {

    print_in_purple "\n   iTerm2\n\n"

    copy_profiles

}

main
