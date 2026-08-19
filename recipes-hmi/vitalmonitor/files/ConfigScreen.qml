import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 开机配置画面：入场动画 + 病人信息 + 开始监测
Item {
    id: page
    property var patient

    signal startMonitoring()

    // ---- 背景 ----
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#070c18" }
            GradientStop { position: 1.0; color: "#0b1a1a" }
        }
    }
    // 呼吸式光晕
    Rectangle {
        id: glow
        anchors.centerIn: parent
        width: parent.height * 1.4; height: width; radius: width / 2
        color: "#0f766e"
        opacity: 0.12
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { from: 0.85; to: 1.1; duration: 3000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.1; to: 0.85; duration: 3000; easing.type: Easing.InOutSine }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: parent.width * 0.05
        spacing: 40

        // ================= 左：英雄区（动画） =================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 5

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 18

                // 跳动的心脏
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 150; height: 150
                    opacity: 0
                    scale: 0.7
                    Component.onCompleted: introHeart.start()
                    ParallelAnimation {
                        id: introHeart
                        NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 700 }
                        NumberAnimation { target: parent; property: "scale"; to: 1; duration: 700; easing.type: Easing.OutBack }
                    }

                    Canvas {
                        id: heartCanvas
                        anchors.fill: parent
                        property real beat: 1.0
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            var w = width, h = height
                            ctx.translate(w / 2, h / 2); ctx.scale(beat, beat); ctx.translate(-w / 2, -h / 2)
                            var g = ctx.createRadialGradient(w / 2, h * 0.4, 8, w / 2, h * 0.5, w * 0.6)
                            g.addColorStop(0, "#fb7185"); g.addColorStop(1, "#e11d48")
                            ctx.fillStyle = g
                            var cx = w / 2, top = h * 0.30, wide = w * 0.34, bot = h * 0.82
                            ctx.beginPath()
                            ctx.moveTo(cx, bot)
                            ctx.bezierCurveTo(cx - wide * 2.2, h * 0.55, cx - wide, top - h * 0.12, cx, top + h * 0.06)
                            ctx.bezierCurveTo(cx + wide, top - h * 0.12, cx + wide * 2.2, h * 0.55, cx, bot)
                            ctx.fill()
                        }
                        onBeatChanged: requestPaint()
                        SequentialAnimation on beat {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.18; duration: 150; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 1.0;  duration: 220; easing.type: Easing.InQuad }
                            NumberAnimation { to: 1.10; duration: 130; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 1.0;  duration: 330; easing.type: Easing.InQuad }
                            PauseAnimation  { duration: 180 }
                        }
                    }
                }

                // 标题
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "VITAL MONITOR"
                    color: "#f1f5f9"
                    font.pixelSize: 40; font.bold: true
                    font.letterSpacing: 4
                    opacity: 0
                    Component.onCompleted: titleAnim.start()
                    NumberAnimation on opacity { id: titleAnim; to: 1; duration: 600; running: false }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "多参数生命体征监护系统 · Qt 6"
                    color: "#64748b"; font.pixelSize: 16
                    opacity: 0
                    Component.onCompleted: subAnim.start()
                    NumberAnimation on opacity { id: subAnim; to: 1; duration: 600; running: false }
                }

                // 自绘 ECG 预览条
                Waveform {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.9
                    Layout.preferredHeight: 90
                    waveType: "ecg"; rate: 72; traceColor: "#34d399"
                    gain: 0.34
                    opacity: 0
                    Component.onCompleted: waveAnim.start()
                    NumberAnimation on opacity { id: waveAnim; to: 1; duration: 900; running: false }
                }
            }
        }

        // ================= 右：病人信息表单 =================
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 4
            Layout.maximumWidth: 420
            color: "#0b1120"
            radius: 16
            border.color: "#1e293b"; border.width: 1
            opacity: 0
            x: 40
            Component.onCompleted: cardAnim.start()
            ParallelAnimation {
                id: cardAnim
                NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 700 }
                NumberAnimation { target: parent; property: "x"; from: 40; to: 0; duration: 700; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 16

                Text { text: "病人信息"; color: "#e2e8f0"; font.pixelSize: 22; font.bold: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

                // 姓名
                Text { text: "姓名 NAME"; color: "#64748b"; font.pixelSize: 13 }
                DarkField { id: nameField; Layout.fillWidth: true; text: patient ? patient.name : "" }

                // 年龄 + 性别
                RowLayout {
                    Layout.fillWidth: true; spacing: 16
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "年龄 AGE"; color: "#64748b"; font.pixelSize: 13 }
                        DarkField {
                            id: ageField; Layout.fillWidth: true
                            text: patient ? patient.age.toString() : "0"
                            inputMethodHints: Qt.ImhDigitsOnly
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "性别 SEX"; color: "#64748b"; font.pixelSize: 13 }
                        ComboBox {
                            id: sexBox
                            Layout.fillWidth: true
                            model: ["男 Male", "女 Female", "其他 Other"]
                        }
                    }
                }

                // 床号 + ID
                Text { text: "床号 BED"; color: "#64748b"; font.pixelSize: 13 }
                DarkField { id: bedField; Layout.fillWidth: true; text: patient ? patient.bed : "" }

                Text { text: "病历号 ID"; color: "#64748b"; font.pixelSize: 13 }
                DarkField { id: idField; Layout.fillWidth: true; text: patient ? patient.pid : "" }

                Item { Layout.fillHeight: true }   // 弹性占位

                // 开始按钮
                Button {
                    id: startBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    text: ""
                    background: Rectangle {
                        radius: 12
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: startBtn.pressed ? "#059669" : "#10b981" }
                            GradientStop { position: 1.0; color: startBtn.pressed ? "#0d9488" : "#14b8a6" }
                        }
                        border.color: "#5eead4"
                        border.width: 1
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.82; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
                        }
                    }
                    contentItem: Text {
                        text: "▶  开始监测"
                        color: "#052e26"; font.pixelSize: 20; font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (patient) {
                            patient.name = nameField.text
                            patient.age  = parseInt(ageField.text) || patient.age
                            patient.sex  = sexBox.currentText
                            patient.bed  = bedField.text
                            patient.pid  = idField.text
                        }
                        page.startMonitoring()
                    }
                }
            }
        }
    }

    // 复用的深色输入框
    component DarkField: TextField {
        color: "#e2e8f0"
        font.pixelSize: 16
        selectByMouse: true
        leftPadding: 12
        background: Rectangle {
            implicitHeight: 42
            color: "#0d1424"
            radius: 8
            border.color: parent && parent.activeFocus ? "#14b8a6" : "#1e293b"
            border.width: 1
        }
    }
}
