# meta-custom/recipes-core/busybox/busybox_%.bbappend

# 添加自定义配置片段
SRC_URI += "file://httpd-custom.cfg"

# 覆盖默认的 HTTP 服务配置
do_configure:append() {
    # 设置 HTTP 服务端口为 8080（避免与 sthttpd 冲突）
    echo "CONFIG_HTTPD_PORT=8080" >> ${WORKDIR}/httpd-custom.cfg
    # 修改默认的网页根目录（可选）
    echo "CONFIG_HTTPD_DOCUMENT_ROOT=/srv/busybox-www" >> ${WORKDIR}/httpd-custom.cfg
}

# 在同一个 bbappend 文件中添加以下内容
do_install:append() {
    # 修改 SysVinit 脚本的端口和路径
    if [ -f ${D}${sysconfdir}/init.d/httpd ]; then
        sed -i 's|port=80|port=8080|g' ${D}${sysconfdir}/init.d/httpd
        sed -i 's|/srv/www|/srv/busybox-www|g' ${D}${sysconfdir}/init.d/httpd
    fi

    # 修改 systemd 服务（如果存在）
    if [ -f ${D}${systemd_unitdir}/system/busybox-httpd.service ]; then
        sed -i 's|--port=80|--port=8080|g' ${D}${systemd_unitdir}/system/busybox-httpd.service
        sed -i 's|/srv/www|/srv/busybox-www|g' ${D}${systemd_unitdir}/system/busybox-httpd.service
    fi
}
