# meta-custom/recipes-bsp/u-boot/u-boot-dey_2022.10.bbappend

# 指定 Git 仓库和分支
SRC_URI:append = " git://github.com/peyoot/ccmp25_dt.git;protocol=https;branch=dualeth-s"

# 指定 Git 仓库的修订版本
# 如果你有特定的提交哈希，可以在这里指定，例如：SRCREV = "abc123def456"
# 如果使用分支，可以设置为 "branch=<branch_name>,commit=<commit_hash>"
SRCREV_ccmp25_dt = "${AUTOREV}"

# 在编译前替换设备树文件和配置文件
do_patch() {
    # 从 Git 仓库中复制设备树文件到 U-Boot 源码目录
    cp ${WORKDIR}/ccmp25_dt/uboot-dts/ccmp25-dvk.dts ${S}/arch/arm/dts/ccmp25-dvk.dts
    cp ${WORKDIR}/ccmp25_dt/uboot-dts/ccmp25-dvk-u-boot.dtsi ${S}/arch/arm/dts/ccmp25-dvk-u-boot.dtsi

    # 从 Git 仓库中复制配置文件到 U-Boot 源码目录
    cp ${WORKDIR}/ccmp25_dt/uboot/configs/ccmp25-dvk_defconfig ${S}/configs/ccmp25-dvk_defconfig
}
