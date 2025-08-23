# Copyright (C) 2023-2025 Digi

# 确保自定义文件路径被优先搜索
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# 添加自定义文件到 SRC_URI
SRC_URI:append = " \
    file://load_iw612.sh \
"

# 重写 do_install 任务，确保使用自定义文件
do_install:append() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/81-iw612-wifi.rules ${D}${sysconfdir}/udev/rules.d/ 2>/dev/null || true
    install -d ${D}${sysconfdir}/udev/scripts
    install -m 0777 ${WORKDIR}/load_iw612.sh ${D}${sysconfdir}/udev/scripts/
}

# 确保文件被包含在包中
FILES:${PN}:append = " \
    ${sysconfdir}/udev/rules.d \
    ${sysconfdir}/udev/scripts \
"

# 添加依赖
RDEPENDS:${PN}:append = " firmware-murata-nxp"