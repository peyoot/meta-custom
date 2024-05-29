# dummy.service.bb

SUMMARY = "dummy script systemd service"
DESCRIPTION = "A systemd service to run or source script on system startup. you can ues it as reference. change it to your formal service name rather than dummy"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
RPROVIDES:${PN} += "${PN}"

SRC_URI = "file://dummy.sh \
        file://dummy.service"
# Specify where to get the files

inherit systemd

SYSTEMD_SERVICE:${PN} = "dummy.service"

do_configure[noexec] = "1"
do_compile[noexec] = "1"


do_install() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/dummy.service ${D}${systemd_unitdir}/system/

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/dummy.sh ${D}${bindir}/


    install -d ${D}${sysconfdir}/systemd/system
    ln -s ${D}${systemd_unitdir}/system/dummy.service ${D}${sysconfdir}/systemd/system/dummy.service
}

FILES:${PN} += "${systemd_unitdir}/system/dummy.service \
        ${bindir}/dummy.sh"
