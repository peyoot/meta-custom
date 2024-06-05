# qtbase.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://qt5.sh \
"

do_install:append() {

    install -d ${D}${sysconfdir}/profile.d/
    install -m 0755 ${WORKDIR}/qt5.sh ${D}${sysconfdir}/profile.d/qt5.sh
}


#FILES:${PN} += "${sysconfdir}/profile.d/qt5.sh" remote this and use prepend to make sure override 
FILES:append = "${sysconfdir}/profile.d/qt5.sh"

