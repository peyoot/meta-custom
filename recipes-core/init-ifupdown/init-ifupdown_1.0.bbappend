# 路径扩展（通用 + ccimx9 覆盖）
FILESEXTRAPATHS:prepend := " \
    ${THISDIR}/${BP}/ccimx9: \
    ${THISDIR}/${BP}: \
    ${COREBASE}/../meta-digi/meta-digi-dey/recipes-core/init-ifupdown/${BP}: \
"

# 通用文件（所有机型）
SRC_URI:append = " \
    file://udhcpd.conf \
    file://udhcpd.service \
"

# ccimx9 专用文件（通过 MACHINEOVERRIDES 触发）
SRC_URI:append:ccimx9 = " \
    file://ccimx9/udhcpd.conf \
    file://ccimx9/udhcpd.service \
    file://ccimx9/set-regdomain.service \
"

SYSTEMD_SERVICE:${PN} += "udhcpd.service"
SYSTEMD_SERVICE:${PN}:append:ccimx9 = " set-regdomain.service"

# 通用安装步骤（非 ccimx9 机型）
do_install:append() {
    install -m 0644 ${WORKDIR}/udhcpd.conf ${D}${sysconfdir}/
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/udhcpd.service ${D}${systemd_system_unitdir}/
}

# ccimx9 专用安装步骤（覆盖通用配置）
do_install:append:ccimx9() {
    install -m 0644 ${WORKDIR}/ccimx9/udhcpd.conf ${D}${sysconfdir}/udhcpd.conf
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ccimx9/udhcpd.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/ccimx9/set-regdomain.service ${D}${systemd_system_unitdir}/
}

