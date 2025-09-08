# 路径：meta-custom/recipes-core/images/dey-image-qt.bbappend
GLIBC_GENERATE_LOCALES = "zh_CN.UTF-8 en_US.UTF-8"
IMAGE_LINGUAS = "en-us zh-cn"
LOCALE_UTF8_ONLY = "1"

export LANG = "en_US.UTF-8"
export LC_ALL = "en_US.UTF-8"

