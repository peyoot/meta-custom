# 添加对旧版本 cyw-fmac-utils-imx64 的获取
SRC_URI += " \
    git://github.com/murata-wireless/cyw-fmac-utils-imx64;protocol=http;branch=master;destsuffix=cyw-fmac-utils-imx64-old;name=cyw-fmac-utils-imx64-old \
"

# 指定旧版本的 SRCREV
SRCREV_cyw-fmac-utils-imx64-old = "1bc78d68f9609290b2f6578516011c57691f7815"

# 更新 SRCREV_FORMAT 以包含新的源码项
SRCREV_FORMAT:append = " _cyw-fmac-utils-imx64-old"

# 修改 do_install 函数，追加安装旧版本 wl 工具的步骤
do_install:append() {
    # 安装旧版本的 WLAN client utility binary (wl-1bc78d6) 基于 64-bit arch
    if [ ${TARGET_ARCH} = "aarch64" ]; then
        bbnote "Installing old version (${SRCREV_cyw-fmac-utils-imx64-old}) of wl utility as wl-1bc78d6..."
        install -m 755 ${S}/cyw-fmac-utils-imx64-old/wl ${D}${sbindir}/wl-1bc78d6
    fi
}

# 确保旧版本的工具也被打包到 ${PN}-mfgtest 包中
FILES:${PN}-mfgtest += " \
    ${sbindir}/wl-1bc78d6 \
"