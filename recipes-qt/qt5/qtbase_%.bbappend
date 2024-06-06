# meta-custom/recipes-qt/qt5/qtbase_%.bbappend  
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://rosqt5.sh \
"

do_install:append() {

    rm -f ${D}${sysconfdir}/profile.d/qt5.sh
    install -d ${D}${sysconfdir}/profile.d/
    install -m 0755 ${WORKDIR}/rosqt5.sh ${D}${sysconfdir}/profile.d/qt5.sh
}


FILES:${PN} += "${sysconfdir}/profile.d/qt5.sh"


