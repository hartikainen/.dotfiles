#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

declare -r LOCAL_SHELL_CONFIG_FILE="${HOME}/.bash.local"
# declare -r CUDA_RUN_FILE_URL="https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers/cuda_9.2.148_396.37_linux"
# declare -r CUDA_PATCH_1_URL="https://developer.nvidia.com/compute/cuda/9.2/Prod2/patches/1/cuda_9.2.148.1_linux"
declare -r CUDA_VERSION="9.0"
declare -r CUDADIR="/usr/local/cuda-${CUDA_VERSION}"

declare -r CUDA_REPOSITORY_URL="http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub"

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

install_cuda() {

    sudo apt-key adv --fetch-keys ${CUDA_REPOSITORY_URL}
    wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.1.85-1_amd64.deb
    wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/nvidia-machine-learning-repo-ubuntu1604_1.0.0-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu1604_9.1.85-1_amd64.deb
    sudo dpkg -i nvidia-machine-learning-repo-ubuntu1604_1.0.0-1_amd64.deb
    sudo apt-get update

    # NCCL 2.x.
    sudo apt-get -y install \
         cuda9.0 \
         cuda-cublas-9-0 \
         cuda-cufft-9-0 \
         cuda-curand-9-0 \
         cuda-cusolver-9-0 \
         cuda-cusparse-9-0 \
         libcudnn7=7.2.1.38-1+cuda9.0 \
         libnccl2=2.2.13-1+cuda9.0 \
         cuda-command-line-tools-9-0

    # TensorRT runtime
    sudo apt-get update
    sudo apt-get install -y libnvinfer4=4.1.2-1+cuda9.0

    # install_package "freeglut3 freeglut3-dev libxi-dev libxmu-dev"

    # tmp_file="$(mktemp /tmp/XXXXX)"
    # download "${CUDA_RUN_FILE_URL}" "${tmp_file}"
    # execute "sudo sh ${tmp_file} --silent --toolkit --driver \
    #          && rm ${tmp_file}"

    # tmp_file="$(mktemp /tmp/XXXXX)"
    # download "${CUDA_PATCH_1_URL}" "${tmp_file}"
    # execute "sudo sh ${tmp_file} --silent --accept-eula \
    #          && rm ${tmp_file}"

    print_success "CUDA (install)"

}


configure_cuda() {
    declare -r CONFIGS="
# CUDA
export CUDADIR=${CUDADIR}
export PATH=\${PATH:+\${PATH}:}\${CUDADIR}/bin
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH:+\${LD_LIBRARY_PATH}:}\${CUDADIR}/lib64
"

    if [ ! $(grep -Fxq "${CONFIGS}" "${LOCAL_SHELL_CONFIG_FILE}") ]; then
        execute \
            "printf '%s' '${CONFIGS}' >> ${LOCAL_SHELL_CONFIG_FILE} \
                 && . ${LOCAL_SHELL_CONFIG_FILE}"
    fi

    print_success "CUDA (configure)"

}

main () {

    # https://www.pugetsystems.com/labs/hpc/How-to-install-CUDA-9-2-on-Ubuntu-18-04-1184/

    # disable_nouveau_driver

    # install_cuda

    configure_cuda

}

main


# # Install prerequisites
# execute dpkg --add-architecture i386
# update
# execute "sudo apt install build-essential libc:i386"

# # Download nvidia driver
# tmp_file="$(mktemp /tmp/XXXXX)"
# download "${NVIDIA_DRIVER_URL}" "${tmp_file}"
