# 路径：meta-custom/recipes-core/images/dey-image-qt.bbappend

STM32MP_KERNEL_DEVICETREE:ccmp25-dvk:append = " ccmp25-viena.dtb ccmp25-viena-hdmi.dtb ccmp25-viena-dualdisplay.dtb ccmp25-viena_ads7846.dtbo ccmp25-viena_hdmi.dtbo ccmp25-viena_dualdisplay.dtbo"

IMAGE_INSTALL:append = " util-linux-chrt util-linux-taskset util-linux-lscpu"

GLIBC_GENERATE_LOCALES = "zh_CN.UTF-8 en_US.UTF-8"
IMAGE_LINGUAS = "en-us zh-cn"
LOCALE_UTF8_ONLY = "1"

export LANG = "en_US.UTF-8"
export LC_ALL = "en_US.UTF-8"

