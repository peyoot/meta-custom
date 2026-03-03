# 因为 meta-custom 优先级更高，这个 prepend 会晚于 digi 的 bbappend 执行，所以我们的路径会排在 digi 前面
FILESEXTRAPATHS:prepend:dey := "${THISDIR}/files:"

# 可选：显式重新声明一次（保险起见，推荐加上）
SPLASH_IMAGES = "file://logo.png;outsuffix=default"