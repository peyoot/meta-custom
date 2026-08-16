#!/bin/bash
# gpio_ctrl.sh - 只监听上升沿，兼容旧版 gpiomon

PORT="${1:-GPIOF}"
LINE="${2:-12}"
QT_APP="QtDemo"
QT_PATH="/usr/share/qt5everywheredemo-1.0/QtDemo"

CLICK_TIMEOUT=0.5
LONG_PRESS_GAP=2.0

echo "[DEBUG] Starting guard on $PORT $LINE (only rising edge)"
echo "[DEBUG] QtDemo path: $QT_PATH"

command -v gpiomon >/dev/null || { echo "[ERROR] gpiomon missing"; exit 1; }

parse_timestamp() {
    echo "$1" | sed -n 's/.*\[ *\([0-9.]*\)\].*/\1/p'
}

toggle_qt() {
    PID=$(pgrep -x "$QT_APP" | head -1)
    if [ -n "$PID" ]; then
        echo "  -> Killing $QT_APP (PID=$PID)"
        kill -TERM "$PID" 2>/dev/null
        sleep 1
        kill -KILL "$PID" 2>/dev/null
    else
        echo "  -> Starting $QT_APP"
        "$QT_PATH" &
    fi
}

CLICK_COUNT=0
LAST_TIME=0

while true; do
    echo "[DEBUG] Waiting for rising edge (release)..."
    # 注意：$PORT 和 $LINE 不加引号，作为两个独立参数
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

        # 长按判定：间隔 >= LONG_PRESS_GAP
        if awk "BEGIN{exit !($GAP >= $LONG_PRESS_GAP)}"; then
            echo "[ACTION] Long press detected (gap $GAP s) -> poweroff"
            poweroff
            CLICK_COUNT=0
            LAST_TIME=$CURRENT
            continue
        fi

        # 短按计数：间隔 <= CLICK_TIMEOUT
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

    # 检查是否达到 3 次
    if [ "$CLICK_COUNT" -ge 3 ]; then
        echo "[ACTION] 3 clicks detected! Toggling QtDemo..."
        toggle_qt
        CLICK_COUNT=0
        LAST_TIME=0
    fi
done