import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 开机配置画面：入场动画 + 病人信息 + 开始监测
// 所有尺寸都按屏幕高度 page.height 等比例计算（并做 min/max 限幅），
// 保证在任意分辨率下整屏都能放得下、看得到，不依赖滚动。
Item {
    id: page
    property var patient

    signal startMonitoring()

    // ---------- 响应式尺寸 ----------
    readonly property real heroHeartSize: Math.max(70,  Math.min(160, Math.min(width, height) * 0.22))
    readonly property real heroTitleSize: Math.max(20,  Math.min(40, height * 0.062))
    readonly property real heroSubSize:   Math.max(11,  Math.min(17, height * 0.026))
    readonly property real heroWaveH:     Math.max(46,  Math.min(100, height * 0.15))
    readonly property real heroSpacing:   Math.max(8,   height * 0.022)

    readonly property real cardMargin:    Math.max(10,  height * 0.03)
    readonly property real cardSpacing:   Math.max(6,   height * 0.018)
    readonly property real cardTitleSize: Math.max(14,  Math.min(20, height * 0.03))
    readonly property real labelSize:     Math.max(10,  Math.min(13, height * 0.02))
    readonly property real fieldH:        Math.max(28,  Math.min(44, height * 0.062))
    readonly property real fieldFont:     Math.max(12,  Math.min(16, height * 0.024))
    readonly property real btnH:          Math.max(36,  Math.min(54, height * 0.08))
    readonly property real btnFont:       Math.max(14,  Math.min(20, height * 0.028))

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
        anchors.margins: Math.min(parent.width, parent.height) * 0.035
        spacing: Math.max(12, parent.width * 0.02)

        // ================= 左：英雄区（动画） =================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 5

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: page.heroSpacing

                // 跳动的心脏
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: page.heroHeartSize; height: page.heroHeartSize
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
                    font.pixelSize: page.heroTitleSize; font.bold: true
                    font.letterSpacing: 4
                    opacity: 0
                    Component.onCompleted: titleAnim.start()
                    NumberAnimation on opacity { id: titleAnim; to: 1; duration: 600; running: false }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "多参数生命体征监护系统 · Qt 6"
                    color: "#64748b"; font.pixelSize: page.heroSubSize
                    opacity: 0
                    Component.onCompleted: subAnim.start()
                    NumberAnimation on opacity { id: subAnim; to: 1; duration: 600; running: false }
                }

                // 自绘 ECG 预览条
                Waveform {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.9
                    Layout.preferredHeight: page.heroWaveH
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
            clip: true
            x: 40
            Component.onCompleted: cardAnim.start()
            ParallelAnimation {
                id: cardAnim
                NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 700 }
                NumberAnimation { target: parent; property: "x"; from: 40; to: 0; duration: 700; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: page.cardMargin
                spacing: page.cardSpacing

                Text { text: "病人信息"; color: "#e2e8f0"; font.pixelSize: page.cardTitleSize; font.bold: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1e293b" }

                // 姓名
                Text { text: "姓名 NAME"; color: "#64748b"; font.pixelSize: page.labelSize }
                DarkField {
                    id: nameField
                    Layout.fillWidth: true
                    text: patient ? patient.name : ""
                    fieldHeight: page.fieldH; fontSize: page.fieldFont
                }

                // 年龄 + 性别
                RowLayout {
                    Layout.fillWidth: true; spacing: Math.max(8, page.width * 0.02)
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { text: "年龄 AGE"; color: "#64748b"; font.pixelSize: page.labelSize }
                        DarkField {
                            id: ageField; Layout.fillWidth: true
                            text: patient ? patient.age.toString() : "0"
                            inputMethodHints: Qt.ImhDigitsOnly
                            fieldHeight: page.fieldH; fontSize: page.fieldFont
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { text: "性别 SEX"; color: "#64748b"; font.pixelSize: page.labelSize }
                        ComboBox {
                            id: sexBox
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.fieldH
                            model: ["男 Male", "女 Female", "其他 Other"]
                        }
                    }
                }

                // 床号 + ID
                Text { text: "床号 BED"; color: "#64748b"; font.pixelSize: page.labelSize }
                DarkField {
                    id: bedField
                    Layout.fillWidth: true
                    text: patient ? patient.bed : ""
                    fieldHeight: page.fieldH; fontSize: page.fieldFont
                }

                Text { text: "病历号 ID"; color: "#64748b"; font.pixelSize: page.labelSize }
                DarkField {
                    id: idField
                    Layout.fillWidth: true
                    text: patient ? patient.pid : ""
                    fieldHeight: page.fieldH; fontSize: page.fieldFont
                }

                Item { Layout.fillHeight: true }   // 弹性占位，把按钮推到底部

                // 开始按钮
                Button {
                    id: startBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: page.btnH
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
                        color: "#052e26"; font.pixelSize: page.btnFont; font.bold: true
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

    // 复用的深色输入框 —— 高度/字号由外部通过 fieldHeight / fontSize 传入，
    // 从而随屏幕尺寸自适应（组件定义体内不能直接引用 page 的 id）。
    component DarkField: TextField {
        property real fieldHeight: 42
        property real fontSize: 16
        color: "#e2e8f0"
        font.pixelSize: fontSize
        selectByMouse: true
        leftPadding: 12
        background: Rectangle {
            implicitHeight: fieldHeight
            color: "#0d1424"
            radius: 8
            border.color: parent && parent.activeFocus ? "#14b8a6" : "#1e293b"
            border.width: 1
        }
    }
}
