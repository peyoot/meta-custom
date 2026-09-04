# meta-custom/recipes-core/images/dey-image-qtros.bb
#
# Copyright (C) 2016-2024, Digi International Inc.
#
#require dey-image-graphical.inc
require recipes-core/images/dey-image-graphical.inc

DISTRO_FEATURES:append = " rt"

IMAGE_ROOTFS_MAXSIZE = "6291456"

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

BOOTFS_LABEL = "BOOT"
MKFS_VFAT_EXTRA_OPTS = "-F 32"

# 核心修复：分步复制文件，避免长命令行问题
do_image_boot_vfat:prepend() {
    bbnote "Using split mcopy to avoid long argument list"
}

do_image_boot_vfat:append() {
    # 先 mkfs（保持原有逻辑）
    # 然后替换原来的 mcopy 为分步复制
    for f in ${BOOTIMG_FILES_SYMLINK}; do
        if [ -e "$f" ]; then
            mcopy -i ${IMGDEPLOYDIR}/${IMAGE_NAME}.boot.vfat -s "$f" ::/ || \
            bbwarn "Failed to copy $f to boot image"
        fi
    done

    # boot.scr 也单独处理
    for item in ${BOOT_SCRIPTS}; do
        src=`echo $item | awk -F':' '{ print $1 }'`
        dst=`echo $item | awk -F':' '{ print $2 }'`
        mcopy -i ${IMGDEPLOYDIR}/${IMAGE_NAME}.boot.vfat -s ${DEPLOY_DIR_IMAGE}/$src ::/$dst || true
    done
}

# 移除 kernel-image 的全局 exclude，允许 kernel 包进入 rootfs
PACKAGE_EXCLUDE:remove = "kernel-image-*"

# 确保 kernel 被安装
IMAGE_INSTALL:append = " kernel-image-image.gz"