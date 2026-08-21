import QtQuick

// 右侧大号数值块（HR / SpO2 / RESP ...）
Rectangle {
    id: block
    property string label: ""
    property int    value: 0
    property string unit: ""
    property color  accent: "#34d399"
    property bool   beat: false          // 是否显示跳动小心形
    property real   beatRate: 72

    color: "#0b1120"
    radius: 10
    border.color: "#1e293b"
    border.width: 1

    Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    // 顶部标签行
    Row {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 12
        spacing: 8
        Text { text: label; color: "#94a3b8"; font.pixelSize: 15; font.bold: true }

        // 跳动的小心形
        Canvas {
            id: heart
            visible: beat
            width: 16; height: 16
            property real s: 1.0
            onPaint: {
                var ctx = getContext("2d"); ctx.reset()
                ctx.fillStyle = accent
                ctx.translate(width / 2, height / 2); ctx.scale(s, s)
                ctx.beginPath()
                ctx.moveTo(0, 4)
                ctx.bezierCurveTo(-7, -3, -3, -8, 0, -3)
                ctx.bezierCurveTo(3, -8, 7, -3, 0, 4)
                ctx.fill()
            }
            onSChanged: requestPaint()
            SequentialAnimation on s {
                running: beat; loops: Animation.Infinite
                NumberAnimation { to: 1.35; duration: 140; easing.type: Easing.OutQuad }
                NumberAnimation { to: 1.0;  duration: Math.max(120, 60000 / beatRate - 140); easing.type: Easing.InQuad }
            }
        }
    }

    // 大号数字
    Text {
        id: big
        text: value.toString()
        color: accent
        font.bold: true
        font.pixelSize: Math.min(parent.height * 0.5, 64)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 8
        anchors.left: parent.left
        anchors.leftMargin: 16
    }

    Text {
        text: unit
        color: "#64748b"
        font.pixelSize: 15
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
    }
}
