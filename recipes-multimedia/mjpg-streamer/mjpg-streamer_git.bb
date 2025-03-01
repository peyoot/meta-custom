# meta-custom/recipes-multimedia/mjpg-streamer/mjpg-streamer_git.bb

SUMMARY = "MJPG-streamer for streaming video"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "git://github.com/jacksonliam/mjpg-streamer.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git/mjpg-streamer-experimental"

DEPENDS = "jpeg libv4l"
# 添加构建依赖cmake-native
DEPENDS += "cmake-native"

# 使用CMake构建
inherit cmake

# 启用必要的插件
EXTRA_OECMAKE = " \
    -DPLUGIN_INPUT_UVC=ON \
    -DPLUGIN_OUTPUT_HTTP=ON \
"

# 安装路径调整
do_install() {
    install -d ${D}${bindir}
    install -d ${D}${libdir}/mjpg-streamer

    # 安装主程序
    install -m 0755 ${B}/mjpg_streamer ${D}${bindir}/

    # 安装插件
    install -m 0755 ${B}/input_uvc.so ${D}${libdir}/mjpg-streamer/
    install -m 0755 ${B}/output_http.so ${D}${libdir}/mjpg-streamer/
}

FILES:${PN} += " \
    ${bindir}/mjpg_streamer \
    ${libdir}/mjpg-streamer/*.so \
"
