meta-custom scarthgap-qtfb-rtnodemo branch
This is a QT5 framebuffer version to optimize for realtime linux
Please refer to https://peyoot.github.io/deyaio/wiki/ccmp25/qt-realtime.html for more details


real time test command:

cyclictest -p 98 -t5 -m -l 100000
cyclictest --mlockall --smp --priority=98 --interval=1000 --distance=0 -D 2m