# custom-service.bb

SUMMARY = "custom systemd service"
DESCRIPTION = "PLC demo systemd service on startup."
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
RPROVIDES:${PN} += "${PN}"

SRC_URI = "file://codesyscontrol.zip \
        file://codesysstart.service"
# Specify where to get the files

inherit systemd

SYSTEMD_SERVICE:${PN} = "codesysstart.service"

do_configure[noexec] = "1"
do_compile[noexec] = "1"


do_install() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/codesysstart.service ${D}${systemd_unitdir}/system/

    install -d ${D}/usr/local
    cp -r ${WORKDIR}/codsyscontrol/* ${D}/usr/local/

#    install -d ${D}${bindir}
#    install -m 0755 ${WORKDIR}/dummy.sh ${D}${bindir}/

    install -d ${D}${sysconfdir}/systemd/system
    ln -s ${D}${systemd_unitdir}/system/codesysstart.service ${D}${sysconfdir}/systemd/system/codesysstart.service
}


do_unpack() {
    unzip ${WORKDIR}/codsyscontrol.zip -d ${WORKDIR}/codsyscontrol    
}

FILES:${PN} += "${systemd_unitdir}/system/codesysstart.service \
        /usr/local"
