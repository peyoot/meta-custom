#!/bin/sh
# gpio_demo_ctrl.sh - 3击切换三个演示应用

PORT="${1:-GPIOF}"
LINE="${2:-12}"

CLICK_TIMEOUT=0.5          # 连续点击最大间隔（秒）
LONG_PRESS_GAP=2.0         # 长按判定间隔（秒）

# ===== 应用配置 =====
# 每个条目：名称 | 启动命令 | 停止命令
# 注意：webapp 用 /etc/connectcore-demo-example 控制
# bedside-monitor 和 vitalmonitor 直接用二进制
APP0_NAME="WebKit Example"
APP0_START="/etc/connectcore-demo-example-webkit start"
APP0_STOP="/etc/connectcore-demo-example-webkit stop"

APP1_NAME="bedside-monitor"
APP1_START="/usr/bin/bedside-monitor &"
APP1_STOP="pkill -x bedside-monitor"

APP2_NAME="vitalmonitor"
APP2_START="/usr/bin/vitalmonitor &"
APP2_STOP="pkill -x vitalmonitor"

# 当前运行的应用索引（0,1,2），初始为 -1 表示无
CURRENT_INDEX=0

# ===== 辅助函数 =====
parse_timestamp() {
    echo "$1" | sed -n 's/.*\[ *\([0-9.]*\)\].*/\1/p'
}

# 检查某个应用是否在运行
is_running() {
    case "$1" in
        0) # webkit 例程：检查进程名或服务状态
           # 假设 webkit 例程的进程名为 WebKitWebProcess 或类似，这里用 pgrep 模糊匹配
           pgrep -f "WebKitWebProcess\|webkit" >/dev/null 2>&1
           return $?
           ;;
        1) # bedside-monitor
           pgrep -x "bedside-monitor" >/dev/null 2>&1
           return $?
           ;;
        2) # vitalmonitor
           pgrep -x "vitalmonitor" >/dev/null 2>&1
           return $?
           ;;
        *) return 1 ;;
    esac
}

# 启动指定索引的应用
start_app() {
    idx=$1
    case $idx in
        0) echo "[ACTION] Starting $APP0_NAME"
           eval "$APP0_START"
           ;;
        1) echo "[ACTION] Starting $APP1_NAME"
           export WAYLAND_DISPLAY=wayland-1
           export XDG_RUNTIME_DIR=/run/user/0
           export QT_QPA_PLATFORM=wayland
           export LANG=C.UTF-8
           export LC_ALL=C.UTF-8
           eval "$APP1_START"
           sleep 2
           if $PGREP -x "bedside-monitor" >/dev/null 2>&1; then
               echo "[OK] bedside-monitor started"
           else
               echo "[FAIL] bedside-monitor NOT running. Check /tmp/bedside.log"
           fi
           ;;
        2) echo "[ACTION] Starting $APP2_NAME"
           export WAYLAND_DISPLAY=wayland-1
           export XDG_RUNTIME_DIR=/run/user/0
           export QT_QPA_PLATFORM=wayland
           export LANG=C.UTF-8
           export LC_ALL=C.UTF-8
           eval "$APP2_START"
           sleep 2
           if $PGREP -x "vitalmonitor" >/dev/null 2>&1; then
               echo "[OK] vitalmonitor started"
           else
               echo "[FAIL] vitalmonitor NOT running. Check /tmp/vital.log"
           fi
           ;;
    esac
}

# 停止指定索引的应用
stop_app() {
    idx=$1
    case $idx in
        0) echo "[ACTION] Stopping $APP0_NAME"
           eval "$APP0_STOP"
           ;;
        1) echo "[ACTION] Stopping $APP1_NAME"
           eval "$APP1_STOP"
           ;;
        2) echo "[ACTION] Stopping $APP2_NAME"
           eval "$APP2_STOP"
           ;;
    esac
}

# 停止所有应用（无论哪个在运行）
stop_all_apps() {
    echo "[ACTION] Stopping all apps"
    eval "$APP0_STOP"
    eval "$APP1_STOP"
    eval "$APP2_STOP"
    # 等待所有进程退出
    sleep 2
    $PKILL -9 -x "bedside-monitor" 2>/dev/null
    $PKILL -9 -x "vitalmonitor" 2>/dev/null
    # webkit 例程可能也有残留进程，但由其控制脚本处理
}
# 切换到下一个应用
switch_to_next() {
    # 先停止所有应用
    stop_all_apps

    # 计算下一个索引
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % 3 ))
    start_app $NEXT_INDEX
    CURRENT_INDEX=$NEXT_INDEX
    echo "[INFO] Now running: index $CURRENT_INDEX"
}

# ===== 主循环 =====
echo "[DEBUG] Starting guard on $PORT $LINE (3-click cycle)"
echo "[DEBUG] Apps: WebKit Example, bedside-monitor, vitalmonitor"

command -v gpiomon >/dev/null || { echo "[ERROR] gpiomon missing"; exit 1; }

CLICK_COUNT=0
LAST_TIME=0

while true; do
    echo "[DEBUG] Waiting for rising edge (release)..."
    OUTPUT=$(gpiomon --num-events 1 --rising-edge $PORT $LINE 2>&1)
    if [ $? -ne 0 ] || [ -z "$OUTPUT" ]; then
        echo "[ERROR] gpiomon failed: $OUTPUT"
        sleep 1
        continue
    fi

    CURRENT=$(parse_timestamp "$OUTPUT")
    echo "[DEBUG] Rising edge at $CURRENT"

    if [ "$LAST_TIME" != "0" ]; then
        GAP=$(awk "BEGIN{printf \"%.3f\", $CURRENT-$LAST_TIME}")
        echo "[DEBUG] Gap from previous rising edge: $GAP s"

        # 长按判定
        if awk "BEGIN{exit !($GAP >= $LONG_PRESS_GAP)}"; then
            echo "[ACTION] Long press detected (gap $GAP s) -> poweroff"
            poweroff
            CLICK_COUNT=0
            LAST_TIME=$CURRENT
            continue
        fi

        # 短按计数
        if awk "BEGIN{exit !($GAP <= $CLICK_TIMEOUT)}"; then
            CLICK_COUNT=$((CLICK_COUNT + 1))
            echo "[DEBUG] Click count increased to $CLICK_COUNT"
        else
            CLICK_COUNT=1
            echo "[DEBUG] Gap too large, reset click count to 1"
        fi
    else
        CLICK_COUNT=1
        echo "[DEBUG] First click, count=1"
    fi

    LAST_TIME=$CURRENT

    # 检测到3次短按
    if [ "$CLICK_COUNT" -ge 3 ]; then
        echo "[ACTION] 3 clicks detected! Switching to next app..."
        switch_to_next
        CLICK_COUNT=0
        LAST_TIME=0
    fi
done