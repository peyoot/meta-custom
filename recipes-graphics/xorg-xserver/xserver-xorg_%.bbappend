# 确保 xvfb 子包被主包运行时依赖，这样它就会被自动安装
RRECOMMENDS:${PN} += "${PN}-xvfb"