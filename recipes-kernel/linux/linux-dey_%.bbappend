# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

# 指定文件搜索路径
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# 添加本地文件到 SRC_URI
SRC_URI:append = " file://ccmp25-plc.dts"

# 追加 do_unpack 任务以安装自定义 DTS 文件
do_unpack:append() {
    install -D -m 644 ${WORKDIR}/ccmp25-plc.dts ${KERNEL_SRC}/arch/arm64/boot/dts/digi/ccmp25-plc.dts
}

# 为 ccmp25-dvk 机器添加自定义设备树二进制文件
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk += " ccmp25-plc.dtb"

