# u-boot-dey2022.10.bbappend
# add install_plc_fw_sd.txt into build 

# require recipes-bsp/u-boot/u-boot.inc

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"


SECTION = "bootloaders"

DEPENDS += "bc-native dtc-native u-boot-mkimage-native"
DEPENDS += "${@oe.utils.conditional('TRUSTFENCE_SIGN', '1', 'trustfence-sign-tools-native', '', d)}"

PROVIDES += "u-boot"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

# Select internal or Github U-Boot repo
UBOOT_URI_STASH = "${DIGI_MTK_GIT}/uboot/u-boot-denx.git;protocol=ssh"
UBOOT_URI_GITHUB = "${DIGI_GITHUB_GIT}/u-boot.git;protocol=https"
UBOOT_GIT_URI ?= "${@oe.utils.conditional('DIGI_INTERNAL_GIT', '1' , '${UBOOT_URI_STASH}', '${UBOOT_URI_GITHUB}', d)}"

INSTALL_FW_UBOOT_SCRIPTS = " \
    file://install_plc_fw_sd.txt \
"

SRC_URI = " \
    ${INSTALL_FW_UBOOT_SCRIPTS} \
"



BUILD_UBOOT_SCRIPTS ?= "true"

BOOTLOADER_IMAGE_RECIPE ?= "u-boot"

LOCALVERSION ?= ""
inherit ${@oe.utils.conditional('DEY_SOC_VENDOR', 'NXP', 'fsl-u-boot-localversion', '', d)}

# Disable u-boot environment artifacts
UBOOT_INITIAL_ENV = ""

python __anonymous() {
    if (d.getVar("TRUSTFENCE_DEK_PATH") not in ["0", None]) and (d.getVar("TRUSTFENCE_SIGN") != "1"):
        bb.fatal("Only signed U-Boot images can be encrypted. Generate signed images (TRUSTFENCE_SIGN = \"1\") or remove encryption (TRUSTFENCE_DEK_PATH = \"0\")")
}

do_configure[prefuncs] += "${@oe.utils.ifelse(d.getVar('UBOOT_TF_CONF'), 'trustfence_config', '')}"
python trustfence_config() {
    import shlex
    config_path = d.expand('${WORKDIR}/uboot-trustfence.cfg')
    with open(config_path, 'w') as f:
        for cfg in shlex.split(d.getVar('UBOOT_TF_CONF'), posix=False):
            # strip quotes for "is not set" options
            if 'is not set' in cfg:
                cfg = cfg.strip('"\'')
            f.write('%s\n' % cfg)
    d.appendVar('SRC_URI', ' file://%s' % config_path)
}

TF_BOOTSCRIPT_SEDFILTER = "${@tf_bootscript_sedfilter(d)}"

def tf_bootscript_sedfilter(d):
    tf_initramfs = d.getVar('TRUSTFENCE_INITRAMFS_IMAGE') or ""
    return "s,\(^[[:blank:]]*\)true.*,\\1setenv boot_initrd true\\n\\1setenv initrd_file %s-${MACHINE}.cpio.gz.u-boot.tf,g" % tf_initramfs if tf_initramfs else ""

SIGN_UBOOT ?= ""
SIGN_UBOOT:ccimx6 = "sign_uboot"
SIGN_UBOOT:ccimx6ul = "sign_uboot"

do_deploy[postfuncs] += " \
    adapt_uboot_filenames \
    ${@oe.utils.ifelse(d.getVar('BUILD_UBOOT_SCRIPTS') == 'true', 'build_uboot_scripts', '')} \
    ${@oe.utils.conditional('TRUSTFENCE_SIGN', '1', '${SIGN_UBOOT}', '', d)} \
"

build_uboot_scripts() {
	for f in $(echo ${INSTALL_FW_UBOOT_SCRIPTS} | sed -e 's,file\:\/\/,,g'); do
		f_ext="${f##*.}"
		TMP_INSTALL_SCR="$(mktemp ${WORKDIR}/${f}.XXXXXX)"
		sed -e 's,##GRAPHICAL_BACKEND##,${GRAPHICAL_BACKEND},g' \
			-e 's,##MACHINE##,${MACHINE},g' \
			-e 's,##GRAPHICAL_IMAGES##,${GRAPHICAL_IMAGES},g' \
			-e 's,##DEFAULT_IMAGE_NAME##,${DEFAULT_IMAGE_NAME},g' \
			${WORKDIR}/${f} > ${TMP_INSTALL_SCR}
		# Change the u-boot name when TrustFence is enabled
		if [ "${TRUSTFENCE_SIGN}" = "1" ]; then
			if [ "${DEY_SOC_VENDOR}" = "NXP" ]; then
				if [ "${TRUSTFENCE_DEK_PATH}" != "0" ]; then
					sed -i -e 's,##SIGNED##,encrypted,g' ${TMP_INSTALL_SCR}
				else
					sed -i -e 's,##SIGNED##,signed,g' ${TMP_INSTALL_SCR}
				fi
			else
				sed -i -e 's,##SIGNED##,_Signed,g' ${TMP_INSTALL_SCR}
				sed -i -e 's,##SIGNED_TFA##,_signed,g' ${TMP_INSTALL_SCR}
			fi
		else
			sed -i -e 's,-##SIGNED##,,g' -e 's,##SIGNED##,,g' ${TMP_INSTALL_SCR}
			if [ "${DEY_SOC_VENDOR}" = "STM" ]; then
				sed -i -e 's,##SIGNED_TFA##,,g' ${TMP_INSTALL_SCR}
			fi
		fi
		if [ "${f_ext}" = "txt" ]; then
			mkimage -T script -n "DEY firmware install script" -C none -d ${TMP_INSTALL_SCR} ${DEPLOYDIR}/${f%.*}.scr
		else
			install -m 775 ${TMP_INSTALL_SCR} ${DEPLOYDIR}/${f}
		fi
		rm -f ${TMP_INSTALL_SCR}
	done
