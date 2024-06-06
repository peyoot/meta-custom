# meta-custom/recipes-qt/qt5/qtbase_%.bbappend  
  
do_install_append() {  
    local custom_script="${THISDIR}/qtbase/rosqt5.sh"  
    if [ -f "${custom_script}" ]; then  
        rm -f ${D}${sysconfdir}/profile.d/qt5.sh  
  
        install -m 0755 "${custom_script}" ${D}${sysconfdir}/profile.d/qt5.sh  
    else  
        bberror "Custom script ${custom_script} not found!"  
        return 1  
    fi  
}  
  
FILES:${PN} += "${sysconfdir}/profile.d/qt5.sh"


