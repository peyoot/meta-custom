import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 心电监测主界面：三条扫描波形 + 大号数值 + 返回配置
Item {
    id: page
    property var patient

    signal exitRequested()

    // ---- 实时数值 ----
    property int hr:   72
    property int spo2: 98
    property int resp: 16
    property var trendData: []
    property string clock: ""

    Timer {   // 生命体征模拟
        interval: 1500; running: page.visible; repeat: true
        onTriggered: {
            hr   = 66 + Math.floor(Math.random() * 22)
            spo2 = 95 + Math.floor(Math.random() * 5)
            resp = 13 + Math.floor(Math.random() * 7)
            trendData.push(hr)
            if (trendData.length > 60) trendData.shift()
            trendCanvas.requestPaint()
        }
    }
    Timer {   // 时钟
        interval: 1000; running: page.visible; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            clock = Qt.formatDateTime(d, "yyyy-MM-dd  hh:mm:ss")
        }
    }

    Rectangle { anchors.fill: parent; color: "#05070d" }

    // ================= 顶部状态栏 =================
    Rectangle {
        id: topBar
        width: parent.width; height: 54
        color: "#0b1120"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 20
            spacing: 16

            // 返回配置
            Button {
                id: backBtn
                Layout.preferredWidth: 108; Layout.preferredHeight: 36
                background: Rectangle {
                    radius: 8
                    color: backBtn.pressed ? "#1e293b" : "#111a2e"
                    border.color: "#334155"; border.width: 1
                }
                contentItem: Text {
                    text: "‹  配置"; color: "#cbd5e1"; font.pixelSize: 15; font.bold: true
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                onClicked: page.exitRequested()
            }

            Text {
                text: "CARDIAC MONITOR"
                color: "#f87171"; font.bold: true; font.pixelSize: 18; font.letterSpacing: 2
            }

            // 病人信息
            Text {
                Layout.leftMargin: 8
                text: patient
                      ? (patient.name + "  ·  " + patient.sex + "  ·  " + patient.age + "岁  ·  床 " + patient.bed)
                      : ""
                color: "#94a3b8"; font.pixelSize: 15
            }

            Item { Layout.fillWidth: true }

            Text { text: page.clock; color: "#64748b"; font.pixelSize: 15 }

            // LIVE 指示
            Row {
                spacing: 6
                Rectangle {
                    width: 10; height: 10; radius: 5; color: "#34d399"
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 700 }
                        NumberAnimation { to: 1.0; duration: 700 }
                    }
                }
                Text { text: "LIVE"; color: "#34d399"; font.pixelSize: 15; font.bold: true }
            }
        }
    }

    // ================= 主体 =================
    RowLayout {
        anchors.top: topBar.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 10
        spacing: 10

        // ---- 左：三条波形 ----
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.preferredWidth: 66
            spacing: 10

            WavePanel {
                Layout.fillWidth: true; Layout.fillHeight: true
                title: "ECG II"; titleColor: "#34d399"
                waveType: "ecg"; rate: page.hr; traceColor: "#34d399"; gain: 0.42; baselineFrac: 0.5
            }
            WavePanel {
                Layout.fillWidth: true; Layout.fillHeight: true
                title: "PLETH · SpO₂"; titleColor: "#38bdf8"
                waveType: "pleth"; rate: page.hr; traceColor: "#38bdf8"; gain: 0.55; baselineFrac: 0.68
            }
            WavePanel {
                Layout.fillWidth: true; Layout.fillHeight: true
                title: "RESP"; titleColor: "#fbbf24"
                waveType: "resp"; rate: page.resp; traceColor: "#fbbf24"; gain: 0.32; baselineFrac: 0.5
                sweepSpeed: 2
            }
        }

        // ---- 右：数值 ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 34
            Layout.minimumWidth: 240
            spacing: 10

            VitalsBlock {
                Layout.fillWidth: true; Layout.preferredHeight: 130
                label: "HR"; value: page.hr; unit: "bpm"; accent: "#34d399"
                beat: true; beatRate: page.hr
            }
            VitalsBlock {
                Layout.fillWidth: true; Layout.preferredHeight: 130
                label: "SpO₂"; value: page.spo2; unit: "%"; accent: "#38bdf8"
            }
            VitalsBlock {
                Layout.fillWidth: true; Layout.preferredHeight: 130
                label: "RESP"; value: page.resp; unit: "br/min"; accent: "#fbbf24"
            }

            // 心率趋势
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: "#0b1120"; radius: 10
                border.color: "#1e293b"; border.width: 1
                Text {
                    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 10
                    text: "HR TREND"; color: "#64748b"; font.pixelSize: 14; font.bold: true
                }
                Canvas {
                    id: trendCanvas
                    anchors.fill: parent
                    anchors.topMargin: 30; anchors.margins: 10
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        var n = page.trendData.length
                        if (n < 2) return
                        ctx.strokeStyle = "#f87171"; ctx.lineWidth = 2
                        ctx.lineJoin = "round"
                        ctx.beginPath()
                        for (var i = 0; i < n; i++) {
                            var px = (i / (n - 1)) * width
                            var py = height - ((page.trendData[i] - 40) / 120) * height
                            if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
                        }
                        ctx.stroke()
                    }
                }
            }
        }
    }

    // 带标题的波形面板
    component WavePanel: Rectangle {
        property string title: ""
        property color  titleColor: "#34d399"
        property alias  waveType: wave.waveType
        property alias  rate: wave.rate
        property alias  traceColor: wave.traceColor
        property alias  gain: wave.gain
        property alias  baselineFrac: wave.baselineFrac
        property alias  sweepSpeed: wave.sweepSpeed

        color: "#080f1c"; radius: 10
        border.color: "#1e293b"; border.width: 1
        clip: true

        Text {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 10
            text: parent.title; color: parent.titleColor; font.pixelSize: 15; font.bold: true
            z: 2
        }
        Waveform {
            id: wave
            anchors.fill: parent
            anchors.topMargin: 30; anchors.margins: 8
        }
    }
}
