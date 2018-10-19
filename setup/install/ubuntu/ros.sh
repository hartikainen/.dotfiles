#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

declare -r LOCAL_SHELL_CONFIG_FILE="$HOME/.bash.local"
declare -r ROS_GPG_URL="https://download.ros.com/linux/ubuntu/gpg"
declare -r ROS_CONDA_ENV="ros"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

setup_repository() {

    # http://wiki.ros.org/kinetic/Installation/Ubuntu#Installation.2BAC8-Ubuntu.2BAC8-Sources.Configure_your_Ubuntu_repositories

    print_error "TODO(ros.sh): This might be unsafe. Check the fingerprint."

    execute "sudo apt-get update \
             && sudo apt-get install \
                    apt-transport-https \
                    ca-certificates \
                    curl \
                    software-properties-common \
             && echo \"deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main\" \
                 > /etc/apt/sources.list.d/ros-latest.list \
             && sudo apt-key adv \
                 --keyserver hkp://ha.pool.sks-keyservers.net:80 \
                 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116" \
            "Ros (setup repository)"

}

install_ros() {

    # http://wiki.ros.org/kinetic/Installation/Ubuntu#Installation-1

    execute "sudo apt-get update \
             && sudo apt-get install ros-kinetic-desktop-full" \
            "Ros (install)"

}

update_ros() {

    print_error "Ros update not implemented yet!"

    print_success "Ros (update)"

}

post_install_steps() {

    # http://wiki.ros.org/kinetic/Installation/Ubuntu#Initialize_rosdep

    source_setup_command="source /opt/ros/kinetic/setup.bash"


    $(source_setup_command)



    execute "sudo rosdep init \
             && rosdep update" \
            "Ros (initialize rosdep)"

    if [ ! grep -Fxq "${source_setup_command}" ${LOCAL_SHELL_CONFIG_FILE} ]; then
        execute "printf '%s' '${source_setup_command}' >> ${LOCAL_SHELL_CONFIG_FILE}"
    fi

    execute "${source_setup_command}"

    execute \
        "sudo apt-get install -y \
             python-rosinstall \
             python-rosinstall-generator \
             python-wstool \
             build-essential"

    execute \
        "source activate ${ROS_CONDA_ENV} \
         [ $? -neq 0 ] && conda env create -y -n ${ROS_CONDA_ENV} python=2.7
         source activate ${ROS_CONDA_ENV}"

    print_success "Ros (post installation steps)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    echo "TODO: Figure this out"

    if [[ "true" = "true" || ! "command -v docker >/dev/null 2>&1" ]]; then
        setup_repository
        install_ros
        post_install_steps
    else
        setup_repository
        update_ros
        post_install_steps
    fi

}

main
