FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# 扩展 PACKAGECONFIG 以支持 X11
PACKAGECONFIG:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11', 'x11 xcb xkbcommon-evdev', '', d)} \
"

# 根据后端类型提供不同的配置
QT_CONFIG_FLAGS += " -no-sse2 -no-opengles3"

SRC_URI:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'x11', 'file://qt5-x11.sh', '', d)} \
"

do_install:append() {
    install -d ${D}${sysconfdir}/profile.d/

    if ${@bb.utils.contains('DISTRO_FEATURES', 'x11', 'true', 'false', d)}; then
        # X11 backend
        install -m 0755 ${WORKDIR}/qt5-x11.sh ${D}${sysconfdir}/profile.d/qt5.sh
    elif ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'true', 'false', d)}; then
        # Wayland backend
        install -m 0755 ${WORKDIR}/qt5-wayland.sh ${D}${sysconfdir}/profile.d/qt5.sh
    else
        # EGLFS backend
        install -d ${D}${datadir}/qt5
        install -m 0755 ${WORKDIR}/qt5-eglfs.sh ${D}${sysconfdir}/profile.d/qt5.sh
        install -m 0664 ${WORKDIR}/cursor.json ${D}${datadir}/qt5/
    fi
}

FILES:${PN} += " \
    ${sysconfdir}/profile.d/qt5.sh \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', '', \
        bb.utils.contains('DISTRO_FEATURES', 'x11', '', '${datadir}/qt5', d), d)} \
"