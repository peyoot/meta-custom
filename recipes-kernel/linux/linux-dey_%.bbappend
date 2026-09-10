# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# 定义内核配置片段用 .config 后缀走"第二轮合并"（KERNEL_CONFIG_FRAGMENTS），从而排在 Digi 官方 RT 基线之后生效。
SRC_URI += " \
            file://fragment.config \
            file://cpufreq.config \
            "
MY_CONFIG_FRAGS = " \
    ${WORKDIR}/fragment.config \
    ${WORKDIR}/cpufreq.config \
"
KERNEL_CONFIG_FRAGMENTS:append = " ${MY_CONFIG_FRAGS}"

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

addtask verify_kernel_config after do_configure
