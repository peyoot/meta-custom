#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtGlobal>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
#if QT_VERSION_MAJOR >= 6
    // Qt6: qt_add_qml_module（见 CMakeLists.txt）生成的模块资源路径
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/VitalMonitor/Main.qml")));
#else
    // Qt5: 传统 qrc 资源路径（见 qml.qrc）
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
#endif

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}