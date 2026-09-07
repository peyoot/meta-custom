Digi Embedded Yocto, 5.0 R4 realtime version.
About this image : modified on 20260903 , start to support dualdisplay.
20260907: update device tree architechture，支持LVDS和HDMI切换:
    ccmp25-viena.dtb LVDS+SPI触控，主设备树
        ccmp25-viena_ads7846_i2c.dtbo，配合主设备树实现I2C芯片的触控（同时禁掉SPI触控）
        ccmp25-viena_dualdisplay.dtbo, 配合主设备树实现LVDS+HDMI双显切换
    ccmp25-viena-hdmi.dtb 仅HDMI显示器支持
    ccmp25-viena-dualdisplay.dtb  LVDS+HDMI双显切换，默认启动的设备树。


More information, please refer to https://peyoot.github.io



