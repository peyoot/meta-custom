# 禁用 gstreamer 以避免 vulkan 编译错误
#RDEPENDS:${PN} = ""

# 移除 connectcore-demo-example 和 CCCS 相关包
RDEPENDS:${PN}:remove = " \
    gstreamer1.0-plugins-base-meta \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good-meta \
    gstreamer1.0-plugins-bad-meta \
    gstreamer1.0-plugins-ugly-meta \
    gstreamer1.0-libav \
    gstreamer1.0-rtsp-server-meta \
"

RDEPENDS:${PN}:remove:append = append = " \
    gstreamer1.0-plugins-base-alsa \
    gstreamer1.0-plugins-base-audioconvert \
    gstreamer1.0-plugins-base-audioresample \
    gstreamer1.0-plugins-base-playback \
    gstreamer1.0-plugins-base-typefindfunctions \
    gstreamer1.0-plugins-base-videoconvertscale \
    gstreamer1.0-plugins-base-volume \
    gstreamer1.0-plugins-good-pulseaudio \
    gstreamer1.0-plugins-good-video4linux2 \
    gstreamer1.0-plugins-good-videofilter \
    gstreamer1.0-plugins-good-avi \
    gstreamer1.0-plugins-good-jpeg \
"