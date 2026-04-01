# meta-custom/recipes-core/images/core-image-base.bbappend
# 与 meta-digi-dey 的 core-image-base.bbappend 合并生效

# ==================== 设备树追加（针对 ccmp25-viena） ====================
KERNEL_DEVICETREE:append:ccmp25-dvk = " ccmp25-viena.dtb ccmp25-viena_ads7846.dtbo"


# ==================== 2. 网络配置：使用 /etc/network/interfaces + udhcpc ====================
# 从最终镜像移除不需要的网络相关包
IMAGE_INSTALL:remove = " \
    networkmanager \
    modemmanager \
    ppp \
    batctl \
    vsftpd \
    bluez bluez5 bluez5-init bluez-obex \
    packagegroup-dey-bluetooth \
    bluetooth \
    bluetoothd \
    wpa-supplicant \
"

# 从 packagegroup 源头移除（减少 warning）
RDEPENDS:packagegroup-dey-network:remove = " modemmanager ppp batctl "
# 从可能拉入 bluetooth 的 packagegroup 中移除（减少 warning）
RDEPENDS:packagegroup-dey-bluetooth:remove = "bluez5 bluez5-init"
RDEPENDS:packagegroup-dey-core:remove = "packagegroup-dey-bluetooth"

# 禁用 bluetooth init 脚本启动（sysvinit 下关键）
UPDATE-RC.D:pn-bluez5 = "0"
UPDATE-RC.D:pn-bluez5-init = "0"
UPDATE-RC.D:pn-bluetooth = "0"

# 添加传统网络支持
IMAGE_INSTALL:append = " init-ifupdown"

# ==================== 3. 彻底移除 swupdate ====================
IMAGE_INSTALL:remove = " swupdate swupdate-config swupdate-tools swupdate-progress swupdate-webserver libswupdate "
# 阻止 swupdate 服务自动启动（sysvinit 下关键）
SYSTEMD_AUTO_ENABLE:pn-swupdate = "0" 
UPDATE-RC.D:pn-swupdate = "0" 
ROOTFS_POSTPROCESS_COMMAND:remove = " create_sw_versions_file "


# ==================== 4. 额外瘦身（适合实时 Linux） ====================
IMAGE_FEATURES:remove = " eclipse-debug dbg-pkgs tools-debug tools-profile tools-testapps dev-pkgs package-management "

# 抑制调试符号，减小体积
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

# 保险起见（虽然 swupdate 已移除）
SYSTEMD_AUTO_ENABLE:pn-swupdate = "0"

# ==================== 5. 移除 dbus（减少后台进程和内存占用） ====================
IMAGE_INSTALL:remove = " \
    dbus \
    dbus-daemon \
    dbus-glib \
    dbus-lib \
    libdbus \
    messagebus \
"

# 如果某些 packagegroup 强拉 dbus，可额外清理（减少 warning）
RDEPENDS:packagegroup-dey-core:remove = "dbus"
RDEPENDS:packagegroup-dey-network:remove = "dbus"   # 如果有的话

# 阻止 dbus 服务启动（sysvinit 下）
UPDATE-RC.D:pn-dbus = "0"