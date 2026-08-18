SUMMARY = "Bedside patient monitor UI (Qt6 QML) - multi-parameter vitals display"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=fad3086693606a19735a08b2959e6b8c"

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://Main.qml \
           file://VitalsPanel.qml \
           file://WaveformCanvas.qml \
           file://VitalsSimulator.js \
           file://LICENSE \
"

S = "${WORKDIR}"

inherit qt6-cmake

DEPENDS += "qtbase qtdeclarative qtdeclarative-native qtshadertools-native"
RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative-qmlplugins \
"

do_install:append() {
    install -d ${D}${datadir}/applications
    cat > ${D}${datadir}/applications/bedside-monitor.desktop <<EOF
[Desktop Entry]
Name=Bedside Monitor
Exec=/usr/bin/bedside-monitor
Type=Application
EOF
}

FILES:${PN} += "${datadir}/applications/bedside-monitor.desktop"