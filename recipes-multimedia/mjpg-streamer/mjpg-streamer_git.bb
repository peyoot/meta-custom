# meta-custom/recipes-multimedia/mjpg-streamer/mjpg-streamer_git.bb

SUMMARY = "MJPG-streamer for streaming video"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "git://github.com/jacksonliam/mjpg-streamer.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git/mjpg-streamer-experimental"

# 添加所有插件可能需要的依赖（根据实际需要调整）
DEPENDS = "jpeg libv4l libsdl2 libsdl2-image"
DEPENDS += "cmake-native"
EXTRA_OEMAKE += "WITH_SDL=1"

inherit cmake

# 启用插件（或根据需要选择）
EXTRA_OECMAKE = " \
    -DPLUGIN_INPUT_UVC=ON \
    -DPLUGIN_OUTPUT_HTTP=ON \
    -DPLUGIN_OUTPUT_VIEWER=ON \
"

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${libdir}

    # 安装主程序
    install -m 0755 ${B}/mjpg_streamer ${D}${bindir}/

    # 自动安装所有插件（递归搜索.so文件）
    find ${B}/plugins/ -name "*.so" -exec install -Dm 0755 {} ${D}${libdir}/ \;
}

FILES:${PN} += " \
    ${bindir}/mjpg_streamer \
    ${libdir}/*.so \
"
