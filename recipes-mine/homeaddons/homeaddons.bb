# Copyright (C) 2018 Digi International Inc.
SUMMARY = "Home Addons" 
DESCRIPTION = "Adding optional files to homedir" 
LICENSE = "CLOSED" 
FILESEXTRAPATHS:prepend := "${THISDIR}/files:" 
RPROVIDES:${PN} += "${PN}" 
SRC_URI = "file://.bashrc \
        file://about-demo.txt"
# Specify where to get the files
S = "${WORKDIR}" 
do_configure[noexec] = "1" 
do_compile[noexec] = "1" 
do_install() {
        # creating the destination directories
        install -d ${D}/home/root
        install -d ${D}/home/weston
        # extra files need to go in the respective directories
        install -m 0644 ${WORKDIR}/.bashrc ${D}/home/root/
        install -m 0644 ${WORKDIR}/about-demo.txt ${D}/home/root/
        install -m 0644 ${WORKDIR}/.bashrc ${D}/home/weston/
        install -m 0644 ${WORKDIR}/about-demo.txt ${D}/home/weston/

}

FILES:${PN} += "/home/root/.bashrc \
        /home/root/about-demo.txt \
        /home/weston/.bashrc \
        /home/weston/about-demo.txt"
