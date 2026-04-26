SUMMARY = "dual display auto turn off lvds"
DESCRIPTION = "Custom service to turn off lvds backlight when HDMI available"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://dualdisplay_bl_ctl.service \
    file://dualdisplay_bl_ctl.sh \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "dualdisplay_bl_ctl.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # 安装服务脚本
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/dualdisplay_bl_ctl.sh ${D}${bindir}/dualdisplay_bl_ctl.sh

    # 安装systemd服务文件
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/dualdisplay_bl_ctl.service ${D}${systemd_system_unitdir}
}

FILES:${PN} = " \
    ${bindir}/dualdisplay_bl_ctl.sh \
    ${systemd_system_unitdir}/dualdisplay_bl_ctl.service \
"
