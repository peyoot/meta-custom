# ros_setup.service.bb

SUMMARY = "dummy setup script systemd service"
DESCRIPTION = "A systemd service to source script on system startup. you can ues it as reference. change it to your formal service name rather than dummy_setup"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "file://dummy_setup.sh \
        file://dummy_setup.service"
# Specify where to get the files

inherit systemd

SYSTEMD_SERVICE:${PN} = "dummy_setup.service"

do_install() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/dummy_setup.service ${D}${systemd_unitdir}/system/

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/dummy_setup.sh ${D}${bindir}/


    install -d ${D}${sysconfdir}/systemd/system
    ln -s ${D}${systemd_unitdir}/system/dummy_setup.service ${D}${sysconfdir}/systemd/system/dummy_setup.service
}

FILES:${PN} += "${systemd_unitdir}/system/dummy_setup.service \
        ${bindir}/dummy_setup.sh"
