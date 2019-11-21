#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_spotify() {

    execute "sudo apt-get update \
             && sudo apt-key adv \
                 --keyserver hkp://keyserver.ubuntu.com:80 \
                 --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 \
             && echo deb http://repository.spotify.com stable non-free \
                | sudo tee /etc/apt/sources.list.d/spotify.list \
             && sudo apt-get install spotify-client" \
            "Spotify (setup repository)"

}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    install_spotify

}

main
