# meta-custom/recipes-bsp/u-boot/u-boot-dey_2022.10.bbappend

# 添加自定义设备树仓库
SRC_URI:append = " \
    git://github.com/peyoot/ccmp25_dt;branch=dualeth-s;protocol=https;destsuffix=ccmp25_dt;name=ccmp25dt \
"

# 指定自定义设备树仓库的提交哈希
# SRCREV_ccmp25dt = "c932586c9aa024c6e621c62656032b4acf4b2bdc"
SRCREV_ccmp25dt = "${AUTOREV}"

# 定义 SRCREV_FORMAT 以分离主内核仓库和自定义仓库的版本号
SRCREV_FORMAT = "default_ccmp25dt"


# 在编译前替换设备树文件和配置文件
do_patch() {
    # 从 Git 仓库中复制设备树文件到 U-Boot 源码目录
    cp ${WORKDIR}/ccmp25_dt/uboot-dts/ccmp25-dvk.dts ${S}/arch/arm/dts/ccmp25-dvk.dts
    cp ${WORKDIR}/ccmp25_dt/uboot-dts/ccmp25-dvk-u-boot.dtsi ${S}/arch/arm/dts/ccmp25-dvk-u-boot.dtsi

    # 从 Git 仓库中复制配置文件到 U-Boot 源码目录
    cp ${WORKDIR}/ccmp25_dt/uboot/configs/ccmp25-dvk_defconfig ${S}/configs/ccmp25-dvk_defconfig
}
