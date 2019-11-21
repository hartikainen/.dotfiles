#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

declare -r NVIDIA_DRIVER_URL="http://us.download.nvidia.com/XFree86/Linux-x86_64/390.87/NVIDIA-Linux-x86_64-390.87.run"


#TODO(hartikainen): These should be installed from apt-get!

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# disable_nvidia_nouveau_driver() {

#     # Blacklist Nvidia nouveau driver
#     execute "sudo bash -c \
#                  'echo blacklist nouveau > \
#                   /etc/modprobe.d/blacklist-nvidia-nouveau.conf'"
#     execute "sudo bash -c \
#                  'echo options nouveau modeset=0 >> \
#                   /etc/modprobe.d/blacklist-nvidia-nouveau.conf'"

#     # Update kernel initramfs
#     sudo update-initramfs -u

# }

main () {

    update

    # 1. Confirm and remove old drivers
    execute "sudo apt-get purge 'nvidia*'"

    add_ppa "graphics-drivers/ppa"
    update
    install_package "nvidia-390" "nvidia-390"

    # disable_nouveau_driver

}

main



# # Install prerequisites
# execute dpkg --add-architecture i386
# update
# execute "sudo apt install build-essential libc:i386"

# # Download nvidia driver
# tmp_file="$(mktemp /tmp/XXXXX)"
# download "${NVIDIA_DRIVER_URL}" "${tmp_file}"
