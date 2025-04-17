# custom-service.bb

SUMMARY = "custom systemd service"
DESCRIPTION = "PLC demo systemd service on startup."
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
RPROVIDES:${PN} += "${PN}"

SRC_URI = "file://codesyscontrol.zip \
           file://my_nm.eth1 \
           file://codesysstart.service"
# Specify where to get the files

DEPENDS += "networkmanager"

inherit systemd

SYSTEMD_SERVICE:${PN} = "codesysstart.service"

do_configure[noexec] = "1"
do_compile[noexec] = "1"


do_unpack() {
    unzip ${WORKDIR}/codsyscontrol.zip -d ${WORKDIR}/codsyscontrol
}


do_install() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/codesysstart.service ${D}${systemd_unitdir}/system/

    install -d ${D}/usr/local
    cp -r ${WORKDIR}/codsyscontrol/* ${D}/usr/local/

#    install -d ${D}${bindir}
#    install -m 0755 ${WORKDIR}/dummy.sh ${D}${bindir}/

    install -d ${D}${sysconfdir}/systemd/system
    ln -s ${D}${systemd_unitdir}/system/codesysstart.service ${D}${sysconfdir}/systemd/system/codesysstart.service
}

do_install_append() {

    if [ -f ${D}${sysconfdir}/NetworkManager/system-connections/nm.eth1 ]; then
        # 用你的自定义文件覆盖 nm.eth1
        install -m 0600 ${WORKDIR}/my_nm.eth1${D}${sysconfdir}/NetworkManager/system-connections/nm.eth1
    else
        # 如果 nm.eth1 不存在，输出错误信息
        echo "Error: nm.eth1 not found in ${D}${sysconfdir}/NetworkManager/system-connections/ yet, check priority of recipes"
        exit 1
    fi
}

FILES:${PN} += "${systemd_unitdir}/system/codesysstart.service \
        /usr/local"
