# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://fragment.cfg \
            file://cpufreq.cfg \
            file://ads7846-v6.11.c \
            "

# 添加自定义设备树仓库
SRC_URI:append = " \
    git://github.com/peyoot/ccmp25_dt;branch=ccmp25-viena;protocol=https;destsuffix=ccmp25_dt;name=ccmp25dt \
"

# 指定自定义设备树仓库的提交哈希
# SRCREV_ccmp25dt = "6925933fe3728d1a2d457793944989a822915f34"
SRCREV_ccmp25dt =  "${AUTOREV}"

# 定义 SRCREV_FORMAT 以分离主内核仓库和自定义仓库的版本号
SRCREV_FORMAT = "default_ccmp25dt" 

# 确保配置片段被应用
#do_configure:append() {
#    if [ -f ${WORKDIR}/fragment.cfg ]; then
#        cat ${WORKDIR}/fragment.cfg >> ${B}/.config
#    fi
#}

do_compile:prepend() {
    # 将YOCTO工作目录中的ads7846.c复制到内核源码的对应目录
    cp ${WORKDIR}/ads7846-v6.11.c ${S}/drivers/input/touchscreen/ads7846.c
}

DT_FILES = " \
    ccmp25-viena.dts \
    ccmp25-viena-rt.dts \
    ccmp25-viena-hdmi.dts \
    ccmp25-viena-hdmi-rmpd2.dts \
    ccmp25-viena-ddisplay.dts \
    ccmp25-viena-ddisplay-rmpd2.dts \
    ccmp25-viena-dualdisplay.dts \
    ccmp25-viena_ads7846.dtso \
    ccmp25-viena_hdmi.dtso \
    ccmp25-viena_dualdisplay.dtso \
"

# 定义一个 Python 函数来执行安装命令
python do_install_dts() {
    import os
    import subprocess

    workdir = d.getVar('WORKDIR', True)
    kernel_src = d.getVar('S', True)
    dest_dir = os.path.join(kernel_src, 'arch/arm64/boot/dts/digi')

    for filename in d.getVar('DT_FILES', True).split():
        src = os.path.join(workdir, 'ccmp25_dt', filename)
        dest = os.path.join(dest_dir, filename)
        
        # 创建目标目录并安装文件
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        subprocess.run(['install', '-D', '-m', '644', src, dest], check=True)

}

addtask do_install_dts after do_patch before do_configure

# 为 ccmp25-dvk机器添加设备树和 overlay
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk += " \
    ccmp25-viena.dtb \
    ccmp25-viena-rt.dtb \
    ccmp25-viena-hdmi.dtb \
    ccmp25-viena-hdmi-rmpd2.dtb \
    ccmp25-viena-ddisplay.dtb \
    ccmp25-viena-ddisplay-rmpd2.dtb \
    ccmp25-viena-dualdisplay.dtb \
    ccmp25-viena_ads7846.dtbo \
    ccmp25-viena_hdmi.dtbo \
    ccmp25-viena_dualdisplay.dtbo \
"

do_install:prepend:ccmp2() {
#    echo "KERNEL_DEVICETREE: ${KERNEL_DEVICETREE}"  and check log when perform bitbake -D -v linux-dey
    echo "KERNEL_DEVICETREE: ${KERNEL_DEVICETREE}"
    if [ -d "${B}/arch/${ARCH}/boot/dts/digi" ]; then
        for dtbf in ${KERNEL_DEVICETREE}; do
            install -m 0644 "${B}/arch/${ARCH}/boot/dts/digi/${dtbf}" "${B}/arch/${ARCH}/boot/dts/"
        done
    fi
}

