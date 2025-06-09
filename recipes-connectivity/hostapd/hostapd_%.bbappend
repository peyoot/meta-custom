# 路径扩展（通用 + ccimx9 覆盖）
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# ccimx9 专用文件（通过 MACHINEOVERRIDES 触发）
SRC_URI:append:ccimx9 = " \
    file://hostapd_uap0.conf \
"

SRC_URI:append:stm32mpcommon =  " \
    file://stm32mpcommon/defconfig  \
    file://stm32mpcommon/hostapd_wlan1.conf \
"

do_configure:append:stm32mpcommon() {
    bbnote "Using custom defconfig from ${WORKDIR}/stm32mpcommon/defconfig"
    install -m 0644 ${WORKDIR}/stm32mpcommon/defconfig ${S}/hostapd/.config 
}
