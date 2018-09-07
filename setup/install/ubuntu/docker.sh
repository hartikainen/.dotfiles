#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r LOCAL_SHELL_CONFIG_FILE="$HOME/.bash.local"
declare -r DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

setup_repository() {

    print_error "TODO(docker.sh): This might be unsafe. Check the fingerprint."

    execute "sudo apt-get update \
             && sudo apt-get install \
                    apt-transport-https \
                    ca-certificates \
                    curl \
                    software-properties-common \
             && curl -fsSL ${DOCKER_GPG_URL} | sudo apt-key add - \
             && sudo apt-key fingerprint 0EBFCD88 \
             && sudo add-apt-repository \
                  'deb [arch=amd64] https://download.docker.com/linux/ubuntu \
                  $(lsb_release -cs) \
                  stable'" \
            "Docker (setup repository)"

}

install_docker() {

    execute "sudo apt-get update \
             && sudo apt-get install docker-ce \
             && sudo docker run hello-world" \ # Verify installation
            "Docker (install)"
}

update_docker() {

    print_error "Docker update not implemented yet!"

    print_success "Docker (update)"

}

post_install_steps() {

    # https://docs.docker.com/install/linux/linux-postinstall/

    execute "sudo groupadd docker \
             && sudo usermod -aG docker ${USER} \
             && sudo systemctl enable docker" \
            "Docker (post installation steps)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    if [ ! "command -v docker >/dev/null 2>&1" ]; then
        setup_repository
        install_docker
        post_install_steps
    else
        setup_repository
        update_docker
        post_install_steps
    fi

}

main
