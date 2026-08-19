import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    property string label: "ECG"
    property string waveColor: "#34d399"   // 改为 waveColor，避免与内置 color 冲突
    property string waveform: "ecg"
    property real sampleRate: 240
    property real speed: 30

    // 背景色使用内置 color 属性
    color: "#0d1424"
    radius: 8
    border.color: "#1e293b"
    border.width: 1

    property var buffer: []
    property int maxPoints: 0
    property real lastValue: 0

    onWidthChanged: updateMaxPoints()
    onSpeedChanged: updateMaxPoints()

    function updateMaxPoints() {
        maxPoints = Math.max(10, Math.round(width * sampleRate / speed))
        if (buffer.length > maxPoints) {
            buffer = buffer.slice(buffer.length - maxPoints)
        }
        canvas.requestPaint()
    }

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

            if (buffer.length < 2) return

            var midY = height / 2
            var amp = height * 0.38
            var stepX = width / (buffer.length - 1)

            // 使用 waveColor 绘制波形
            ctx.strokeStyle = waveColor
            ctx.lineWidth = 2
            ctx.beginPath()
            for (var i = 0; i < buffer.length; i++) {
                var x = i * stepX
                var y = midY - buffer[i] * amp
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()

            // 笔尖圆点
            var lastIdx = buffer.length - 1
            var dotX = lastIdx * stepX
            var dotY = midY - buffer[lastIdx] * amp
            ctx.fillStyle = waveColor
            ctx.beginPath()
            ctx.arc(dotX, dotY, 4, 0, 2 * Math.PI)
            ctx.fill()
        }
    }

    Timer {
        interval: 1000 / sampleRate
        running: true
        repeat: true
        onTriggered: {
            var val = generateSample(waveform)
            buffer.push(val)
            if (buffer.length > maxPoints) {
                buffer.shift()
            }
            canvas.requestPaint()
        }
    }

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
        updateMaxPoints()
        while (buffer.length < maxPoints) {
            buffer.push(generateSample(waveform))
        }
        canvas.requestPaint()
    }
}