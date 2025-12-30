SUMMARY = "touch calibration service configuration"
DESCRIPTION = "Custom service configuration for touch screen calibration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://touch_calibration.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "touch_calibration.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {

    # 安装systemd服务文件
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/touch_calibration.service ${D}${systemd_system_unitdir}
}

FILES:${PN} = " \
    ${systemd_system_unitdir}/touch_calibration.service \
"
