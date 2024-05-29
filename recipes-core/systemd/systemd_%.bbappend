# ros_setup.service.bb

SUMMARY = "dummy setup script systemd service"
DESCRIPTION = "A systemd service to source script on system startup. you can ues it as reference. change it to your formal service name rather than dummy_setup"
LICENSE = "Apache-2.0"

SRC_URI = "file://dummy_setup.service"

inherit systemd

SYSTEMD_SERVICE:${PN} = "dummy_setup.service"

do_install() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/dummy_setup.service ${D}${systemd_unitdir}/system/
    install -m 0755 ${WORKDIR}/dummy_setup.sh ${D}${sysconfdir}/

    install -d ${D}${sysconfdir}/systemd/system
    ln -s ${D}${systemd_unitdir}/system/dummy_setup.service ${D}${sysconfdir}/systemd/system/dummy_setup.service
}


SYSTEMD_SERVICE:${PN} = "dummy_setup.service"


