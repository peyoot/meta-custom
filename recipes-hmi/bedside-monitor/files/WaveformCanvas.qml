import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    property string label: "ECG"
    property string color: "#34d399"
    property string waveform: "ecg"
    property real sampleRate: 240       // 采样率（Hz）
    property real speed: 30             // 滚动速度（像素/秒），决定数据点密度

    color: "#0d1424"
    radius: 8
    border.color: "#1e293b"
    border.width: 1

    // 数据缓冲区：固定长度，环形队列思想（实际用 shift/push）
    property var buffer: []
    property int maxPoints: 0
    property real lastValue: 0

    // 根据宽度计算最大点数（每像素多少个点由 speed 决定）
    onWidthChanged: updateMaxPoints()
    onSpeedChanged: updateMaxPoints()

    function updateMaxPoints() {
        // 每秒钟显示 speed 像素宽度的数据，采样率 sampleRate，所以每像素对应 sampleRate/speed 个点
        // 为了简化，我们让 maxPoints = width * sampleRate / speed
        maxPoints = Math.max(10, Math.round(width * sampleRate / speed))
        // 如果缓冲区太长，截断
        if (buffer.length > maxPoints) {
            buffer = buffer.slice(buffer.length - maxPoints)
        }
        canvas.requestPaint()
    }

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

            if (buffer.length < 2) return

            var midY = height / 2
            var amp = height * 0.38      // 振幅为高度的38%，留边
            var stepX = width / (buffer.length - 1)

            // 绘制波形线
            ctx.strokeStyle = color
            ctx.lineWidth = 2
            ctx.beginPath()
            for (var i = 0; i < buffer.length; i++) {
                var x = i * stepX
                var y = midY - buffer[i] * amp
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()

            // 绘制最右侧的笔尖圆点（最后一个数据点）
            var lastIdx = buffer.length - 1
            var dotX = lastIdx * stepX
            var dotY = midY - buffer[lastIdx] * amp
            ctx.fillStyle = color
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
            if (buffer.length > maxPoints) {
                buffer.shift()   // 移除最旧的数据，实现滚动
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
        updateMaxPoints()
        // 填充初始数据
        while (buffer.length < maxPoints) {
            buffer.push(generateSample(waveform))
        }
        canvas.requestPaint()
    }
}