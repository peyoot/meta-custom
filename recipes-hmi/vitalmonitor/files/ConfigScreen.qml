import QtQuick 2.15
import QtQuick.Controls 2.15

// 开机配置画面：入场动画 + 病人信息 + 开始监测
//
// 注意：本文件刻意不使用 QtQuickLayouts（RowLayout/ColumnLayout/Layout.*），
// 全部改用 anchors + Row/Column 定位。原因：
//   1. Layouts 的"比例伸展 + 最大宽度钳制"在 Qt5/Qt6 上边界行为不一致，
//      之前已导致病人信息卡片宽度被算成 0、整块不显示；
//   2. Layouts 的重排是递归的，子项尺寸依赖父布局尺寸时容易反复重排甚至爆栈；
//   3. 对照组 bedside-monitor 通篇用 Row/Column/anchors，从未出现同类问题。
// anchors/Row/Column 的定位行为完全确定，是嵌入式上更稳妥的选择。
Item {
    id: page
    property var patient

    signal startMonitoring()

    // ---------- 响应式尺寸（按屏幕尺寸等比缩放并限幅）----------
    readonly property real outerMargin:   Math.min(width, height) * 0.035
    readonly property real columnGap:     Math.max(12, width * 0.02)
    readonly property real cardWidth:     Math.min(420, width * 0.42)

    readonly property real heroHeartSize: Math.max(70, Math.min(160, Math.min(width, height) * 0.22))
    readonly property real heroTitleSize: Math.max(20, Math.min(40, height * 0.062))
    readonly property real heroSubSize:   Math.max(11, Math.min(17, height * 0.026))
    readonly property real heroWaveH:     Math.max(46, Math.min(100, height * 0.15))
    readonly property real heroSpacing:   Math.max(8,  height * 0.022)

    readonly property real cardMargin:    Math.max(10, height * 0.03)
    readonly property real cardSpacing:   Math.max(6,  height * 0.018)
    readonly property real cardTitleSize: Math.max(14, Math.min(20, height * 0.03))
    readonly property real labelSize:     Math.max(10, Math.min(13, height * 0.02))
    readonly property real fieldGap:      Math.max(8,  width * 0.015)
    readonly property real fieldH:        Math.max(28, Math.min(44, height * 0.062))
    readonly property real fieldFont:     Math.max(12, Math.min(16, height * 0.024))
    readonly property real btnH:          Math.max(36, Math.min(54, height * 0.08))
    readonly property real btnFont:       Math.max(14, Math.min(20, height * 0.028))

    // ---- 背景 ----
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#070c18" }
            GradientStop { position: 1.0; color: "#0b1a1a" }
        }
    }

    // 呼吸式光晕（略微溢出屏幕做柔光感，但不宜太夸张）
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 1.1
        height: width
        radius: width / 2
        color: "#0f766e"
        opacity: 0.12
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { from: 0.92; to: 1.05; duration: 3000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.05; to: 0.92; duration: 3000; easing.type: Easing.InOutSine }
        }
    }

    // ================= 左：英雄区（动画） =================
    Item {
        id: hero
        anchors.left: parent.left
        anchors.leftMargin: page.outerMargin
        anchors.right: infoCard.left
        anchors.rightMargin: page.columnGap
        anchors.top: parent.top
        anchors.topMargin: page.outerMargin
        anchors.bottom: parent.bottom
        anchors.bottomMargin: page.outerMargin

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: page.heroSpacing

            // 跳动的心脏
            Item {
                id: heartWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: page.heroHeartSize
                height: page.heroHeartSize
                opacity: 0
                scale: 0.7
                Component.onCompleted: introHeart.start()
                ParallelAnimation {
                    id: introHeart
                    // 显式写 target: heartWrap。写 target: parent 会被 QML 沿作用域链
                    // 解析成本 Item 的 parent，动画就打到了错误的对象上。
                    NumberAnimation { target: heartWrap; property: "opacity"; to: 1; duration: 700 }
                    NumberAnimation { target: heartWrap; property: "scale"; to: 1; duration: 700; easing.type: Easing.OutBack }
                }

                Canvas {
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
                anchors.horizontalCenter: parent.horizontalCenter
                text: "VITAL MONITOR"
                color: "#f1f5f9"
                font.pixelSize: page.heroTitleSize
                font.bold: true
                font.letterSpacing: 4
                opacity: 0
                Component.onCompleted: titleAnim.start()
                NumberAnimation on opacity { id: titleAnim; to: 1; duration: 600; running: false }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Multi-Parameter Vital Signs Monitor"
                color: "#64748b"
                font.pixelSize: page.heroSubSize
                opacity: 0
                Component.onCompleted: subAnim.start()
                NumberAnimation on opacity { id: subAnim; to: 1; duration: 600; running: false }
            }

            // 自绘 ECG 预览条
            Waveform {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.9
                height: page.heroWaveH
                waveType: "ecg"
                rate: 72
                traceColor: "#34d399"
                gain: 0.34
                opacity: 0
                Component.onCompleted: waveAnim.start()
                NumberAnimation on opacity { id: waveAnim; to: 1; duration: 900; running: false }
            }
        }
    }

    // ================= 右：病人信息表单 =================
    Rectangle {
        id: infoCard
        anchors.right: parent.right
        anchors.rightMargin: page.outerMargin
        anchors.top: parent.top
        anchors.topMargin: page.outerMargin
        anchors.bottom: parent.bottom
        anchors.bottomMargin: page.outerMargin
        width: page.cardWidth

        color: "#0b1120"
        radius: 16
        border.color: "#1e293b"
        border.width: 1
        opacity: 0
        clip: true

        // 滑入用 transform，不直接动 x —— 避免动画和 anchors 互相打架
        transform: Translate { id: cardSlide; x: 40 }

        Component.onCompleted: cardAnim.start()
        ParallelAnimation {
            id: cardAnim
            NumberAnimation { target: infoCard; property: "opacity"; to: 1; duration: 700 }
            NumberAnimation { target: cardSlide; property: "x"; from: 40; to: 0; duration: 700; easing.type: Easing.OutCubic }
        }

        // 表单区（从顶部往下排）
        Column {
            id: formCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: page.cardMargin
            spacing: page.cardSpacing

            Text {
                text: "Patient Information"
                color: "#e2e8f0"
                font.pixelSize: page.cardTitleSize
                font.bold: true
            }
            Rectangle { width: parent.width; height: 1; color: "#1e293b" }

            // 姓名
            Text { text: "NAME"; color: "#64748b"; font.pixelSize: page.labelSize }
            DarkField {
                id: nameField
                width: parent.width
                text: patient ? patient.name : ""
                fieldHeight: page.fieldH
                fontSize: page.fieldFont
            }

            // 年龄 + 性别（并排）
            Row {
                width: parent.width
                spacing: page.fieldGap

                Column {
                    width: (parent.width - page.fieldGap) / 2
                    spacing: 4
                    Text { text: "AGE"; color: "#64748b"; font.pixelSize: page.labelSize }
                    DarkField {
                        id: ageField
                        width: parent.width
                        text: patient ? patient.age.toString() : "0"
                        inputMethodHints: Qt.ImhDigitsOnly
                        fieldHeight: page.fieldH
                        fontSize: page.fieldFont
                    }
                }
                Column {
                    width: (parent.width - page.fieldGap) / 2
                    spacing: 4
                    Text { text: "SEX"; color: "#64748b"; font.pixelSize: page.labelSize }
                    ComboBox {
                        id: sexBox
                        width: parent.width
                        height: page.fieldH
                        model: ["Male", "Female", "Other"]
                    }
                }
            }

            // 床号
            Text { text: "BED"; color: "#64748b"; font.pixelSize: page.labelSize }
            DarkField {
                id: bedField
                width: parent.width
                text: patient ? patient.bed : ""
                fieldHeight: page.fieldH
                fontSize: page.fieldFont
            }

            // 病历号
            Text { text: "ID"; color: "#64748b"; font.pixelSize: page.labelSize }
            DarkField {
                id: idField
                width: parent.width
                text: patient ? patient.pid : ""
                fieldHeight: page.fieldH
                fontSize: page.fieldFont
            }
        }

        // 开始按钮（钉在卡片底部）
        Button {
            id: startBtn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: page.cardMargin
            height: page.btnH

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
                text: "▶  Start Monitoring"
                color: "#052e26"
                font.pixelSize: page.btnFont
                font.bold: true
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

    // 复用的深色输入框（高度/字号由调用方传入，以便随屏幕缩放）
    component DarkField: TextField {
        id: fieldRoot
        property real fieldHeight: 42
        property real fontSize: 16

        height: fieldHeight
        color: "#e2e8f0"
        font.pixelSize: fontSize
        selectByMouse: true
        leftPadding: 12
        background: Rectangle {
            color: "#0d1424"
            radius: 8
            // 用 fieldRoot 而不是 parent，避免 parent 解析歧义
            border.color: fieldRoot.activeFocus ? "#14b8a6" : "#1e293b"
            border.width: 1
        }
    }
}
