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
do_configure:append() {
    if grep -q "redefined by fragment" ${T}/log.do_configure 2>/dev/null; then
        bbwarn "检测到内核 config fragment 冲突，请查看: ${T}/log.do_configure"
    fi
}