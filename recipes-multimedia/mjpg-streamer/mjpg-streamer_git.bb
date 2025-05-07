SUMMARY = "MJPG-streamer with SDL2 viewer support"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    git://github.com/peyoot/mjpg-streamer.git;protocol=https;branch=master \
"

SRCREV = "9ed90c00b0115f90a3512a6900aa5a1383168c20"

DEPENDS = "jpeg libv4l libsdl2 libsdl2-image"
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
    install -d -m 0755 "${D}${libdir}/mjpg-streamer"

    install -m 0755 "${B}/mjpg_streamer" "${D}${bindir}/"
    find "${B}/plugins/" -name "*.so" -exec install -m 0755 {} "${D}${libdir}/mjpg-streamer/" \+
}

FILES:${PN} += " \
    ${bindir}/mjpg_streamer \
    ${libdir}/mjpg-streamer/*.so \
"
