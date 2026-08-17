SUMMARY = "OEM-grade automotive instrument cluster demo (Qt6 QML)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "git://github.com/Ibrahim4594/Hmi-Car-Dashboard-.git;branch=main"
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

inherit qt6-cmake

# 依赖极少，meta-st-x-linux-qt 默认就提供
DEPENDS += "qtbase qtdeclarative qtdeclarative-native qtquickcontrols2"

RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative-qmlplugins \
    qtquickcontrols2-qmlplugins \
"

# 目标：1920x720 或 1280x480，可按板子屏幕改
EXTRA_OECMAKE += "-DCMAKE_BUILD_TYPE=Release"

do_install:append() {
    install -d ${D}${datadir}/applications
    cat > ${D}${datadir}/applications/hmi-dashboard.desktop <<EOF
[Desktop Entry]
Name=HMI Dashboard
Exec=/usr/bin/InstrumentCluster
Type=Application
EOF
}

FILES:${PN} += "${datadir}/applications/hmi-dashboard.desktop"