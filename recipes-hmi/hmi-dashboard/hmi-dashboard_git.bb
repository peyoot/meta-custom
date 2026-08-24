SUMMARY = "OEM-grade automotive instrument cluster demo (Qt QML)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "git://github.com/Ibrahim4594/Hmi-Car-Dashboard-.git;branch=main;protocol=https \
           file://0001-support-qt5-and-qt6-dual-build.patch \
"
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

# 同时支持 bblayers.conf 里选用 meta-qt5 或 meta-qt6：
#   - 默认按 meta-qt6 编译 (QT_MAJOR_VERSION = "6")
#   - 切到 meta-qt5 时，在 local.conf / distro 配置里覆盖：
#       QT_MAJOR_VERSION = "5"
# 上面的 0001-support-qt5-and-qt6-dual-build.patch 让上游 CMakeLists.txt
# 在配置阶段自动探测实际的 Qt 主版本；这里只需要让 bitbake 选对
# inherit 的 cmake 包装类和 Qt 组件包名即可（做法和 vitalmonitor recipe 一致）。
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

# 这个项目本身用到了 QtQuick.Controls 2（CMakeLists.txt 里显式 find_package/link 了 QuickControls2）
# Qt6：着色器编译工具，QuickControls2 已经并入 qtdeclarative，不需要单独声明
DEPENDS += "${@bb.utils.contains('QT_MAJOR_VERSION', '6', 'qtshadertools qtshadertools-native', '', d)}"

# Qt5：QtQuick.Controls 2 是独立模块 qtquickcontrols2，到 Qt6 才被合并进 qtdeclarative 仓库
DEPENDS += "${@bb.utils.contains('QT_MAJOR_VERSION', '5', 'qtquickcontrols2', '', d)}"
RDEPENDS:${PN} += "${@bb.utils.contains('QT_MAJOR_VERSION', '5', 'qtquickcontrols2-qmlplugins', '', d)}"

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