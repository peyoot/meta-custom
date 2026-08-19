import QtQuick
import "HeartData.js" as HD

// 医院监护仪风格的「扫描头」波形。
// 一个亮点从左向右扫描绘制波形，头部前方留擦除间隙，扫到右缘回卷。
// 这样即使在嵌入式设备上也只做增量绘制，流畅且真实。
Item {
    id: root

    property color traceColor: "#34d399"
    property color gridColor:  "#10251b"
    property real  rate:       72        // 本波形的节律（次/分）
    property string waveType:  "ecg"     // ecg | pleth | resp
    property real  gain:       0.42      // 幅度占高度的比例
    property real  baselineFrac: 0.5         // 基线位置（高度比例，0=顶 1=底）
    property int   sweepSpeed: 3         // 每帧前进像素
    property int   tickMs:     24        // 帧间隔
    property bool  running:    true

    clip: true

    // ---- 静态网格（只画一次）----
    Canvas {
        id: grid
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = gridColor
            ctx.lineWidth = 1
            for (var x = 0; x < width; x += 12) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
            }
            for (var y = 0; y < height; y += 12) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
            }
            // 基线
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05)
            ctx.beginPath()
            ctx.moveTo(0, height * baselineFrac); ctx.lineTo(width, height * baselineFrac); ctx.stroke()
        }
        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()
    }

    // ---- 波形轨迹（透明画布，只增量绘制描边）----
    Canvas {
        id: trace
        anchors.fill: parent

        property real headX: 0
        property real phase: 0
        property real prevX: 0
        property real prevY: height * baselineFrac

        function sample(ph) {
            if (waveType === "ecg")   return HD.ecgAmplitude(ph)
            if (waveType === "pleth") return HD.plethAmplitude(ph) - 0.55
            return HD.respAmplitude(ph)
        }

        // 尺寸变化时清空重置，避免错位
        // available 为 false 时画布尚未就绪，此时调用 getContext() 只会打印警告
        function resetTrace() {
            headX = 0; phase = 0; prevX = 0; prevY = height * baselineFrac
            if (!available) return
            var ctx = getContext("2d")
            if (ctx) ctx.reset()
        }
        onWidthChanged:  resetTrace()
        onHeightChanged: resetTrace()
        onAvailableChanged: if (available) resetTrace()

        onPaint: {
            var w = width, h = height
            if (w <= 0 || h <= 0) return
            var ctx = getContext("2d")

            var pxPerSec = sweepSpeed * (1000 / tickMs)
            var period   = 60.0 / Math.max(rate, 1)     // 每个周期秒数
            var dphase   = (1.0 / pxPerSec) / period

            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.strokeStyle = traceColor
            ctx.beginPath()
            ctx.moveTo(prevX, prevY)

            for (var s = 0; s < sweepSpeed; s++) {
                headX += 1
                phase += dphase; if (phase >= 1) phase -= 1

                if (headX >= w) {                        // 回卷到左缘
                    ctx.stroke()
                    headX = 0
                    var y0 = h * baselineFrac - sample(phase) * gain * h
                    ctx.beginPath(); ctx.moveTo(0, y0)
                    prevX = 0; prevY = y0
                    continue
                }

                var y = h * baselineFrac - sample(phase) * gain * h
                ctx.lineTo(headX, y)
                prevX = headX; prevY = y
            }
            ctx.stroke()

            // 头部前方擦除间隙（露出下层网格）
            ctx.clearRect(headX + 2, 0, 20, h)
        }

        // 扫描头亮点
        Rectangle {
            width: 4; height: 4; radius: 2
            color: traceColor
            x: trace.headX - 1
            y: trace.prevY - 2
            visible: root.running
        }
    }

    Timer {
        interval: tickMs
        running: root.running && root.visible
        repeat: true
        onTriggered: trace.requestPaint()
    }
}
