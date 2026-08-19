import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: window
    visible: true
    visibility: Window.FullScreen
    color: "#0a0e17"
    title: "Vital Monitor (Qt6)"

    // 全局趋势数据数组
    property var trendData: []

    // ============ 顶部状态栏 ============
    Rectangle {
        id: topBar
        width: parent.width
        height: 48
        color: "#111827"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: "CARDIAC MONITOR"
            color: "#f87171"
            font.bold: true
            font.pixelSize: 18
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: "● LIVE"
            color: "#34d399"
            font.pixelSize: 14
        }
    }

    // ============ 左侧：ECG 波形 ============
    Rectangle {
        id: ecgPanel
        anchors.top: topBar.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        width: parent.width * 0.62
        height: parent.height - topBar.height - 20
        color: "#0d1424"
        radius: 8
        border.color: "#1e293b"
        border.width: 1

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 12
            text: "ECG II"
            color: "#34d399"
            font.bold: true
            font.pixelSize: 16
        }

        Canvas {
            id: ecgCanvas
            anchors.fill: parent
            anchors.topMargin: 40
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 10

            property var points: []
            property int maxPoints: 0

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // 网格
                ctx.strokeStyle = "#152033"
                ctx.lineWidth = 1
                for (var gx = 0; gx < width; gx += 20) {
                    ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, height); ctx.stroke()
                }
                for (var gy = 0; gy < height; gy += 20) {
                    ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke()
                }

                // ECG 波形
                if (points.length < 2) return
                ctx.strokeStyle = "#34d399"
                ctx.lineWidth = 2
                ctx.beginPath()
                for (var i = 0; i < points.length; i++) {
                    var px = (i / maxPoints) * width
                    var py = height / 2 - points[i] * (height / 2 - 20)
                    if (i === 0) ctx.moveTo(px, py)
                    else ctx.lineTo(px, py)
                }
                ctx.stroke()
            }

            // ECG 数据生成（PQRST 复合波）
            Timer {
                interval: 30
                running: true
                repeat: true
                property int t: 0
                onTriggered: {
                    t += 1
                    var v = 0
                    var phase = (t % 100) / 100.0
                    if (phase < 0.1) v = Math.sin(phase * 10 * Math.PI) * 0.1
                    else if (phase >= 0.15 && phase < 0.25) {
                        if (phase < 0.17) v = -0.2
                        else if (phase < 0.19) v = 1.0
                        else if (phase < 0.21) v = -0.3
                    }
                    else if (phase >= 0.35 && phase < 0.5) v = Math.sin((phase-0.35) * 6 * Math.PI) * 0.15
                    else v = 0

                    ecgCanvas.points.push(v)
                    if (ecgCanvas.points.length > ecgCanvas.maxPoints) {
                        ecgCanvas.points.shift()
                    }
                    ecgCanvas.requestPaint()
                }
            }

            Component.onCompleted: {
                maxPoints = Math.floor(width / 3)
            }
        }
    }

    // ============ 右侧：数值面板 ============
    Column {
        anchors.top: topBar.bottom
        anchors.topMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        width: parent.width * 0.33
        height: parent.height - topBar.height - 20
        spacing: 10

        // HR
        VitalsBlock {
            width: parent.width
            height: 140
            label: "HR"
            value: hrValue
            unit: "bpm"
            color: "#34d399"
        }
        // SpO2
        VitalsBlock {
            width: parent.width
            height: 140
            label: "SpO₂"
            value: spo2Value
            unit: "%"
            color: "#60a5fa"
        }
        // RESP
        VitalsBlock {
            width: parent.width
            height: 140
            label: "RESP"
            value: respValue
            unit: "br/min"
            color: "#fbbf24"
        }
        // 心率柱形趋势
        Rectangle {
            width: parent.width
            height: parent.height - 140 * 3 - 20 - 20
            color: "#0d1424"
            radius: 8
            border.color: "#1e293b"
            border.width: 1

            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                text: "TREND"
                color: "#64748b"
                font.pixelSize: 14
            }

            Canvas {
                id: trendCanvas
                anchors.fill: parent
                anchors.topMargin: 30
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var n = window.trendData.length
                    if (n < 2) return
                    ctx.strokeStyle = "#f87171"
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    for (var i = 0; i < n; i++) {
                        var px = (i / (n - 1)) * width
                        var py = height - (window.trendData[i] / 200) * height
                        if (i === 0) ctx.moveTo(px, py)
                        else ctx.lineTo(px, py)
                    }
                    ctx.stroke()
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    window.trendData.push(window.hrValue)
                    if (window.trendData.length > 60) window.trendData.shift()
                    trendCanvas.requestPaint()
                }
            }
        }
    }

    // ============ 数据驱动 ============
    property int hrValue: 72
    property int spo2Value: 98
    property int respValue: 16

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            hrValue = 65 + Math.floor(Math.random() * 30)
            spo2Value = 95 + Math.floor(Math.random() * 5)
            respValue = 12 + Math.floor(Math.random() * 8)
        }
    }

    // ============ VitalsBlock 组件 ============
    component VitalsBlock: Rectangle {
        property string label
        property int value
        property string unit
        property string color
        color: "#0d1424"
        radius: 8
        border.color: "#1e293b"
        border.width: 1

        Text {
            text: label
            color: "#64748b"
            font.pixelSize: 16
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 12
        }
        Text {
            text: value.toString()
            color: color
            font.bold: true
            font.pixelSize: 56
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
        }
        Text {
            text: unit
            color: "#64748b"
            font.pixelSize: 16
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
        }

        Behavior on value {
            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
        }
    }
}