# custom-service.bb

SUMMARY = "Custom systemd service"
DESCRIPTION = "PLC demo systemd service on startup."
LICENSE = "CLOSED"

SRC_URI = " \
    file://codesyscontrol.tar.gz \
    file://codesysstart.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "codesysstart.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    # Install systemd service
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/codesysstart.service ${D}${systemd_unitdir}/system/

    # Install files from tar.gz to /usr/local
    install -d ${D}/usr/local
    cp -r ${WORKDIR}/codesyscontrol/* ${D}/usr/local/
    chmod -R 0755 ${D}/usr/local/codesyscontrol
}

FILES:${PN} += " \
    ${systemd_unitdir}/system/codesysstart.service \
    /usr/local \
"
