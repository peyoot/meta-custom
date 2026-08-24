import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: app
    visible: true
    visibility: Window.FullScreen
    // 实际跑在 Wayland/weston 上：合成器管理窗口尺寸，未设置 width/height 的窗口
    // 初始拿到的是合成器给的默认尺寸，FullScreen 请求生效的时机不完全可控。
    // 显式绑定屏幕尺寸能让 QML 内部布局始终按照确定的真实分辨率计算，不依赖
    // 合成器自动铺满的时机。
    width: Screen.width
    height: Screen.height
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
