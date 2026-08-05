# For better realtime performance do the following
# remove wireless stuff
PACKAGECONFIG:remove:pn-networkmanager = " ppp modemmanager  bluetooth wifi "

# remove gstreamer
PACKAGECONFIG:remove:pn-networkmanager = " gstreamer "