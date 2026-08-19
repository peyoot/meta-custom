import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    property string label: "ECG"
    property string waveColor: "#34d399"   // 已改为 waveColor，避免冲突
    property string waveform: "ecg"
    property real sampleRate: 240
    property real speed: 30                // 像素/秒，控制滚动速度

    color: "#0d1424"
    radius: 8
    border.color: "#1e293b"
    border.width: 1

    // 数据缓冲区：不限长度，但限制最大容量以防内存溢出
    property var buffer: []

    // 每像素对应的点数（固定值，决定曲线密度）
    readonly property real pixelsPerPoint: 2.0

    // 标签
    Text {
        text: label
        color: "#64748b"
        font.pixelSize: 14
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 8
        z: 1
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var data = buffer
            if (data.length < 2) return

            // 计算需要绘制的点数：画布宽度 / 每像素点数
            var drawCount = Math.min(data.length, Math.floor(width / pixelsPerPoint))
            // 只取最后 drawCount 个点（最新的数据）
            var startIdx = data.length - drawCount
            var slice = data.slice(startIdx)

            var midY = height / 2
            var amp = height * 0.38
            var stepX = width / (slice.length - 1)

            // 绘制波形线
            ctx.strokeStyle = waveColor
            ctx.lineWidth = 2
            ctx.beginPath()
            for (var i = 0; i < slice.length; i++) {
                var x = i * stepX
                var y = midY - slice[i] * amp
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()

            // 笔尖圆点（最右侧的最新数据点）
            var lastIdx = slice.length - 1
            var dotX = lastIdx * stepX
            var dotY = midY - slice[lastIdx] * amp
            ctx.fillStyle = waveColor
            ctx.beginPath()
            ctx.arc(dotX, dotY, 4, 0, 2 * Math.PI)
            ctx.fill()
        }
    }

    // 模拟数据生成
    Timer {
        interval: 1000 / sampleRate
        running: true
        repeat: true
        onTriggered: {
            var val = generateSample(waveform)
            buffer.push(val)
            // 限制缓冲区大小，防止无限增长（保留足够多的点用于滚动）
            if (buffer.length > 5000) {
                buffer.shift()
            }
            canvas.requestPaint()
        }
    }

    // 波形样本生成器（与之前相同）
    function generateSample(type) {
        var t = Date.now() / 1000
        switch(type) {
            case "ecg":
                var phase = (t * 1.2) % 1.0
                if (phase < 0.06) return -0.2 + 1.2 * Math.sin(phase / 0.06 * Math.PI)
                else if (phase < 0.13) return -0.1 + 0.3 * Math.sin((phase - 0.07) / 0.04 * Math.PI)
                else if (phase < 0.17) return -0.3 + 0.5 * Math.sin((phase - 0.135) / 0.035 * Math.PI)
                else return 0.0 + 0.1 * Math.sin(phase * 20)
            case "pleth":
                return 0.5 + 0.4 * Math.sin(t * 2 * Math.PI * 1.2) + 0.1 * Math.sin(t * 2 * Math.PI * 2.4)
            case "resp":
                return 0.5 * Math.sin(t * 2 * Math.PI * 0.3) + 0.1 * Math.sin(t * 2 * Math.PI * 0.6)
            default:
                return Math.sin(t * 2 * Math.PI)
        }
    }

    Component.onCompleted: {
        // 填充初始数据，使画布一开始就有波形
        var initialCount = Math.floor(width / pixelsPerPoint)
        for (var i = 0; i < initialCount; i++) {
            buffer.push(generateSample(waveform))
        }
        canvas.requestPaint()
    }
}