# Copyright (C) 2023-2025 Your Company Name

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# Replace the original load_iw612.sh with our custom version
SRC_URI:remove = "file://load_iw612.sh"
SRC_URI:append = " file://load_iw612.sh"