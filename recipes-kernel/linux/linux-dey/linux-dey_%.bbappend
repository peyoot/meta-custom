# 扩展文件搜索路径
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# 添加自定义设备树仓库
SRC_URI += " \
    git://github.com/peyoot/ccmp25_dt;branch=dualeth-s;protocol=https;destsuffix=git/ccmp25_dt;name=ccmp25dt \
"

# 指定仓库的提交哈希（替换为实际值）
SRCREV_ccmp25dt = "c932586c9aa024c6e621c62656032b4acf4b2bdc"

# 在解压阶段复制设备树文件到内核源码树
do_unpack:append() {
    cp ${WORKDIR}/git/ccmp25_dt/ccmp25-plc.dts ${S}/arch/arm64/dts/digi/
}

# 确保设备树被编译
KERNEL_DEVICETREE:append = " ccmp25-plc.dtb"
