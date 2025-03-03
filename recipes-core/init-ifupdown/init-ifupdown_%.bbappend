# 关键路径修正
FILESEXTRAPATHS:prepend := "${THISDIR}/init-ifupdown-1.0:"

# 安全追加文件
SRC_URI:append = " \
    file://udhcpd.conf \
    file://udhcpd.service \
"

# 继承 systemd 特性
inherit systemd

# 添加 systemd 服务
SYSTEMD_SERVICE:${PN} += "udhcpd.service"

do_install:append() {
    # 安装 udhcpd 配置文件
    install -m 0644 ${WORKDIR}/udhcpd.conf ${D}${sysconfdir}/

    # 安装 systemd 服务单元
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/udhcpd.service ${D}${systemd_system_unitdir}/
}
