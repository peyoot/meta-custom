SUMMARY = "MJPG-streamer with SDL1.2 viewer support"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    git://github.com/peyoot/mjpg-streamer.git;protocol=https;branch=master \
"

SRCREV = "${AUTOREV}"

DEPENDS = "jpeg libjpeg-turbo libjpeg-turbo-native libv4l gstreamer1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad wayland wayland-protocols virtual/egl virtual/libgles2 cmake-native"

S = "${WORKDIR}/git/mjpg-streamer-experimental"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DPLUGIN_INPUT_UVC=ON \
    -DPLUGIN_INPUT_V4L2=ON \
    -DPLUGIN_INPUT_RASPICAM=ON \
    -DPLUGIN_OUTPUT_HTTP=ON \
    -DPLUGIN_OUTPUT_VIEWER=ON \                  
    -DWITH_GSTREAMER=ON \                  
"
EXTRA_OECMAKE:append:ccimx9 = " -DPLATFORM_ARCH=cortex-a55 "
EXTRA_OECMAKE:append:ccmp25 = " -DPLATFORM_ARCH=cortex-a35 "

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
