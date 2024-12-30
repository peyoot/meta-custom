# meta-custom/recipes-mine/base-files/base-files.bbappend

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
    file://share/dot.bashrc \
"

