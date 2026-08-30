# meta-custom/recipes-bsp/u-boot/u-boot-dey_2023.10.bbappend
FILESEXTRAPATHS:prepend:u-boot-dey_2023.10 := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend := "${THISDIR}:${THISDIR}:"

# 添加自定义设备树仓库
SRC_URI:append = " \
    git://github.com/peyoot/ccmp25_dt;branch=scarthgap-ccmp25dvk;protocol=https;destsuffix=ccmp25_dt;name=ccmp25dt \
"

# 指定自定义设备树仓库的提交哈希
# SRCREV_ccmp25dt = "6925933fe3728d1a2d457793944989a822915f34"
SRCREV_ccmp25dt = "${AUTOREV}"

# 指定自定义设备树仓库的提交哈希
# SRCREV_ccmp25dt = "6925933fe3728d1a2d457793944989a822915f34"
SRCREV_ccmp25dt = "${AUTOREV}"

# 定义 SRCREV_FORMAT 以分离主内核仓库和自定义仓库的版本号
SRCREV_FORMAT = "default_ccmp25dt"

install_uboot_files() {
    # 复制自定义 defconfig 到 U-Boot 源码目录
    cp ${WORKDIR}/ccmp25_dt/uboot/configs/ccmp25-dvk_defconfig ${S}/configs/ccmp25-dvk_defconfig

    # 如需替换 U-Boot 设备树,取消下面注释:
    cp ${WORKDIR}/ccmp25_dt/uboot-dts/ccmp25-dvk.dts       ${S}/arch/arm/dts/ccmp25-dvk.dts
    cp ${WORKDIR}/ccmp25_dt/uboot-dts/ccmp25-dvk-u-boot.dtsi ${S}/arch/arm/dts/ccmp25-dvk-u-boot.dtsi
}

addtask install_uboot_files after do_patch before do_configure
