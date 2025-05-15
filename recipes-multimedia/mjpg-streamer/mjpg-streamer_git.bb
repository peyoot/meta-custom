SUMMARY = "MJPG-streamer with SDL1.2 viewer support"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    git://github.com/peyoot/mjpg-streamer.git;protocol=https;branch=master \
"

SRCREV = "${AUTOREV}"

DEPENDS = "jpeg libv4l libsdl2 libjpeg-turbo virtual/egl virtual/libgles2 cmake-native"

S = "${WORKDIR}/git/mjpg-streamer-experimental"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DPLUGIN_INPUT_UVC=ON \
    -DPLUGIN_OUTPUT_HTTP=ON \
    -DPLUGIN_OUTPUT_VIEWER=ON \
    -DSDL2_DIR=${STAGING_LIBDIR}/cmake/SDL2 \
    -DCMAKE_DISABLE_FIND_PACKAGE_TurboJPEG=ON \                      
    -DWITH_TURBOJPEG=ON \                     
"
EXTRA_OECMAKE:append:ccimx9 = " \
    -DCMAKE_C_FLAGS='-O3 -mcpu=cortex-a55' \
"

EXTRA_OECMAKE:append:ccmp25 = " \
    -DCMAKE_C_FLAGS='-O3 -mcpu=cortex-a35 -mfpu=neon-fp-armv8 -mfloat-abi=hard' \
"

PACKAGECONFIG:remove = "sdl2-opengles neon"

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
