# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://fragment.config \
            file://cpufreq.config \
            "
MY_CONFIG_FRAGS = " \
    ${WORKDIR}/fragment.config \
    ${WORKDIR}/cpufreq.config \
"
KERNEL_CONFIG_FRAGMENTS:append = " ${MY_CONFIG_FRAGS}"

# 检查自定义的内核配置是否与RT冲突，默认只出警告，bbwarn 换成 bbfatal 即可阻止编译
do_configure:prepend() {
    if [ -n "${RT_CONFIG_FRAGS}" ]; then
        cp ${B}/.config ${WORKDIR}/.config.conflict-check
        if ! ${S}/scripts/kconfig/merge_config.sh -m -s -O ${WORKDIR} \
                ${WORKDIR}/.config.conflict-check ${RT_CONFIG_FRAGS} ${MY_CONFIG_FRAGS} \
                > ${WORKDIR}/kconfig-conflict-check.log 2>&1; then
            bbwarn "内核 config fragment 冲突详情见: ${WORKDIR}/kconfig-conflict-check.log"
        fi
    fi
}