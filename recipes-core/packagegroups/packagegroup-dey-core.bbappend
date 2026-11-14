# meta-custom/recipes-core/packagegroups/packagegroup-dey-core.bbappend

# 移除 connectcore-demo-example 和 CCCS 相关包
RDEPENDS:${PN}:remove = " \
    connectcore-demo-example \
"