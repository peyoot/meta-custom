# meta-custom/recipes-security/optee/optee-os-stm32mp_4.0.0.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://0001-ccmp25-dvk-adjust-dts-configuration.patch"
SRCREV = "5c00c71b64a32a4f4bd7266ae88d34b7a07ebe5a"