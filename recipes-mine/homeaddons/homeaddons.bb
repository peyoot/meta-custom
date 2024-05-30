# Copyright (C) 2018 Digi International Inc.
SUMMARY = "Home Addons" 
DESCRIPTION = "Adding optional files to homedir" 
LICENSE = "CLOSED" 
FILESEXTRAPATHS:prepend := "${THISDIR}/files:" 
RPROVIDES:${PN} += "${PN}" 
SRC_URI = "file://.profile \
        file://myfile.txt"
# Specify where to get the files
S = "${WORKDIR}" 
do_configure[noexec] = "1" 
do_compile[noexec] = "1" 
do_install() {
        # creating the destination directories
        install -d ${D}/home/root
        # extra files need to go in the respective directories
        install -m 0644 ${WORKDIR}/.profile ${D}/home/root/
        install -m 0644 ${WORKDIR}/about-demo.txt ${D}/home/root/
        install -m 0644 ${WORKDIR}/.profile ${D}/home/weston/
        install -m 0644 ${WORKDIR}/about-demo.txt ${D}/home/weston/

}

FILES:${PN} += "/home/root/.profile \
        /home/root/about-demo.txt \
        /home/weston/.profile \
        /home/weston/about-demo.txt"
