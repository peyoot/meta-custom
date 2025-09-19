# add old cyw-fmac-utils-imx64
SRC_URI += " \
    git://github.com/murata-wireless/cyw-fmac-utils-imx64;protocol=http;branch=master;destsuffix=cyw-fmac-utils-imx64-old;name=cyw-fmac-utils-imx64-old \
"

# sepcify SRCREV for old version
SRCREV_cyw-fmac-utils-imx64-old = "1bc78d68f9609290b2f6578516011c57691f7815"

# update SRCREV_FORMAT to include old one
SRCREV_FORMAT = "cyw-fmac-fw_cyw-fmac-nvram_cyw-bt-patch_cyw-fmac-utils-imx32_cyw-fmac-utils-imx64_cyw-fmac-utils-imx64-old"
# SRCREV_FORMAT:append = "_cyw-fmac-utils-imx64-old"

# append do_install to copy wl-1bc78d6
do_install:append() {
    # install WLAN client utility binary (wl-1bc78d6) in 64-bit arch
    if [ ${TARGET_ARCH} = "aarch64" ]; then
        bbnote "Installing old version (${SRCREV_cyw-fmac-utils-imx64-old}) of wl utility as wl-1bc78d6..."
        install -m 755 ${S}/cyw-fmac-utils-imx64-old/wl ${D}${sbindir}/wl-1bc78d6
    fi
}

# make sure ${PN}-mfgtest include it
FILES:${PN}-mfgtest += " \
    ${sbindir}/wl-1bc78d6 \
"