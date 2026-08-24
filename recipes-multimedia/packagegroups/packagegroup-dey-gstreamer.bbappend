# 扩展MACHINE_GSTREAMER_1_0_PKGS以包含必要的插件
MACHINE_GSTREAMER_1_0_PKGS:append = " \
    gstreamer1.0-plugins-base-alsa \
    gstreamer1.0-plugins-base-audioconvert \
    gstreamer1.0-plugins-base-audioresample \
    gstreamer1.0-plugins-base-playback \
    gstreamer1.0-plugins-base-typefindfunctions \
    gstreamer1.0-plugins-base-videoconvert \
    gstreamer1.0-plugins-base-videoscale \
    gstreamer1.0-plugins-base-volume \
    gstreamer1.0-plugins-good-pulseaudio \
    gstreamer1.0-plugins-good-video4linux2 \
    gstreamer1.0-plugins-good-videofilter \
    gstreamer1.0-plugins-good-vpx \
    gstreamer1.0-plugins-good-avi \
    gstreamer1.0-plugins-good-jpeg \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-rtsp-server \
    gstreamer1.0-libav \
    gstreamer1.0-omx \
    gstreamer1.0-plugins-base-apps \
"

# 确保包含其他必要的依赖
MACHINE_GSTREAMER_1_0_EXTRA_INSTALL:append = " \
    x264 \
    libjpeg-turbo \
    libpng \
    zlib \
    uhttpd \
    v4l-utils \
"

# 添加缺失的插件包到 RDEPENDS

RDEPENDS:${PN} = " \
    gstreamer1.0-plugins-base-meta \
    gstreamer1.0-plugins-good-meta \
    gstreamer1.0-plugins-bad-meta \
    gstreamer1.0-plugins-ugly-meta \
"

# 接受可能的许可证限制（如 GPL/商业许可证）
LICENSE_FLAGS_ACCEPTED = "commercial"
