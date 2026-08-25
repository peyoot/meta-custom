import QtQuick 2.15
import QtQuick.Controls 2.15

// 心电监测主界面：三条扫描波形 + 大号数值 + 返回配置
//
// 同 ConfigScreen.qml：不使用 QtQuickLayouts，全部改用 anchors + Row/Column，
// 避免 Layout.preferredWidth 当"比例"用这种写法在 Qt5/Qt6 上表现不一致
// （之前在这个文件上就是靠这招踩出了"数据区/波形区宽度比例算反"的 bug）。
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

    // 右侧数值栏宽度、面板间距，按屏幕尺寸缩放
    readonly property real valuesColWidth: Math.max(240, width * 0.34)
    readonly property real gap: 10

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

        // 左侧一组：返回按钮 + 标题 + 病人信息
        Row {
            anchors.left: parent.left; anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Button {
                id: backBtn
                width: 108; height: 36
                anchors.verticalCenter: parent.verticalCenter
                background: Rectangle {
                    radius: 8
                    color: backBtn.pressed ? "#1e293b" : "#111a2e"
                    border.color: "#334155"; border.width: 1
                }
                contentItem: Text {
                    text: "‹  Setup"; color: "#cbd5e1"; font.pixelSize: 15; font.bold: true
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                onClicked: page.exitRequested()
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "CARDIAC MONITOR"
                color: "#f87171"; font.bold: true; font.pixelSize: 18; font.letterSpacing: 2
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: patient
                      ? (patient.name + "  ·  " + patient.sex + "  ·  " + patient.age + " yrs  ·  Bed " + patient.bed)
                      : ""
                color: "#94a3b8"; font.pixelSize: 15
            }
        }

        // 右侧一组：时钟 + LIVE 指示
        Row {
            anchors.right: parent.right; anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: page.clock; color: "#64748b"; font.pixelSize: 15
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
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
    Item {
        id: body
        anchors.top: topBar.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 10

        // ---- 左：三条波形（占满除数值栏外的全部宽度） ----
        Item {
            id: waveCol
            anchors.left: parent.left
            anchors.right: valuesCol.left
            anchors.rightMargin: page.gap
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            readonly property real panelH: (height - 2 * page.gap) / 3

            WavePanel {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top
                height: waveCol.panelH
                title: "ECG II"; titleColor: "#34d399"
                waveType: "ecg"; rate: page.hr; traceColor: "#34d399"; gain: 0.42; baselineFrac: 0.5
            }
            WavePanel {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: waveCol.panelH + page.gap
                height: waveCol.panelH
                title: "PLETH · SpO₂"; titleColor: "#38bdf8"
                waveType: "pleth"; rate: page.hr; traceColor: "#38bdf8"; gain: 0.55; baselineFrac: 0.68
            }
            WavePanel {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: waveCol.panelH
                title: "RESP"; titleColor: "#fbbf24"
                waveType: "resp"; rate: page.resp; traceColor: "#fbbf24"; gain: 0.32; baselineFrac: 0.5
                sweepSpeed: 2
            }
        }

        // ---- 右：数值栏（固定宽度，贴右边） ----
        Item {
            id: valuesCol
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: page.valuesColWidth

            readonly property real blockH: (height - 3 * page.gap) / 4

            VitalsBlock {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top
                height: valuesCol.blockH
                label: "HR"; value: page.hr; unit: "bpm"; accent: "#34d399"
                beat: true; beatRate: page.hr
            }
            VitalsBlock {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: valuesCol.blockH + page.gap
                height: valuesCol.blockH
                label: "SpO₂"; value: page.spo2; unit: "%"; accent: "#38bdf8"
            }
            VitalsBlock {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.topMargin: (valuesCol.blockH + page.gap) * 2
                height: valuesCol.blockH
                label: "RESP"; value: page.resp; unit: "br/min"; accent: "#fbbf24"
            }

            // 心率趋势
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: valuesCol.blockH
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
