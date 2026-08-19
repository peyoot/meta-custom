SUMMARY = "Vital monitor demo (Qt6 QML) - ECG/HR/SpO2/RESP waveforms"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=fad3086693606a19735a08b2959e6b8c"

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://Main.qml \
           file://ConfigScreen.qml \
           file://MonitorScreen.qml \
           file://Waveform.qml \
           file://VitalsBlock.qml \
           file://HeartData.js \
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
    cat > ${D}${datadir}/applications/vitalmonitor.desktop <<EOF
[Desktop Entry]
Name=Vital Monitor
Exec=/usr/bin/vitalmonitor
Type=Application
EOF
}

FILES:${PN} += "${datadir}/applications/vitalmonitor.desktop"