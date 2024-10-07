#
# Copyright (C) 2016-2023 Digi International.
#
require recipes-core/images/dey-image-graphical.inc

DESCRIPTION = "DEY image with dotnet support"

GRAPHICAL_CORE = "mono"

require recipes-sato/images/core-image-sato.bb
require recipes-mono/images/core-image-mono.inc

CORE_IMAGE_EXTRA_INSTALL += " \
    ${@bb.utils.contains('IMAGE_FEATURES', 'dey-mono', ' msbuild dotnet dotnet-helloworld python3-pythonnet', '', d)} \
"

GLIBC_GENERATE_LOCALES = "zh_CN.UTF-8 en_GB.UTF-8 en_US.UTF-8" 
IMAGE_LINGUAS = "en-us"
LOCALE_UTF8_ONLY="1"
