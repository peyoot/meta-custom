#
# Copyright (C) 2023 Digi International Inc.
#
SUMMARY = "LVGL packagegroup for DEY image"

PACKAGE_ARCH = "${MACHINE_ARCH}"
inherit packagegroup

# PROVIDES = "dey-mono"

RDEPENDS_${PN} = " \
    msbuild \
    dotnet \
    dotnet-helloworld \
    python3-pythonnet \
"
