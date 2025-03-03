# 文件路径扩展
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# 追加新的源码文件
SRC_URI += " \
    file://udhcpd.conf \
    file://udhcpd.service \
"

# 声明新的systemd服务
SYSTEMD_SERVICE:${PN} += "udhcpd.service"

do_install:append() {
    # 安装udhcpd配置文件
    install -m 0644 ${WORKDIR}/udhcpd.conf ${D}${sysconfdir}/udhcpd.conf

    # 安装systemd服务
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/udhcpd.service ${D}${systemd_system_unitdir}/
}
