
# 设置 SRCREV_FORMAT 为 git
SRCREV_FORMAT_linux = "git"
SRCREV_FORMAT_ccmp25dt = "git"

# 添加新的设备树文件
SRC_URI += " \
    git://github.com/peyoot/ccmp25_dt;branch=dualeth-s;protocol=https;destsuffix=git/ccmp25_dt;name=ccmp25dt \
"

# 指定仓库的提交哈希（替换为实际值）
SRCREV_ccmp25dt = "c932586c9aa024c6e621c62656032b4acf4b2bdc"

# 在 do_unpack 阶段将设备树文件复制到内核源码树
do_unpack:append() {
    # 将设备树文件从下载的源码目录复制到内核源码树的目标目录
    install -D -m 644 ${WORKDIR}/git/ccmp25_dt/ccmp25_plc.dts ${KERNEL_SRC}/arch/arm64/boot/dts/digi/ccmp25-plc.dts
}

# 添加设备树文件到编译列表
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk += " ccmp25-plc.dtb"

