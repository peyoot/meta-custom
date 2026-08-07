# igh-ethercat_1.6.bb
# IgH EtherCAT Master (EtherLab) for ConnectCore MP25 / STM32MP257.
# Target: DEY / OpenSTLinux (Scarthgap), systemd, ec_generic driver only.
#
# Placed in: meta-custom/recipes-extended/igh-ethercat/

SUMMARY = "IgH EtherCAT Master for Linux (EtherLab)"
DESCRIPTION = "Open-source EtherCAT master stack from EtherLab (IgH). \
Builds the userspace 'ethercat' tool, libethercat, and the ec_master / \
ec_generic kernel modules."
HOMEPAGE = "https://etherlab.org/en/ethercat/"
SECTION = "kernel/modules"

# Kernel modules are GPL-2.0-only, userspace library is LGPL-2.1. We reference
# the repo-level COPYING (GPL-2.0) to keep the skeleton simple.
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=59530bdf33659b29e73d4adb9f9f6552"

# --- Source -----------------------------------------------------------------
IGH_BRANCH ?= "stable-1.6"
SRC_URI = "git://gitlab.com/etherlab.org/ethercat.git;protocol=https;branch=${IGH_BRANCH}"
# Our own systemd unit — IgH ships ethercat.service in script/ but does not
# reliably install it in a cross build, so we provide it deterministically.
SRC_URI += "file://ethercat.service"

# Pin an exact commit on stable-1.6. VERIFY and replace with the commit you
# actually validate against. Never use AUTOREV in a product build.
SRCREV = "703b6117288bbe4e6f74ecb4a6b8ef13f390b898"

S = "${WORKDIR}/git"

# --- Driver selection -------------------------------------------------------
# GENERIC ONLY. ec_generic rides on top of the in-kernel stmmac (dwmac) driver
# of the STM32MP2 GMAC; no native NIC driver is built.
PACKAGECONFIG ??= "generic"

PACKAGECONFIG[generic]  = "--enable-generic,--disable-generic,"
PACKAGECONFIG[eoe]      = "--enable-eoe,--disable-eoe,"
PACKAGECONFIG[8139too]  = "--enable-8139too,--disable-8139too,"
PACKAGECONFIG[e1000e]   = "--enable-e1000e,--disable-e1000e,"
PACKAGECONFIG[r8169]    = "--enable-r8169,--disable-r8169,"

# --- Build ------------------------------------------------------------------
inherit autotools-brokensep pkgconfig module-base systemd

do_configure[depends] += "virtual/kernel:do_shared_workdir"

EXTRA_OECONF += "--with-linux-dir=${STAGING_KERNEL_BUILDDIR}"
EXTRA_OECONF += "--with-module-dir=kernel/ethercat"
EXTRA_OECONF += "--enable-tool --enable-userlib"

do_configure:prepend() {
    touch ChangeLog
}

do_compile:append() {
    oe_runmake modules
}

do_install:append() {
    oe_runmake MODLIB=${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION} modules_install

    # DEY uses systemd — drop the shipped SysV init script.
    rm -rf ${D}${sysconfdir}/init.d/ethercat

    # Install our systemd unit deterministically. IgH's own make install does
    # not reliably place ethercat.service in a cross build; ethercatctl (called
    # by the unit) IS always installed to ${sbindir}, so the unit works as-is.
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ethercat.service ${D}${systemd_system_unitdir}/ethercat.service

    # Keep boot-time module loading deterministic: let ethercat.service load the
    # modules (in the right order, using /etc/ethercat.conf) rather than udev.
    install -d ${D}${sysconfdir}/modprobe.d
    : > ${D}${sysconfdir}/modprobe.d/igh-ethercat.conf
    for drv in ${PACKAGECONFIG}; do
        echo "blacklist ec_${drv}" >> ${D}${sysconfdir}/modprobe.d/igh-ethercat.conf
    done
}

# --- Packaging --------------------------------------------------------------
SYSTEMD_SERVICE:${PN} = "ethercat.service"
SYSTEMD_AUTO_ENABLE = "disable"

FILES:${PN} += "\
    ${nonarch_base_libdir}/modules/${KERNEL_VERSION}/* \
    ${systemd_system_unitdir}/ethercat.service \
    ${datadir}/bash-completion/completions \
"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
ERROR_QA:remove = "buildpaths"
WARN_QA:append = " buildpaths"
