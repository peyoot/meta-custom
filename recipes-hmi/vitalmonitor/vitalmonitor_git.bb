SUMMARY = "Vital monitor demo (Qt QML) - ECG/HR/SpO2/RESP waveforms"
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
           file://qml.qrc \
           file://LICENSE \
"

S = "${WORKDIR}"

# 同时支持 bblayers.conf 里选用 meta-qt5 或 meta-qt6：
#   - 默认按 meta-qt6 编译 (QT_MAJOR_VERSION = "6")
#   - 切到 meta-qt5 时，在 local.conf / distro 配置里覆盖：
#       QT_MAJOR_VERSION = "5"
# CMakeLists.txt 会在配置阶段自动探测实际的 Qt 主版本并生成对应的构建逻辑，
# 这里只需要让 bitbake 选对 inherit 的 cmake 包装类和 Qt 组件包名即可。
QT_MAJOR_VERSION ?= "6"

# meta-qt6 提供 "qt6-cmake"，meta-qt5 提供 "cmake_qt5" —— 两个类名的构词顺序不同，
# 不能简单地用 qt${QT_MAJOR_VERSION}-cmake 拼出来，所以用 bb.utils.contains 显式二选一。
inherit ${@bb.utils.contains('QT_MAJOR_VERSION', '5', 'cmake_qt5', 'qt6-cmake', d)}

# 两个版本都有的基础依赖
DEPENDS += "qtbase qtdeclarative qtdeclarative-native"
RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative-qmlplugins \
"

# Qt6 专属：Qt Quick 的着色器编译工具（RHI 渲染管线需要，Qt5 没有这个模块）
DEPENDS += "${@bb.utils.contains('QT_MAJOR_VERSION', '6', 'qtshadertools qtshadertools-native', '', d)}"

# Qt5 专属：QtQuick.Controls 2 在 Qt5 里是独立模块 qtquickcontrols2，
# 到了 Qt6 才被合并进 qtdeclarative 仓库里，所以只有 Qt5 才需要单独声明。
DEPENDS += "${@bb.utils.contains('QT_MAJOR_VERSION', '5', 'qtquickcontrols2', '', d)}"
RDEPENDS:${PN} += "${@bb.utils.contains('QT_MAJOR_VERSION', '5', 'qtquickcontrols2-qmlplugins', '', d)}"

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
