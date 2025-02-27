SUMMARY = "MJPG-streamer for streaming video"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "git://github.com/jacksonliam/mjpg-streamer.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

DEPENDS = "libjpeg"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 mjpg_streamer ${D}${bindir}/
    install -m 0755 input_*.so output_*.so ${D}${bindir}/
}

FILES:${PN} += "${bindir}/*"
