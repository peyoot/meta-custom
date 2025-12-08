SUMMARY = "MJPG-Streamer service configuration"
DESCRIPTION = "Custom service configuration for MJPG-Streamer with USB camera support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://http_camera_demo.sh \
    file://mjpg_streamer.service \
"

DEPENDS = "mjpg-streamer"

inherit systemd

SYSTEMD_SERVICE:${PN} = "mjpg_streamer.service"
SYSTEMD_AUTO_ENABLE = "disable"

do_install() {
    # 安装服务脚本
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/http_camera_demo.sh ${D}${bindir}/http_camera_demo

    # 安装systemd服务文件
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/mjpg_streamer.service ${D}${systemd_system_unitdir}
}

FILES:${PN} = " \
    ${bindir}/http_camera_demo \
    ${systemd_system_unitdir}/mjpg_streamer.service \
"

RDEPENDS:${PN} = " \
    mjpg-streamer \
    v4l-utils \
    bash \
"
