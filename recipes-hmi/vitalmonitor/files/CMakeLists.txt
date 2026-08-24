cmake_minimum_required(VERSION 3.16)

project(vitalmonitor LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# 同时兼容 meta-qt5 (Qt5) 与 meta-qt6 (Qt6)：
# 注意不能用网上常见的 find_package(QT NAMES Qt6 Qt5 ...) 两步探测写法——
# 那依赖 Qt 提供的 QTConfig.cmake 引导文件，而 Qt 5.15（meta-qt5/scarthgap 用的版本）
# 并不提供这个文件，会导致 Qt5 环境下直接配置失败。这里手动探测，更可靠。
find_package(Qt6 QUIET COMPONENTS Core Gui Qml Quick)
if(Qt6_FOUND)
    set(QT_VERSION_MAJOR 6)
else()
    find_package(Qt5 REQUIRED COMPONENTS Core Gui Qml Quick)
    set(QT_VERSION_MAJOR 5)
endif()

set(VITALMONITOR_QML_FILES
    Main.qml
    ConfigScreen.qml
    MonitorScreen.qml
    Waveform.qml
    VitalsBlock.qml
    HeartData.js
)

if(QT_VERSION_MAJOR GREATER_EQUAL 6)
    # Qt6：qt_add_qml_module 会自动把 QML 文件打包成模块资源
    qt_standard_project_setup(REQUIRES 6.5)

    qt_add_executable(vitalmonitor main.cpp)

    qt_add_qml_module(vitalmonitor
        URI VitalMonitor
        VERSION 1.0
        QML_FILES ${VITALMONITOR_QML_FILES}
    )
else()
    # Qt5 没有 qt_add_qml_module（那是 Qt6 才有的 CMake API），
    # 改用传统 qrc 资源打包 QML 文件，main.cpp 里按版本加载对应路径。
    add_executable(vitalmonitor main.cpp qml.qrc)
endif()

target_link_libraries(vitalmonitor PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::Qml
    Qt${QT_VERSION_MAJOR}::Quick
)

install(TARGETS vitalmonitor RUNTIME DESTINATION bin)
