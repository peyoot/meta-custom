import QtQuick
import QtQuick.Controls
import QtQuick.Window

ApplicationWindow {
    id: app
    visible: true
    visibility: Window.FullScreen
    width: 1024
    height: 600
    color: "#05070d"
    title: "Vital Monitor (Qt6)"

    // 全局病人信息（配置画面与监测画面共享）
    QtObject {
        id: patient
        property string name: "Zhang San"
        property int    age:  45
        property string sex:  "男 Male"
        property string bed:  "ICU-08"
        property string pid:  "P-100245"
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: configComp

        // 页面切换动画
        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 350 }
        }
        popEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 350 }
        }
    }

    Component {
        id: configComp
        ConfigScreen {
            patient: patient
            onStartMonitoring: stack.push(monitorComp)
        }
    }

    Component {
        id: monitorComp
        MonitorScreen {
            patient: patient
            onExitRequested: stack.pop()
        }
    }
}
