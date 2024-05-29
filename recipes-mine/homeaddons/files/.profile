# /etc/profile

# Check for ROS environment and source the setup script based on the shell type
if [ -d /etc/profile.d/ros/ ]; then
    # Check for bash shell
    if [ -n "$BASH_VERSION" ]; then
        . /etc/profile.d/ros/setup.bash
    # Check for zsh shell
    elif [ -n "$ZSH_VERSION" ]; then
        . /etc/profile.d/ros/setup.zsh
    # Check for other shells (e.g., sh)
    else
        . /etc/profile.d/ros/setup.sh
    fi
fi


export QMLSCENE_DEVICE="softwarecontext"
