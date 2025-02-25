# 删除冲突的 index.html
do_install:append() {
    rm -f ${D}/srv/www/index.html
}
