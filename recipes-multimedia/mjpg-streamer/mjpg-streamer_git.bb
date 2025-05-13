SUMMARY = "MJPG-streamer with SDL1.2 viewer support"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    git://github.com/peyoot/mjpg-streamer.git;protocol=https;branch=master \
"

SRCREV = "${AUTOREV}"

DEPENDS = "jpeg libv4l libsdl2 libjpeg-turbo"
DEPENDS += "cmake-native"

S = "${WORKDIR}/git/mjpg-streamer-experimental"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DPLUGIN_INPUT_UVC=ON \
    -DPLUGIN_OUTPUT_HTTP=ON \
    -DPLUGIN_OUTPUT_VIEWER=ON \
    -DSDL2_DIR=${STAGING_LIBDIR}/cmake/SDL2 \
"

do_install() {
    install -d -m 0755 "${D}${bindir}"
    install -d -m 0755 "${D}${libdir}"

    install -m 0755 "${B}/mjpg_streamer" "${D}${bindir}/"
    find "${B}/plugins/" -name "*.so" -exec install -m 0755 {} "${D}${libdir}/" \;
}

FILES:${PN} += " \
    ${bindir}/mjpg_streamer \
    ${libdir}/*.so \
"
