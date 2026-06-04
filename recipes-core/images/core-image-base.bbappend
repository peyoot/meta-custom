# STM32MP_KERNEL_DEVICETREE:ccmp25-dvk:append = " ccmp25-viena.dtb ccmp25-viena_ads7846.dtbo"
STM32MP_KERNEL_DEVICETREE:ccmp25-dvk:append = " ccmp25-viena.dtb ccmp25-viena-hdmi.dtb ccmp25-viena-dualdisplay.dtb ccmp25-viena_ads7846.dtbo ccmp25-viena_hdmi.dtbo ccmp25-viena_dualdisplay.dtbo"

IMAGE_INSTALL:append = " util-linux-chrt util-linux-taskset util-linux-lscpu"