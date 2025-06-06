# 路径扩展（通用 + ccimx9 覆盖）
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# ccimx9 专用文件（通过 MACHINEOVERRIDES 触发）
SRC_URI:append:ccimx9 = " \
    file://hostapd_uap0.conf \
"

SRC_URI:append:stm32mpcommon =  " \
    file://stm32mpcommon/defconfig  \
    file://hostapd_wlan1.conf \
"

do_configure:append:stm32mpcommon() {
    bbnote "Using custom defconfig from ${WORKDIR}/stm32mpcommon/defconfig"
    install -m 0644 ${WORKDIR}/stm32mpcommon/defconfig ${S}/hostapd/.config 
}

# 通用安装步骤（非 ccimx9 机型）
do_install:append() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/hostapd_wlan1.conf ${D}${sysconfdir}/hostapd_wlan1.conf
}

# ccimx9 专用安装步骤（覆盖通用配置）
do_install:append:ccimx9() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/hostapd_uap0.conf ${D}${sysconfdir}/hostapd_uap0.conf
}