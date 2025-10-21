# 禁用 gstreamer 以避免 vulkan 编译错误
MACHINE_GSTREAMER_1_0_PKGS = ""

RDEPENDS:${PN} = " \
    ${MACHINE_GSTREAMER_1_0_PKGS} \
"