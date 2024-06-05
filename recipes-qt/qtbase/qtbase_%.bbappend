# qtbase.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://rosqt5.sh \
"

do_install:append() {

    rm -f ${D}${sysconfdir}/profile.d/qt5.sh
    install -d ${D}${sysconfdir}/profile.d/
    install -m 0755 ${WORKDIR}/rosqt5.sh ${D}${sysconfdir}/profile.d/rosqt5.sh
}


FILES:${PN} += "${sysconfdir}/profile.d/rosqt5.sh"

