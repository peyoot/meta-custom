# 禁用 vulkansink 插件以避免窗口系统依赖
PACKAGECONFIG:remove = "vulkan"

# 可选：确保其他不必要的插件也被禁用（根据需要调整）
PACKAGECONFIG:remove = "wayland x11"

# 确保 gstreamer 核心功能正常
PACKAGECONFIG:append = " fbdev"