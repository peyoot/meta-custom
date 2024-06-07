#!/bin/sh
export QT_QPA_PLATFORM="wayland"

[ -f "/etc/profile.d/weston.sh" ] || [ -f "/etc/profile.d/weston-socket.sh" ] && return


export QT_QPA_PLATFORM="xcb"

# Use EGLFS platform plugin for images without XWayland and X11
[ -f "/etc/xserver-nodm/Xserver" ] || export QT_QPA_PLATFORM="eglfs" QT_QPA_EGLFS_INTEGRATION="eglfs_viv"

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
