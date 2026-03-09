#!/bin/sh
if [ -f /etc/pointercal ]; then
    exit 0
fi

# check ads7846 compatible hardware connection
if ! grep -q "ADS7846" /proc/bus/input/devices; then
    echo "No resistive touchscreen detected, skipping calibration."
    exit 0
fi

# auto detect input event name for touch screen
TSDEVICE=$(grep -A5 "ADS7846" /proc/bus/input/devices | grep -o "event[0-9]\+" | head -1)
if [ -z "$TSDEVICE" ]; then
    echo "Cannot find event device for resistive touchscreen."
    exit 1
fi

export TSLIB_TSDEVICE="/dev/input/$TSDEVICE"
export TSLIB_CALIBFILE="/etc/pointercal"
export TSLIB_CONFFILE="/etc/ts.conf"

/usr/bin/ts_calibrate
sync