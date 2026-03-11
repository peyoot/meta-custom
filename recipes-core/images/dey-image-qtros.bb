# meta-custom/recipes-core/images/dey-image-qtros.bb
# add ccmp25plc device tree files

#
# Copyright (C) 2016-2024, Digi International Inc.
#
#require dey-image-graphical.inc
require recipes-core/images/dey-image-graphical.inc

#
# Create QT5/6 capable toolchain/SDK
#
inherit qt-version
inherit ${QT_POPULATE_SDK}

DESCRIPTION = "DEY image with QT graphical libraries"

GRAPHICAL_CORE = "qt"

add_cinematicexperience_shortcut() {
	if [ -f ${IMAGE_ROOTFS}${datadir}/icons/hicolor/24x24/icon_qt.png ] && [ -f ${IMAGE_ROOTFS}${sysconfdir}/xdg/weston/weston.ini ]; then
		printf "\n[launcher]\nicon=${datadir}/icons/hicolor/24x24/icon_qt.png\npath=${bindir}/cinematic-experience\n" >> ${IMAGE_ROOTFS}${sysconfdir}/xdg/weston/weston.ini
	fi
}
ROOTFS_POSTPROCESS_COMMAND:append:imxgpu = " add_cinematicexperience_shortcut"
ROOTFS_POSTPROCESS_COMMAND:append:ccmp15 = " add_cinematicexperience_shortcut"
ROOTFS_POSTPROCESS_COMMAND:append:ccimx93 = " add_cinematicexperience_shortcut"

STM32MP_KERNEL_DEVICETREE:ccmp25-dvk:append = " ccmp25-plc.dtb ccmp25-plc_pwm_do1_2.dtbo ccmp25-plc_fix_eth2_100m.dtbo ccmp25-plc_eth3.dtbo"


inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

#IMAGE_INSTALL:append = " \
#    packagegroup-ros-world \
#"
GLIBC_GENERATE_LOCALES = "zh_CN.UTF-8 en_GB.UTF-8 en_US.UTF-8" 
IMAGE_LINGUAS = "en-us"
LOCALE_UTF8_ONLY="1"

IMAGE_INSTALL:append = " \
    ros-core \
    packagegroup-ros2-demos \
"