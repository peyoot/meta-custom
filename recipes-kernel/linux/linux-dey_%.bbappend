# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-add-ch343-usb-serial-driver.patch \
    file://fragment.config \
    file://cpufreq.config \
    file://ch343.config \
"
MY_CONFIG_FRAGS = " \
    ${WORKDIR}/fragment.config \
    ${WORKDIR}/cpufreq.config \
    ${WORKDIR}/ch343.config \
"
# 定义内核配置片段用 .config 后缀走"第二轮合并"（KERNEL_CONFIG_FRAGMENTS），从而排在 Digi 官方 RT 基线之后生效。
KERNEL_CONFIG_FRAGMENTS:append = " ${MY_CONFIG_FRAGS}"

# 添加自定义设备树仓库
SRC_URI:append = " \
    git://github.com/peyoot/ccmp25_dt;branch=ccmp25plc;protocol=https;destsuffix=ccmp25_dt;name=ccmp25dt \
"

# 指定自定义设备树仓库的提交哈希
# SRCREV_ccmp25dt = "6925933fe3728d1a2d457793944989a822915f34"
SRCREV_ccmp25dt =  "${AUTOREV}"

# 定义 SRCREV_FORMAT 以分离主内核仓库和自定义仓库的版本号
SRCREV_FORMAT = "default_ccmp25dt" 

DT_FILES = " \
    ccmp25-plc.dts \
    ccmp25-plc_pwm_do1_2.dtso \
    ccmp25-plc_eth3.dtso \
    ccmp25-plc_fix_eth2_100m.dtso \
"

# 校验任务：对比"纯官方基线"（defconfig + Digi 自己的 .cfg + Digi 官方 RT_CONFIG_FRAGS）
# 和"最终实际生效的 .config"（含我们自己的 fragment）之间的差异。确认自定义选项有没有真正生效、以及有没有
# 意外带崩别的依赖项（比如关掉 CFG80211 顺带影响 MAC80211 这种级联效果）。
# ---------------------------------------------------------------------------
do_verify_kernel_config() {
    OFFICIAL_DIR="${WORKDIR}/kconfig-official-check"
    rm -rf "${OFFICIAL_DIR}"
    mkdir -p "${OFFICIAL_DIR}"
    # 第 0 层：跟正式流程用同一份 defconfig 起手（do_copy_defconfig 已经放好了）
    cp -f "${WORKDIR}/defconfig" "${OFFICIAL_DIR}/.config"
    oe_runmake -C ${S} O="${OFFICIAL_DIR}" olddefconfig

    # 第一轮合并：Digi 自己的 .cfg（此时我们自己的三个文件因为是 .config 后缀，不会被扫进来）
    if [ -n "${@' '.join(find_cfgs(d))}" ]; then
        ${S}/scripts/kconfig/merge_config.sh -m -O "${OFFICIAL_DIR}" \
            "${OFFICIAL_DIR}/.config" ${@" ".join(find_cfgs(d))}
    fi

    # 第二轮合并：只用官方 RT_CONFIG_FRAGS，不掺我们自己的 MY_CONFIG_FRAGS
    if [ -n "${RT_CONFIG_FRAGS}" ]; then
        ${S}/scripts/kconfig/merge_config.sh -m -O "${OFFICIAL_DIR}" \
            "${OFFICIAL_DIR}/.config" ${RT_CONFIG_FRAGS}
    fi
    
    # 解析依赖级联，得到"纯官方"最终态
    oe_runmake -C ${S} O="${OFFICIAL_DIR}" olddefconfig

    # 真正的 .config（已含自定义 fragment）同样解析一次依赖，用副本，不碰 ${B}
    MINE_DIR="${WORKDIR}/kconfig-mine-check"
    rm -rf "${MINE_DIR}"
    mkdir -p "${MINE_DIR}"
    cp ${B}/.config "${MINE_DIR}/.config"
    oe_runmake -C ${S} O="${MINE_DIR}" olddefconfig

    diff -u "${OFFICIAL_DIR}/.config" "${MINE_DIR}/.config" \
        > ${WORKDIR}/kconfig-diff-vs-official.txt || true

    if [ -s ${WORKDIR}/kconfig-diff-vs-official.txt ]; then
        bbnote "自定义内核配置相对 Digi 官方基线的差异（预期内，仅供核对生效情况）: ${WORKDIR}/kconfig-diff-vs-official.txt"
    else
        bbnote "自定义 fragment 未产生任何实际差异，请检查是否真的生效"
    fi
}

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

# 添加内核设备树合并后单独检查任务，不作为标准任务
addtask verify_kernel_config after do_configure

# 只想看差异时，用
# bitbake -c verify_kernel_config -f linux-dey
# cat tmp/work/*/linux-dey/*/kconfig-diff-vs-official.txt

# 拷入自定义设备树
addtask do_install_dts after do_patch before do_configure

# 为 ccmp25-dvk机器添加设备树和 overlay
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk += " \
    ccmp25-plc.dtb \
    ccmp25-plc_pwm_do1_2.dtbo \
    ccmp25-plc_eth3.dtbo \
    ccmp25-plc_fix_eth2_100m.dtbo \
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

