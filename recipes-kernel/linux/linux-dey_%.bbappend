# meta-custom/recipes-kernel/linux/linux-dey_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://0001-add-ch343-usb-serial-driver.patch \
    file://ch343.cfg \
"

# 确保内核配置片段被应用，以ch343为例
do_configure:append() {
    if [ -f ${WORKDIR}/ch343.cfg ]; then
        cat ${WORKDIR}/ch343.cfg >> ${B}/.config
    fi
}

