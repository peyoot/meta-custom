import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    property string label: "ECG"
    property string waveColor: "#34d399"
    property string waveform: "ecg"
    property real sampleRate: 240
    property real pixelsPerSecond: 25   // 25 mm/s 标准心电走纸速度

    color: "#0d1424"
    radius: 8
    border.color: "#1e293b"
    border.width: 1
    clip: true

    // ---------- 数据 ----------
    property var buffer: []   // 存 {t, v}，t 为相对时间(秒)，v 为归一化值
    property real startTime: 0

    // ---------- 背景网格 ----------
    Canvas {
        id: gridCanvas
        anchors.fill: parent
        z: 0
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // 网格参数（模拟 5mm 大格 / 1mm 小格）
            var big = 50   // 大格间距(像素)，对应 1 秒 @25px/s
            var small = 10  // 小格间距

            // 小格
            ctx.strokeStyle = "#111827"
            ctx.lineWidth = 1
            ctx.beginPath()
            for (var x = 0; x < width; x += small) {
                ctx.moveTo(x + 0.5, 0)
                ctx.lineTo(x + 0.5, height)
            }
            for (var y = 0; y < height; y += small) {
                ctx.moveTo(0, y + 0.5)
                ctx.lineTo(width, y + 0.5)
            }
            ctx.stroke()

            // 大格
            ctx.strokeStyle = "#1f2937"
            ctx.lineWidth = 1.5
            ctx.beginPath()
            for (var X = 0; X < width; X += big) {
                ctx.moveTo(X + 0.5, 0)
                ctx.lineTo(X + 0.5, height)
            }
            for (var Y = 0; Y < height; Y += big) {
                ctx.moveTo(0, Y + 0.5)
                ctx.lineTo(width, Y + 0.5)
            }
            ctx.stroke()

            // 中线（零位参考）
            ctx.strokeStyle = "#374151"
            ctx.lineWidth = 1
            ctx.setLineDash([4, 4])
            ctx.beginPath()
            ctx.moveTo(0, height / 2 + 0.5)
            ctx.lineTo(width, height / 2 + 0.5)
            ctx.stroke()
            ctx.setLineDash([])
        }
    }

    // ---------- 波形画布 ----------
    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        z: 1

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            if (buffer.length < 2) return

            var now = (Date.now() / 1000) - startTime
            var midY = height / 2
            var amp = height * 0.38

            ctx.strokeStyle = waveColor
            ctx.lineWidth = 2
            ctx.beginPath()

            for (var i = 0; i < buffer.length; i++) {
                var sample = buffer[i]
                var age = now - sample.t
                var x = width - age * pixelsPerSecond
                if (x < -5 || x > width + 5) continue  // 屏幕外丢弃
                var y = midY - sample.v * amp
                if (i === 0 || buffer[i - 1].t > sample.t) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()

            // 笔尖圆点（最新点，紧贴右侧）
            var last = buffer[buffer.length - 1]
            var lx = width - (now - last.t) * pixelsPerSecond
            var ly = midY - last.v * amp
            ctx.fillStyle = waveColor
            ctx.beginPath()
            ctx.arc(lx, ly, 4, 0, 2 * Math.PI)
            ctx.fill()
        }
    }

    // ---------- 时间轴标签 ----------
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 6
        spacing: 6
        z: 2
        Text { text: "1s/div"; color: "#4b5563"; font.pixelSize: 10 }
    }

    // ---------- 采样 Timer ----------
    Timer {
        interval: 1000 / sampleRate
        running: true
        repeat: true
        onTriggered: {
            var t = (Date.now() / 1000) - startTime
            var v = generateSample(waveform)
            buffer.push({ t: t, v: v })

            // 只保留屏幕内+1秒的数据
            var cutoff = t - (width / pixelsPerSecond) - 1
            while (buffer.length > 0 && buffer[0].t < cutoff) {
                buffer.shift()
            }

            canvas.requestPaint()
        }
    }

    // ---------- 波形生成 ----------
    function generateSample(type) {
        var t = Date.now() / 1000
        switch (type) {
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

    // ---------- 初始化 ----------
    Component.onCompleted: {
        startTime = Date.now() / 1000
        canvas.requestPaint()
        gridCanvas.requestPaint()
    }

    // 尺寸变化时重绘网格
    onWidthChanged: gridCanvas.requestPaint()
    onHeightChanged: gridCanvas.requestPaint()
}