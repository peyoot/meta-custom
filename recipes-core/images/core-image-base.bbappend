DISTRO_FEATURES:append = " rt"


inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

#IMAGE_INSTALL:append = " \
#    packagegroup-ros-world \
#"

# GLIBC_GENERATE_LOCALES = "zh_CN.UTF-8 en_GB.UTF-8 en_US.UTF-8" 
# IMAGE_LINGUAS = "en-us"
# LOCALE_UTF8_ONLY="1"

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