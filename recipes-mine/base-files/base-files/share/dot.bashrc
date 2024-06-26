# ~/.bashrc: executed by bash(1) for non-login shells.

export PS1='\h:\w\$ '
umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
# export LS_OPTIONS='--color=auto'
# eval `dircolors`
# alias ls='ls $LS_OPTIONS'
# alias ll='ls $LS_OPTIONS -l'
# alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

# /etc/profile

# Check for ROS environment and source the setup script based on the shell type
#if [ -d /etc/profile.d/ros/ ]; then
#    # Check for bash shell
#    if [ -n "$BASH_VERSION" ]; then
#        . /etc/profile.d/ros/setup.bash
#    # Check for zsh shell
#    elif [ -n "$ZSH_VERSION" ]; then
#        . /etc/profile.d/ros/setup.zsh
#    # Check for other shells (e.g., sh)
#    else
#        . /etc/profile.d/ros/setup.sh
#    fi
#fi

#export QT_QPA_PLATFORM="wayland"
#export QMLSCENE_DEVICE="softwarecontext"
