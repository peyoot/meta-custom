# 自定义 busybox-httpd 配置

# 定义新端口和路径
BUSYBOX_HTTPD_PORT = "8080"
BUSYBOX_HTTPD_ROOT = "/srv/busybox-www"

# 添加自定义配置片段
SRC_URI += "file://httpd-custom.cfg"

do_configure:prepend() {
    echo "CONFIG_HTTPD_PORT=${BUSYBOX_HTTPD_PORT}" >> ${WORKDIR}/httpd-custom.cfg
    echo "CONFIG_HTTPD_DOCUMENT_ROOT=${BUSYBOX_HTTPD_ROOT}" >> ${WORKDIR}/httpd-custom.cfg
}

do_install:append() {
    # 修改 SysVinit 脚本
    if [ -f ${D}${sysconfdir}/init.d/busybox-httpd ]; then
        sed -i "s|port=80|port=${BUSYBOX_HTTPD_PORT}|g" ${D}${sysconfdir}/init.d/busybox-httpd
        sed -i "s|/srv/www|${BUSYBOX_HTTPD_ROOT}|g" ${D}${sysconfdir}/init.d/busybox-httpd
    fi

    # 修改 systemd 服务
    if [ -f ${D}${systemd_unitdir}/system/busybox-httpd.service ]; then
        sed -i "s|--port 80|--port ${BUSYBOX_HTTPD_PORT}|g" ${D}${systemd_unitdir}/system/busybox-httpd.service
        sed -i "s|/srv/www|${BUSYBOX_HTTPD_ROOT}|g" ${D}${systemd_unitdir}/system/busybox-httpd.service
    fi
}

# 禁用自启动
INITSCRIPT_PARAMS:${PN}-httpd = "stop 21 0 1 6 ."
SYSTEMD_AUTO_ENABLE:${PN}-httpd = "disable"
