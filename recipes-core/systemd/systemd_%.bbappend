FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://99-weston-headless.preset \
"

do_install:append() {
    install -d ${D}${systemd_unitdir}/system-preset/
    install -m 0644 ${WORKDIR}/99-weston-headless.preset ${D}${systemd_unitdir}/system-preset/
}

FILES:${PN}:append = " ${systemd_unitdir}/system-preset/99-weston-headless.preset"