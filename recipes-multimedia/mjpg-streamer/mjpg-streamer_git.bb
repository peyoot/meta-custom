SUMMARY = "MJPG-streamer with SDL2 viewer support"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    git://github.com/jacksonliam/mjpg-streamer.git;protocol=https;branch=master \
    file://0001-Fix-SDL2-support.patch \
"

SRCREV = "310b29f4a94c46652b20c4b7b6e5cf24e532af39"

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
    install -d ${D}${bindir}
    install -d ${D}${libdir}/mjpg-streamer

    install -m 0755 ${B}/mjpg_streamer ${D}${bindir}/
    install -m 0755 ${B}/plugins/output_viewer/output_viewer.so ${D}${libdir}/mjpg-streamer/
}

FILES:${PN} += " \
    ${bindir}/mjpg_streamer \
    ${libdir}/mjpg-streamer/*.so \
"
