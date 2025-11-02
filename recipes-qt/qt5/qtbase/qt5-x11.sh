#!/bin/sh

# Set up Qt for X11
export QT_QPA_PLATFORM=xcb
export QT_X11_NO_MITSHM=1

# Optional: Set DPI and scaling if needed
# export QT_FONT_DPI=96
# export QT_SCALE_FACTOR=1.0

# Enable software rendering if needed
# export QT_QUICK_BACKEND=software