#!/bin/sh
if [ -f /etc/pointercal ]; then
    exit 0
fi

# 检测电阻屏是否存在（通过输入设备名称匹配 ADS7846）
if ! grep -q "ADS7846" /proc/bus/input/devices; then
    echo "No resistive touchscreen detected, skipping calibration."
    exit 0
fi

# 如果您的系统能固定使用 /dev/input/event1，可跳过此部分
TSDEVICE=$(grep -A5 "ADS7846" /proc/bus/input/devices | grep -o "event[0-9]\+" | head -1)
if [ -z "$TSDEVICE" ]; then
    echo "Cannot find event device for resistive touchscreen."
    exit 1
fi

export TSLIB_TSDEVICE="/dev/input/$TSDEVICE"
export TSLIB_CALIBFILE="/etc/pointercal"
export TSLIB_CONFFILE="/etc/ts.conf"

# 执行校准
/usr/bin/ts_calibrate
sync