# meta-custom/recipes-core/images/core-image-base.bbappend
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk:append = " ccmp25-viena.dtb ccmp25-viena_ads7846.dtbo"

require recipes-core/images/core-image-base.bbappend

INHERIT:remove = "dey-swupdate dey-swupdate-common"

IMAGE_INSTALL:remove = "swupdate swupdate-tools swupdate-config swupdate-progress swupdate-web swupdate-update"

DEY_SWUPDATE = "0"

SYSTEMD_AUTO_ENABLE:pn-swupdate = "disable"
SYSTEMD_AUTO_ENABLE:pn-swupdate-tools = "disable"

ROOTFS_POSTPROCESS_COMMAND:append = " remove_swupdate_artifacts; "
remove_swupdate_artifacts() {
    echo "Removing any remaining swupdate components..."
    rm -f ${IMAGE_ROOTFS}${bindir}/swupdate* || true
    rm -f ${IMAGE_ROOTFS}${sysconfdir}/systemd/system/swupdate*.service || true
    rm -f ${IMAGE_ROOTFS}${systemd_unitdir}/system/swupdate*.service || true
    rm -rf ${IMAGE_ROOTFS}${sysconfdir}/swupdate || true
}