SUMMARY = "OEM-grade automotive instrument cluster demo (Qt6 QML)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "git://github.com/Ibrahim4594/Hmi-Car-Dashboard-.git;branch=main;protocol=https"
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

inherit qt6-cmake

DEPENDS += "qtbase qtdeclarative qtdeclarative-native qtshadertools-native"

# 运行时依赖
RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative-qmlplugins \
"

# 目标：1920x720 或 1280x480，可按板子屏幕改
EXTRA_OECMAKE += "-DCMAKE_BUILD_TYPE=Release"

do_configure:prepend() {
    sed -i 's/ctx\.roundRect(/ctx.roundedRect(/g' ${S}/qml/*.qml
    # 注意：如果参数是单半径，需要调整为双半径。此 demo 所有调用都是 5 参数 (x,y,w,h,r)，所以替换后变成 (x,y,w,h,r,r)
    # 更精确的做法是捕获参数并复制最后一个逗号后的值：
    sed -i 's/ctx\.roundedRect(\([^,]*,[^,]*,[^,]*,[^,]*,[^,]*\))/ctx.roundedRect(\1,\1)/g' ${S}/qml/*.qml
}

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