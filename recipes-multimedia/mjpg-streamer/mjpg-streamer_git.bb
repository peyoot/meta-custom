# meta-custom/recipes-multimedia/mjpg-streamer/mjpg-streamer_git.bb

SUMMARY = "MJPG-streamer for streaming video"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "git://github.com/jacksonliam/mjpg-streamer.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

DEPENDS = "jpeg libv4l"

# 指定需要编译的插件
PLUGINS = "input_uvc.so output_http.so"

# 添加头文件和库路径
CFLAGS:append = " -I${STAGING_INCDIR}"
LDFLAGS:append = " -L${STAGING_LIBDIR} -ljpeg"

# 交叉编译参数
EXTRA_OEMAKE = "CC='${CC}' LD='${LD}'"

do_compile() {
    # 编译主程序
    oe_runmake -C mjpg-streamer-experimental

    # 编译插件
    for plugin in ${PLUGINS}; do
        oe_runmake -C mjpg-streamer-experimental/plugins/${plugin%.so}
    done
}

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${libdir}/mjpg-streamer

    # 安装主程序
    install -m 0755 mjpg-streamer-experimental/mjpg_streamer ${D}${bindir}/

    # 安装插件
    for plugin in ${PLUGINS}; do
        install -m 0755 mjpg-streamer-experimental/plugins/${plugin%.so}/${plugin} ${D}${libdir}/mjpg-streamer/
    done
}

FILES:${PN} += " \
    ${bindir}/mjpg_streamer \
    ${libdir}/mjpg-streamer/*.so \
"
