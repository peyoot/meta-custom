# u-boot-dey_2022.10.bbappend

# add custom install script 
SRC_URI += " \
    file://${THISDIR}/u-boot-dey/ccmp2/install_plc_fw_sd.txt \
"

# make sure it has been built in  do_deploy 
do_deploy:append() {

    f="install_plc_fw_sd.txt"
    f_base="${f%.*}"
    f_scr="${DEPLOYDIR}/${f_base}.scr"

    # use mkimage to create scr 
    mkimage -T script -n "Custom firmware install script" -C none -d ${WORKDIR}/${f} ${f_scr}

    install -m 0644 ${f_scr}${D}/boot/${f_base}.scr
}

# make sure this scr be installed into target path
FILES_${PN} += " \
    /boot/install_plc_fw_sd.scr \
"
