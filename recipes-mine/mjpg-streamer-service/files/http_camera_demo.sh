#!/bin/sh
# /usr/local/bin/mjpg-streamer-start.sh

### 可配置参数（直接修改这里）###
CLOSE_OTHER_WEB="yes"      # 是否关闭占用端口的web服务（yes/no）
WIDTH_PRIORITY=(800 1024 1280 640)  # 宽度优先级列表
DEFAULT_RES="640x480"               # 保底分辨率
TARGET_WIDTH=800           # 期望宽度
TARGET_HEIGHT=600          # 期望高度
FRAMERATE=15               # 帧率设置
DEFAULT_PORT=80            # 首选端口
ALT_PORT_START=8080        # 备用端口起始
MAX_PORT_TRY=3             # 最大端口尝试次数
WEB_ROOT="/srv/mjpg_streamer/www"   #mjpg_streamer web

### 创建网页目录和默认页面 ###
mkdir -p ${WEB_ROOT}
if [ ! -f "${WEB_ROOT}/index.html" ]; then
    cat > ${WEB_ROOT}/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Camera Stream</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { margin: 0; background: #000; }
        img { width: 100%; height: 100vh; object-fit: contain; }
    </style>
</head>
<body>
    <img src="./?action=stream">
</body>
</html>
EOF
    echo "Created default index.html in ${WEB_ROOT}"
fi


### 硬件检测函数 ###
detect_usb_device() {
    v4l2-ctl --list-devices | awk '
        !/^[[:space:]]*\/dev\/video[0-9]+/ && !/^$/ {
            desc = tolower($0)
            if ((desc ~ /camera/ && desc ~ /usb/) || (desc ~ /lrcp/ && desc ~ /usb/)) {
                matched = 1
                next
            }
        }
        matched && /^[[:space:]]*\/dev\/video[0-9]+/ {
            print $1
            exit
        }
        /^$/ { matched = 0 }
    '
}

### 分辨率选择函数 ###
select_resolution() {
    local dev=$1
    v4l2-ctl -d $dev --list-formats-ext | awk -v widths="${WIDTH_PRIORITY[*]}" \
        -v default="$DEFAULT_RES" \
        -v framerate="$FRAMERATE" '
        BEGIN {
            split(widths, width_pri, " ")  # 解析优先级列表
            best_res = default
            best_fmt = "unknown"
            delete candidates
        }

        # 提取像素格式
        /^[[:space:]]*\[[0-9]+\]:/ {
            split($2, tmp, "'\''")
            current_fmt = tmp[2]
        }

        # 提取分辨率
        /Size: Discrete/ {
            split($3, res, /x/)
            current_w = res[1] + 0
            current_h = res[2] + 0
        }

        # 处理帧率
        /Interval: Discrete.*\([0-9]+\.[0-9]+.*fps\)/ {
            if (current_fmt == "MJPG" && current_w) {
                split($(NF-1), fps_arr, /\(|\)/)
                current_fps = fps_arr[2] + 0
                if (current_fps >= framerate) {
                    candidates[current_w] = current_w "x" current_h
                }
            }
        }

        END {
            for (i = 1; i <= length(width_pri); i++) {
                target_w = width_pri[i] + 0
                if (target_w in candidates) {
                    best_res = candidates[target_w]
                    best_fmt = "MJPG"
                    break
                }
            }
            print best_fmt " " best_res
        }
    '
}

### 端口管理增强函数 ###
manage_port() {
    local port=$1
    # 检测端口占用
    if netstat -tuln | awk -v p=":$port$" '$4 ~ p {exit 1}'; then
        return 0
    else
        [ "$CLOSE_OTHER_WEB" = "yes" ] && {
            echo "强制释放端口 $port ..."
            # 获取占用进程的PID
            pids=$(netstat -ltnp 2>/dev/null | 
                   awk -v p=":$port$" '$4 ~ p {split($7,a,"/");print a[1]}' |
                   xargs -r)
            
            # 终止占用进程
            [ -n "$pids" ] && {
                kill -9 $pids && sleep 1
                echo "已终止进程：$pids"
            }
        }
        # 再次检测
        netstat -tuln | awk -v p=":$port$" '$4 ~ p {exit 1}'
        return $?
    fi
}

### 主程序流程 ###
# 检测USB摄像头
CAM_DEVICE=$(detect_usb_device)
[ -z "$CAM_DEVICE" ] && {
    echo "[ERROR] 未检测到USB摄像头"
    exit 1
}

# 端口选择逻辑（修正语法错误）
for try_port in $(seq $DEFAULT_PORT $((DEFAULT_PORT + MAX_PORT_TRY))) \
                $(seq $ALT_PORT_START $((ALT_PORT_START + MAX_PORT_TRY))); do
    if manage_port $try_port; then
        USABLE_PORT=$try_port
        break
    fi
done

[ -z "$USABLE_PORT" ] && {
    echo "[ERROR] 找不到可用端口（尝试了从$DEFAULT_PORT到$((DEFAULT_PORT + MAX_PORT_TRY))" \
                "以及$ALT_PORT_START到$((ALT_PORT_START + MAX_PORT_TRY))）"
    exit 2
}


# 获取最佳分辨率配置
IFS=' ' read -r pixel_format resolution < <(select_resolution $CAM_DEVICE)

# 解析分辨率
IFS='x' read -r width height <<< "$resolution"

echo "[INFO] 选定配置：格式=${pixel_format} 分辨率=${width}x${height} 帧率=${FRAMERATE}"

# 配置摄像头参数
if [ "$pixel_format" != "unknown" ]; then
    v4l2-ctl -d $CAM_DEVICE \
        --set-fmt-video=width=$width,height=$height,pixelformat=$pixel_format \
        --set-parm=$FRAMERATE
else
    echo "[WARNING] 未找到满足条件的分辨率，使用默认配置"
    IFS='x' read -r width height <<< "$DEFAULT_RES"
    v4l2-ctl -d $CAM_DEVICE \
        --set-fmt-video=width=$width,height=$height,pixelformat=MJPG \
        --set-parm=$FRAMERATE
fi

# 启动服务
echo "启动视频流服务：$USABLE_PORT端口，分辨率自动适配"
exec mjpg_streamer \
  -i "input_uvc.so -d $CAM_DEVICE -f $FRAMERATE" \
  -o "output_http.so -p $USABLE_PORT -w /srv/mjpg_streamer/www"

