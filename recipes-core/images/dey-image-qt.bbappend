# 路径：meta-custom/recipes-core/images/dey-image-qt.bbappend
GLIBC_GENERATE_LOCALES = "zh_CN.UTF-8 en_US.UTF-8"
IMAGE_LINGUAS = "en-us zh-cn"
LOCALE_UTF8_ONLY = "1"

export LANG = "en_US.UTF-8"
export LC_ALL = "en_US.UTF-8"

# 添加缺失的库到镜像
IMAGE_INSTALL:append = " gstreamer1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-rtsp-server gstreamer1.0-omx gstreamer1.0-plugins-base-apps gst-variable-rtsp-server x264 libjpeg-turbo libpng zlib nano tmux localedef glibc-utils v4l-utils sthttpd  glibc-localedata-en-us  glibc-localedata-zh-cn"



# 接受许可证（可选，如果 LICENSE_FLAGS_ACCEPTED 未在全局设置）
LICENSE_FLAGS_ACCEPTED:append = " commercial_gpl"
