import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: app
    visible: true
    visibility: Window.FullScreen
    // 不设置 width/height：eglfs 这类无合成器的嵌入式后端本来就是
    // "每块屏幕一个、永远铺满"的单窗口模型，显式指定尺寸（哪怕绑定 Screen.width/height）
    // 反而会和平台自身的全屏铺满逻辑冲突，导致窗口实际尺寸和物理屏幕对不上。
    // bedside-monitor 用的 Window 类型就是不设置尺寸，铺满正常，这里改成同样的做法。
    color: "#05070d"
    title: "Vital Monitor (Qt6)"

    // 全局病人信息（配置画面与监测画面共享）
    // 注意：id 不能叫 "patient" —— 否则下面 ConfigScreen { patient: patient } 会被
    // 解析成 ConfigScreen 自身 patient 属性的自绑定（binding loop），而不是引用这个对象。
    QtObject {
        id: patientData
        property string name: "Zhang San"
        property int    age:  45
        property string sex:  "Male"
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
            patient: patientData
            onStartMonitoring: stack.push(monitorComp)
        }
    }

    Component {
        id: monitorComp
        MonitorScreen {
            patient: patientData
            onExitRequested: stack.pop()
        }
    }
}
