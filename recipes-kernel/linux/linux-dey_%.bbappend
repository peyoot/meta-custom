# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

# 指定文件搜索路径
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# 添加本地文件到 SRC_URI
SRC_URI:append = " file://ccmp25-plc.dts"


# 追加 do_unpack 任务以安装自定义 DTS 文件
do_unpack:append() {
    bb.build.exec_func('install_dts', d)
}

# 定义一个 Python 函数来执行安装命令
python install_dts() {
    import os
    import subprocess

    dts_src = os.path.join(d.getVar('WORKDIR', True), 'ccmp25-plc.dts')
    dts_dest = os.path.join(d.getVar('KERNEL_SRC', True), 'arch/arm64/boot/dts/digi/ccmp25-plc.dts')

    subprocess.run(['install', '-D', '-m', '644', dts_src, dts_dest], check=True)
}


# 为 ccmp25-dvk 机器添加自定义设备树二进制文件
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk += " ccmp25-plc.dtb"

