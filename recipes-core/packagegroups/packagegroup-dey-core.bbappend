# meta-custom/recipes-core/packagegroups/packagegroup-dey-core.bbappend

# 移除 connectcore-demo-example 和 CCCS 相关包
RDEPENDS:${PN}:remove = " \
    connectcore-demo-example \
    ${CCCS_PKGS} \
"

# 若需进一步移除 CCCS 子包（根据 cccs_git.bb 内容）
RDEPENDS:${PN}:remove:append = " \
    cccs-daemon \
    cccs-gs-demo \
    cccs-legacy \
"
