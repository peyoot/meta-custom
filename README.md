# meta-custom

Digi Embedded custom layer
==========================

This meta-layer is designed to create a pre-configured rootfs
with the necessary typical files used in a CC6UL project for
demos by the FAE.

To Do List: 
Also it does change the DT files to configure the I/O correctly.

Platform
--------
CC6UL SBC PRO

Requirements
------------
DEY 5.0

Version
-------
这个版本成功编译为X11，并支持Xvfb，但实际可能并没有什么用，它可以配合dey5.0r2.2来编译。
tag标记为ccmp25plc-x11

local.conf配置为：

# 覆盖机器配置中的移除设置
MACHINE_DISTRO_FEATURES_REMOVE:remove = "x11"

# 确保添加 x11 特性
DISTRO_FEATURES:append = " fbdev x11 opengl gles2"

# 移除 wayland（如果需要）
DISTRO_FEATURES:remove = "wayland"
CONFLICT_DISTRO_FEATURES:remove = "wayland"

# 继续从回填排除列表中移除 x11
DISTRO_FEATURES_BACKFILL_CONSIDERED:remove = "x11"


DISTRO_FEATURES:append = " rt"


# add examples
IMAGE_INSTALL:append = " \
    qt5everywheredemo \
    xauth \
    xserver-xorg \
    x11vnc \
    libx11 \
    libxcb \
    libglu \
"

# 确保 xserver-xorg 在构建时包含 xvfb
PACKAGECONFIG:append:pn-xserver-xorg = " xvfb"

