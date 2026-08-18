cmake_minimum_required(VERSION 3.16)

project(vitalmonitor LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(vitalmonitor
    main.cpp
)

qt_add_qml_module(vitalmonitor
    URI VitalMonitor
    VERSION 1.0
    QML_FILES
        Main.qml
        HeartData.js
)

target_link_libraries(vitalmonitor PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

install(TARGETS vitalmonitor RUNTIME DESTINATION bin)