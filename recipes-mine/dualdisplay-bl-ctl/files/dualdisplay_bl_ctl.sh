#!/bin/sh

# 使用 gpiod 工具监控 HPD，无需数字编号
gpiomon -f --chip gpiod 2 | while read line; do
    case "$line" in
        *FALLING*)
            # HDMI 拔出
            echo 7 > /sys/class/backlight/panel-lvds-pwm-backlight/brightness
            ;;
        *RISING*)
            # HDMI 插入
            echo 0 > /sys/class/backlight/panel-lvds-pwm-backlight/brightness
            ;;
    esac
done