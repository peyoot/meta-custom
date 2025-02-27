# meta-custom/recipes-httpd/sthttpd/sthttpd_%.bbappend

# 定义新的网页根目录和端口
SRV_DIR = "/srv/www"  # 修改默认路径
HTTP_PORT = "80"          # 保持默认端口（若需修改，例如 8080，则同步调整）

# 覆盖配置参数
EXTRA_OEMAKE:append = " CFLAGS='-DHTTP_PORT=${HTTP_PORT}'"

# 修改 systemd 服务和 init 脚本
do_install:append() {
    # 更新安装路径和端口
    sed -i "s|${SRV_DIR}|/srv/sthttpd|g" ${D}${sysconfdir}/thttpd.conf
    sed -i "s|/srv/www|/srv/sthttpd|g" ${D}${sysconfdir}/init.d/thttpd
    sed -i "s|--port 80|--port ${HTTP_PORT}|g" ${D}${systemd_unitdir}/system/thttpd.service
}
