# meta-custom/recipes-core/packagegroups/packagegroup-dey-core.bbappend
RDEPENDS:${PN}:remove = " \
    connectcore-demo-example \
    cccs \
    cccs-daemon \
    cccs-gs-demo \
    cccs-legacy \
    dey-examples-cccs \
"

