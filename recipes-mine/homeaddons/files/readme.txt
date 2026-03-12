dey-aio-manifest/meta-custom scarthgap-ccmp25plc branch
This is a framebuffer version to optimize for realtime linux. To use QT5 please check QT version in your conf/bblayers.conf.
Please refer to https://peyoot.github.io/deyaio/wiki/ccmp25/ccmp25plc.html for more details

This image is designed for ST CCMP25PLC board. Please check if you have the applicable board。

For real time test command:

cyclictest -p 98 -t5 -m -l 100000
cyclictest --mlockall --smp --priority=98 --interval=1000 --distance=0 -D 2m

