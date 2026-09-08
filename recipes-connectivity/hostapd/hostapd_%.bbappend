FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# 内容随 MACHINE 变化，dey-aio 跨项目共享 sstate 时建议显式声明
PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI:append:stm32mpcommon = " file://hostapd_wlan1-wifi6.conf"

do_install:append:stm32mpcommon() {
    install -m 0644 ${WORKDIR}/hostapd_wlan1-wifi6.conf ${D}${sysconfdir}/
}