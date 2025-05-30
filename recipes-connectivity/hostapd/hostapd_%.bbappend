# 路径扩展（通用 + ccimx9 覆盖）
FILESEXTRAPATHS:prepend := "${THISDIR}/${BP}:"

# 通用文件（所有机型）
SRC_URI:append = " \
    file://acs-hostapd_wlan1.conf \
"

# ccimx9 专用文件（通过 MACHINEOVERRIDES 触发）
SRC_URI:append:ccimx9 = " \
    file://acs-hostapd_uap0.conf \
"

# 通用安装步骤（非 ccimx9 机型）
do_install:append() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/acs-hostapd_wlan1.conf ${D}${sysconfdir}/hostapd_wlan1.conf
}

# ccimx9 专用安装步骤（覆盖通用配置）
do_install:append:ccimx9() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/acs-hostapd_uap0.conf ${D}${sysconfdir}/hostapd_uap0.conf
}