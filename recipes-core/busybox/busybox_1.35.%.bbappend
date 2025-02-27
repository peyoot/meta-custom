# meta-custom/recipes-core/busybox/busybox_1.35.%.bbappend

# 添加自定义配置文件和模板
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
    file://busybox-httpd.service.in \
    file://busybox-httpd \
    file://httpd-custom.cfg \
"

# 判断是否使用 systemd
HAS_SYSTEMD = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}"

# 合并自定义配置到 Busybox 的 defconfig
do_configure:prepend() {
    cat ${WORKDIR}/httpd-custom.cfg >> ${WORKDIR}/defconfig
}

do_install:append() {
    if grep "CONFIG_HTTPD=y" ${WORKDIR}/defconfig; then
        install -d ${D}/srv/busybox-www/cgi-bin
        install -m 0755 ${WORKDIR}/nm ${D}/srv/busybox-www/cgi-bin/
        if ${HAS_SYSTEMD}; then
            # 安装 systemd 服务（唯一名称：busybox-httpd.service）
            install -d ${D}${systemd_unitdir}/system
            sed 's,@sbindir@,${sbindir},g' < ${WORKDIR}/busybox-httpd.service.in \
                > ${D}${systemd_unitdir}/system/busybox-httpd.service
        else
            # 安装 SysVinit 脚本（唯一名称：busybox-httpd）
            install -d ${D}${sysconfdir}/init.d
            install -m 0755 ${WORKDIR}/busybox-httpd ${D}${sysconfdir}/init.d/
        fi
    fi
}

# 定义文件归属和自启动禁用
FILES:${PN}-httpd:append = " \
    ${systemd_unitdir}/system/busybox-httpd.service \
    ${sysconfdir}/init.d/busybox-httpd \
"
SYSTEMD_PACKAGES += "${PN}-httpd"
SYSTEMD_SERVICE:${PN}-httpd = "busybox-httpd.service"  # 唯一服务名称
SYSTEMD_AUTO_ENABLE:${PN}-httpd = "disable"
INITSCRIPT_PACKAGES += "${PN}-httpd"
INITSCRIPT_NAME:${PN}-httpd = "busybox-httpd"         # 唯一脚本名称
INITSCRIPT_PARAMS:${PN}-httpd = "stop 21 0 1 6 ."
