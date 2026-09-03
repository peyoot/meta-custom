FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# 把 webroot 从默认 /srv/www 换掉,不再跟 busybox-httpd 抢文件
SRV_DIR = "${servicedir}/sthttpd-www"