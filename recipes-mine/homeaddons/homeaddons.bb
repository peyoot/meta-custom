# Copyright (C) 2018 Digi International Inc.
SUMMARY = "Home Addons" 
DESCRIPTION = "Adding optional files to homedir" 
LICENSE = "CLOSED" 
FILESEXTRAPATHS:prepend := "${THISDIR}/files:" 
RPROVIDES:${PN} += "${PN}" 
SRC_URI = "file://.profile \
        file://.localconf \
        file://readme.txt"
# Specify where to get the files
S = "${WORKDIR}" 
do_configure[noexec] = "1" 
do_compile[noexec] = "1" 
do_install() {
        # creating the destination directories
        install -d ${D}/root
        # extra files need to go in the respective directories
        install -m 0644 ${WORKDIR}/.profile ${D}/root/
        install -m 0644 ${WORKDIR}/readme.txt ${D}/root/
        install -m 0755 ${WORKDIR}/.localconf ${D}/root/
}

FILES:${PN} += "/root/* \
        /root/.localconf \
        /root/.profile"
