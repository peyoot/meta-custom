# 彻底移除 cccs-gs-demo 和 cccsd 的 systemd 服务及 init 脚本
# 通过覆盖 do_install 和调整 FILES 变量实现

# 移除 systemd 服务安装逻辑
do_install:prepend() {
    # 删除 SRC_URI 中的服务文件，防止被下载到 WORKDIR
    # 注意：需要确保后续步骤不会依赖这些文件
    rm -f ${WORKDIR}/cccsd.service ${WORKDIR}/cccs-gs-demo.service
    rm -f ${WORKDIR}/cccsd-init ${WORKDIR}/cccs-gs-demo-init
}

# 覆盖原 do_install，跳过服务安装
do_install() {
    oe_runmake DESTDIR=${D} install

    # 强制跳过 systemd 服务安装（即使原逻辑判断为 true）
    :
}

# 清除 init 脚本和符号链接
do_install:append() {
    # 删除已安装的 init 脚本和符号链接
    rm -rf ${D}${sysconfdir}/init.d/cccsd
    rm -rf ${D}${sysconfdir}/init.d/cccs-gs-demo
    rm -rf ${D}${sysconfdir}/cccsd
    rm -rf ${D}${sysconfdir}/cccs-gs-demo
}

# 清空关联包的 FILES 定义，确保不打包残留文件
FILES:${PN}-daemon = ""
FILES:${PN}-gs-demo = ""

# 禁用 systemd 和 initscript 配置（双重保险）
SYSTEMD_SERVICE:${PN}-daemon = ""
SYSTEMD_SERVICE:${PN}-gs-demo = ""
INITSCRIPT_PACKAGES = ""
