# meta-custom/recipes-core/images/dey-image-qt_%.bbappend
# add ccmp25plc device tree files
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk:append = " ccmp25-plc.dtb ccmp25-plc_pwm_do1_2.dtbo ccmp25-plc_fix_eth2_100m.dtbo ccmp25-plc_eth3.dtbo"

# 移除Wayland相关特性，避免X11冲突
# 注意下面这些DISTRO_FEATURES需要在local.conf中配置
MACHINE_DISTRO_FEATURES_REMOVE:remove = "x11"
DISTRO_FEATURES:append = " x11"
DISTRO_FEATURES:remove = "wayland"
CONFLICT_DISTRO_FEATURES:remove = "wayland"

# 继续从回填排除列表中移除 x11
DISTRO_FEATURES_BACKFILL_CONSIDERED:remove = "x11"

CONFLICT_DISTRO_FEATURES:remove = "wayland"


# 调整镜像安装包：移除Wayland组件，添加Xvfb及必要依赖
IMAGE_INSTALL:remove = "weston"
IMAGE_INSTALL:remove = "weston-xwayland" 
IMAGE_INSTALL:append = " \
    qt5everywheredemo \
    xserver-xorg \
    x11vnc \
    xdpyinfo \
    xauth \
    libx11 \
    libxcb \
    mesa-megadriver \
"

# 如果不需要Qt的Wayland支持，可以移除qtwayland，但这需要测试
# IMAGE_INSTALL:remove = "qtwayland"

# 清理为Wayland特制的快捷方式
ROOTFS_POSTPROCESS_COMMAND:remove = "add_cinematicexperience_shortcut;"