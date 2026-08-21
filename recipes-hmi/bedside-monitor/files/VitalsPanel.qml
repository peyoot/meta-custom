import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    property int hr: 80
    property int spo2: 97
    property int resp: 16
    property int nibpSys: 120
    property int nibpDia: 80
    property real temp: 36.8

    onHrChanged: {}
    // 其他属性同理，但如果你只关心 hr，可以省略
    // onSpo2Changed: {}

    color: "#0a0f1a"
    radius: 10
    border.color: "#152033"
    border.width: 1

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // HR
        VitalsBlock {
            width: parent.width
            height: 130
            label: "HR"
            value: hr
            unit: "bpm"
            color: "#34d399"
        }
        // SpO2
        VitalsBlock {
            width: parent.width
            height: 130
            label: "SpO₂"
            value: spo2
            unit: "%"
            color: "#60a5fa"
        }
        // NIBP
        Rectangle {
            width: parent.width
            height: 130
            color: "#0d1424"
            radius: 8
            border.color: "#1e293b"
            border.width: 1
            Text {
                text: "NIBP"
                color: "#64748b"
                font.pixelSize: 16
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 12
            }
            Text {
                text: nibpSys + "/" + nibpDia
                color: "#f472b6"
                font.bold: true
                font.pixelSize: 48
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
            }
            Text {
                text: "mmHg"
                color: "#64748b"
                font.pixelSize: 16
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
            }
        }
        // RESP
        VitalsBlock {
            width: parent.width
            height: 130
            label: "RESP"
            value: resp
            unit: "br/min"
            color: "#fbbf24"
        }
        // TEMP
        VitalsBlock {
            width: parent.width
            height: 130
            label: "TEMP"
            value: temp
            unit: "°C"
            color: "#a78bfa"
        }
    }

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
            font.pixelSize: 52
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