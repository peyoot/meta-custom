# 确保 xvfb 子包被主包运行时依赖，这样它就会被自动安装
RRECOMMENDS:${PN} += "${PN}-xvfb"

IMAGE_INSTALL:append = " \
    qt5everywheredemo \
    xauth \
    xserver-xorg \
    x11vnc \
    libx11 \
    libxcb \
    libglu \
"

# 确保 xserver-xorg 在构建时包含 xvfb
PACKAGECONFIG:append:pn-xserver-xorg = " xvfb"
