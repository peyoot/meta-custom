# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

# 添加自定义设备树仓库
SRC_URI:append = " \
    git://github.com/peyoot/ccmp25_dt;branch=dualeth-s;protocol=https;destsuffix=ccmp25_dt;name=ccmp25dt \
"

# 指定自定义设备树仓库的提交哈希
SRCREV_ccmp25dt = "c932586c9aa024c6e621c62656032b4acf4b2bdc"

# 定义 SRCREV_FORMAT 以分离主内核仓库和自定义仓库的版本号
SRCREV_FORMAT = "default_ccmp25dt" 

# 追加 do_patch 任务以安装自定义 DTS 文件
do_patch:append() {
    bb.build.exec_func('install_dts', d)
}

# 定义一个 Python 函数来执行安装命令
python install_dts() {
    import os
    import subprocess

    dts_src = os.path.join(d.getVar('WORKDIR', True), 'ccmp25-plc.dts')
    kernel_src = d.getVar('S', True)  # 使用 S 变量来获取内核源码路径
    dts_dest = os.path.join(kernel_src, 'arch/arm64/boot/dts/digi/ccmp25-plc.dts')

    subprocess.run(['install', '-D', '-m', '644', dts_src, dts_dest], check=True)
}


# 为 ccmp25-dvk 机器添加自定义设备树二进制文件
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk += " ccmp25-plc.dtb"

