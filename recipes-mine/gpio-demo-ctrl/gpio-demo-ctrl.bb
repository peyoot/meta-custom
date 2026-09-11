SUMMARY = "GPIO Demo Control service configuration"
DESCRIPTION = "Custom gpio guard service configuration for demo application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://gpio_demo_ctrl.sh \
    file://gpio_demo_ctrl.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "gpio_demo_ctrl.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # 安装服务脚本
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/gpio_demo_ctrl.sh ${D}${bindir}/gpio_demo_ctrl.sh

    # 安装systemd服务文件
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/gpio_demo_ctrl.service ${D}${systemd_system_unitdir}
}

FILES:${PN} = " \
    ${bindir}/gpio_demo_ctrl.sh \
    ${systemd_system_unitdir}/gpio_demo_ctrl.service \
"
