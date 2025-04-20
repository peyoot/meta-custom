#!/bin/sh
# /usr/local/bin/mjpg-streamer-start.sh

### 可配置参数（直接修改这里）###
CLOSE_OTHER_WEB="yes"      # 是否关闭占用端口的web服务（yes/no）
TARGET_WIDTH=800           # 期望宽度
TARGET_HEIGHT=600          # 期望高度
FRAMERATE=30               # 帧率设置
DEFAULT_PORT=80            # 首选端口
ALT_PORT_START=8080        # 备用端口起始
MAX_PORT_TRY=3             # 最大端口尝试次数

### 硬件检测函数 ###
detect_usb_device() {
    v4l2-ctl --list-devices | awk '
        /USB Camera/ {
            usb_cam=1
            next
        }
        usb_cam && /\/dev\/video[0-9]+/ {
            print $1
            exit
        }
        /^$/ { usb_cam=0 }
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

# 配置摄像头参数
v4l2-ctl -d $CAM_DEVICE \
    --set-fmt-video=pixelformat=MJPG \
    --set-parm=$FRAMERATE

# 启动服务
echo "启动视频流服务：$USABLE_PORT端口，分辨率自动适配"
exec mjpg_streamer \
  -i "input_uvc.so -d $CAM_DEVICE -f $FRAMERATE" \
  -o "output_http.so -p $USABLE_PORT -w /tmp/mjpg_streamer"

