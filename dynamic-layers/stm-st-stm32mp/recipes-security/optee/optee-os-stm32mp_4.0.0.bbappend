FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:ccmp25 = " \
    file://0001-unlock-MP255C-frequency.patch \
"