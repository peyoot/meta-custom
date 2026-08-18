import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    width: 1920
    height: 1080
    visible: true
    color: "#05070d"
    title: "Bedside Monitor (Qt6)"

    // 顶部信息栏
    Rectangle {
        id: topBar
        width: parent.width
        height: 60
        color: "#0a0f1a"
        border.color: "#152033"
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 20
            Text {
                text: "VITASCOPE BEDSIDE MONITOR"
                color: "#60a5fa"
                font.bold: true
                font.pixelSize: 22
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "Patient: #PT-28471"
                color: "#94a3b8"
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: 40; height: 1 }
            Text {
                text: "● MONITORING"
                color: "#34d399"
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Item { width: parent.width - 700; height: 1 }
            Text {
                id: clockText
                color: "#e2e8f0"
                font.pixelSize: 20
                anchors.verticalCenter: parent.verticalCenter
            }
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    clockText.text = Qt.formatTime(new Date(), "hh:mm:ss")
                }
            }
        }
    }

    // 主体行：左数值 + 右波形
    Row {
        anchors.top: topBar.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        spacing: 12

        // 左侧：数值面板
        VitalsPanel {
            id: vitals
            width: 420
            height: parent.height
        }

        // 右侧：波形区
        Column {
            width: parent.width - 432
            height: parent.height
            spacing: 12

            WaveformCanvas {
                width: parent.width
                height: (parent.height - 24) / 3
                label: "ECG II"
                color: "#34d399"
                waveform: "ecg"
            }
            WaveformCanvas {
                width: parent.width
                height: (parent.height - 24) / 3
                label: "SpO₂ Pleth"
                color: "#60a5fa"
                waveform: "pleth"
            }
            WaveformCanvas {
                width: parent.width
                height: (parent.height - 24) / 3
                label: "RESP"
                color: "#fbbf24"
                waveform: "resp"
            }
        }
    }

    // 模拟数据驱动
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            vitals.hr = 70 + Math.floor(Math.random() * 35)
            vitals.spo2 = 96 + Math.floor(Math.random() * 4)
            vitals.resp = 14 + Math.floor(Math.random() * 8)
            vitals.nibpSys = 115 + Math.floor(Math.random() * 25)
            vitals.nibpDia = 70 + Math.floor(Math.random() * 15)
            vitals.temp = (36.5 + Math.random()).toFixed(1)
        }
    }
}