#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

declare -r LOCAL_SHELL_CONFIG_FILE="${HOME}/.bash.local"
declare -r CUDA_RUN_FILE_URL="https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers/cuda_9.2.148_396.37_linux"
declare -r CUDA_PATCH_1_URL="https://developer.nvidia.com/compute/cuda/9.2/Prod2/patches/1/cuda_9.2.148.1_linux"
declare -r CUDA_BASE_PATH="/usr/local/cuda-9.2"

https://developer.nvidia.com/compute/machine-learning/cudnn/secure/v7.2.1/prod/9.2_20180806/cudnn-9.2-linux-x64-v7.2.1.38


wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.2.1.38-1+cuda9.2_amd64.deb
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.2.1.38-1+cuda9.2_amd64.deb

# to use TensorFlow with multiple GPUs
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libnccl2_2.1.4-1+cuda9.0_amd64.deb
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libnccl-dev_2.1.4-1+cuda9.0_amd64.deb



wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.0.5.15-1+cuda9.0_amd64.deb
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.0.5.15-1+cuda9.0_amd64.deb
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libnccl2_2.1.4-1+cuda9.0_amd64.deb
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libnccl-dev_2.1.4-1+cuda9.0_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1604_9.0.176-1_amd64.deb
sudo dpkg -i libcudnn7_7.0.5.15-1+cuda9.0_amd64.deb
sudo dpkg -i libcudnn7-dev_7.0.5.15-1+cuda9.0_amd64.deb
sudo dpkg -i libnccl2_2.1.4-1+cuda9.0_amd64.deb
sudo dpkg -i libnccl-dev_2.1.4-1+cuda9.0_amd64.deb
sudo apt-get update
sudo apt-get install cuda=9.0.176-1
sudo apt-get install libcudnn7-dev
sudo apt-get install libnccl-dev

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_cudnn() {

    update

    install_package ""

    tmp_file="$(mktemp /tmp/XXXXX)"
    download "${CUDA_RUN_FILE_URL}" "${tmp_file}"
    execute "sudo sh ${tmp_file} --silent --toolkit --driver \
             && rm ${tmp_file}"

    print_success "cuDNN (install)"

}


configure_cudnn() {
    declare -r CONFIGS=""

    if [ ! $(grep -Fxq "${CONFIGS}" "${LOCAL_SHELL_CONFIG_FILE}") ]; then
        execute \
            "printf '%s' '${CONFIGS}' >> ${LOCAL_SHELL_CONFIG_FILE} \
                 && . ${LOCAL_SHELL_CONFIG_FILE}"
    fi

    print_success "cuDNN (configure)"

}

main () {

    # https://docs.nvidia.com/deeplearning/sdk/cudnn-install/index.html

    install_cudnn

    configure_cudnn

}

main
