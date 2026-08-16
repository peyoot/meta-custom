# Copyright (C) 2018 Digi International Inc.
SUMMARY = "Home Addons" 
DESCRIPTION = "Adding optional files to homedir" 
LICENSE = "CLOSED" 
FILESEXTRAPATHS:prepend := "${THISDIR}/files:" 
RPROVIDES:${PN} += "${PN}" 
SRC_URI = "file://.profile \
        file://.localconf \
        file://gpio_ctrl.sh \
        file://gpio_guard.service \
        file://readme.txt"
# Specify where to get the files
S = "${WORKDIR}" 
do_configure[noexec] = "1" 
do_compile[noexec] = "1" 

inherit systemd

SYSTEMD_SERVICE:${PN} = "gpio_guard.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
        # creating the destination directories
        install -d ${D}/root

        # extra files need to go in the respective directories
        install -m 0644 ${WORKDIR}/.profile ${D}/root/
        install -m 0644 ${WORKDIR}/readme.txt ${D}/root/
        install -m 0755 ${WORKDIR}/.localconf ${D}/root/

        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/gpio_ctrl.sh ${D}${bindir}/gpio_ctrl.sh

        # 安装systemd服务文件
        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/gpio_guard.service ${D}${systemd_system_unitdir}

}

FILES:${PN} += "/root/* \
        /root/.localconf \
        /root/.profile \
        ${bindir}/gpio_ctrl.sh \
        ${systemd_system_unitdir}/gpio_guard.service \
        "
