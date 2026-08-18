import QtQuick

Rectangle {
    property string label
    property string color
    property string waveform  // "ecg" | "pleth" | "resp"

    color: "#0d1424"
    radius: 8
    border.color: "#1e293b"
    border.width: 1

    Text {
        text: label
        color: color
        font.bold: true
        font.pixelSize: 18
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 12
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.topMargin: 44
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 10

        property var points: []
        property int maxPoints: 0

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // 网格
            ctx.strokeStyle = "#131c2e"
            ctx.lineWidth = 1
            for (var gx = 0; gx < width; gx += 30) {
                ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke()
            }
            for (var gy = 0; gy < height; gy += 30) {
                ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke()
            }

            // 波形
            if (points.length < 2) return
            ctx.strokeStyle = color
            ctx.lineWidth = 2.5
            ctx.beginPath()
            for (var i = 0; i < points.length; i++) {
                var px = (i / maxPoints) * width
                var py = height / 2 - points[i] * (height / 2 - 15)
                if (i === 0) ctx.moveTo(px, py)
                else ctx.lineTo(px, py)
            }
            ctx.stroke()

            // 扫描线效果
            ctx.fillStyle = color
            ctx.globalAlpha = 0.3
            var scanX = (points.length / maxPoints) * width
            ctx.fillRect(scanX - 2, 0, 4, height)
            ctx.globalAlpha = 1.0
        }

        Timer {
            interval: 40
            running: true
            repeat: true
            property int t: 0
            onTriggered: {
                t += 1
                var phase = (t % 250) / 250.0
                var v = 0
                switch(waveform) {
                case "ecg":
                    if (phase < 0.1) v = Math.sin(phase * 10 * Math.PI) * 0.15;
                    else if (phase >= 0.15 && phase < 0.25) {
                        if (phase < 0.17) v = -0.25;
                        else if (phase < 0.19) v = 1.0;
                        else if (phase < 0.21) v = -0.35;
                    }
                    else if (phase >= 0.35 && phase < 0.5) v = Math.sin((phase-0.35) * 6 * Math.PI) * 0.2;
                    break;
                case "pleth":
                    v = Math.exp(-Math.pow((phase - 0.2) * 4, 2)) + 0.3 * Math.exp(-Math.pow((phase - 0.5) * 6, 2));
                    break;
                case "resp":
                    v = Math.sin(phase * 2 * Math.PI) * 0.7;
                    break;
                }
                canvas.points.push(v)
                if (canvas.points.length > canvas.maxPoints) {
                    canvas.points.shift()
                }
                canvas.requestPaint()
            }
        }

        Component.onCompleted: {
            maxPoints = Math.floor(width / 4)
        }
    }
}