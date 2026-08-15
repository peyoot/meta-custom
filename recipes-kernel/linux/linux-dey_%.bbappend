# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://cpufreq.cfg \
            "
# 确保配置片段被应用
do_configure:append() {
    if [ -f ${WORKDIR}/cpufreq.cfg ]; then
        cat ${WORKDIR}/cpufreq.cfg >> ${B}/.config
    fi
}

