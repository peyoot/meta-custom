# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://cpufreq.cfg \
            file://fragment.cfg \
            "
#do_configure:append() {
#    if [ -f ${WORKDIR}/fragment.cfg ]; then
#        cat ${WORKDIR}/fragment.cfg >> ${B}/.config
#        oe_runmake -C ${S} O=${B} olddefconfig
#    fi
#}
