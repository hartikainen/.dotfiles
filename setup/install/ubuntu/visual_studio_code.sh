#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

setup_repository() {

    print_error "TODO(visual_studio_code.sh): This might be unsafe. Check the fingerprint."

    execute "curl https://packages.microsoft.com/keys/microsoft.asc \
                  | gpg --dearmor \
                  > microsoft.gpg \
             && sudo install \
                -o root \
                -g root \
                -m 644 \
                microsoft.gpg \
                /etc/apt/trusted.gpg.d/ \
            &&  sudo sh -c \
                'echo \"deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main\" \
                > /etc/apt/sources.list.d/vscode.list'" \
            "Visual Studio Code (setup repository)"

}

install_visual_studio_code() {

    execute "sudo apt-get update \
             && sudo apt-get install apt-transport-https \
             && sudo apt-get install code \
             && code --version" \ # Verify installation
            "Visual Studio Code (install)"
}

update_visual_studio_code() {

    print_error "Visual_Studio_Code update not implemented yet!"

    print_success "Visual_Studio_Code (update)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    if [ ! "command -v code --version >/dev/null 2>&1" ]; then
        setup_repository
        install_visual_studio_code
    else
        setup_repository
        update_visual_studio_code
    fi

}

main
