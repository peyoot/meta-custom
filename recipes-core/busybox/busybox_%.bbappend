# meta-custom/recipes-core/busybox/busybox_1.35.%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
    file://busybox-httpd.service.in \
    file://busybox-httpd \
    file://httpd-custom.cfg \
"

HAS_SYSTEMD = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}"

do_configure:prepend() {
    cat ${WORKDIR}/httpd-custom.cfg >> ${WORKDIR}/defconfig
}

do_install:append() {
    if grep "CONFIG_HTTPD=y" ${WORKDIR}/defconfig; then
        install -d ${D}/srv/busybox-www/cgi-bin
        install -m 0755 ${WORKDIR}/nm ${D}/srv/busybox-www/cgi-bin/
        if ${HAS_SYSTEMD}; then
            install -d ${D}${systemd_unitdir}/system
            sed 's,@sbindir@,${sbindir},g' < ${WORKDIR}/busybox-httpd.service.in \
                > ${D}${systemd_unitdir}/system/busybox-httpd.service
        else
            install -d ${D}${sysconfdir}/init.d
            install -m 0755 ${WORKDIR}/busybox-httpd ${D}${sysconfdir}/init.d/
        fi
    fi
}

# 确保所有安装的文件被包含到包中
FILES:${PN}-httpd:append = " \
    ${systemd_unitdir}/system/busybox-httpd.service \
    ${sysconfdir}/init.d/busybox-httpd \
    /srv/busybox-www \
    /srv/busybox-www/cgi-bin \
    /srv/busybox-www/cgi-bin/nm \
"

SYSTEMD_PACKAGES += "${PN}-httpd"
SYSTEMD_SERVICE:${PN}-httpd = "busybox-httpd.service"
SYSTEMD_AUTO_ENABLE:${PN}-httpd = "disable"
INITSCRIPT_PACKAGES += "${PN}-httpd"
INITSCRIPT_NAME:${PN}-httpd = "busybox-httpd"
INITSCRIPT_PARAMS:${PN}-httpd = "stop 21 0 1 6 ."
