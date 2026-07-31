# igh-ethercat_1.6.bb
# IgH EtherCAT Master (EtherLab) for ConnectCore MP25 / STM32MP257
# Target: DEY / OpenSTLinux (Scarthgap), systemd, ec_generic driver only.
#
# Placed in: meta-custom/recipes-extended/igh-ethercat/

SUMMARY = "IgH EtherCAT Master for Linux (EtherLab)"
DESCRIPTION = "Open-source EtherCAT master stack from EtherLab (IgH). \
Builds the userspace 'ethercat' tool, libethercat, and the ec_master / \
ec_generic kernel modules."
HOMEPAGE = "https://etherlab.org/en/ethercat/"
SECTION = "kernel/modules"

# NOTE on licensing: the kernel modules are GPL-2.0-only, the userspace
# library (libethercat) is LGPL-2.1. We reference the repo-level COPYING
# (GPL-2.0) here to keep the skeleton simple. If your compliance process
# needs the library license tracked separately, split this accordingly.
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=59530bdf33659b29e73d4adb9f9f6552"

# --- Source -----------------------------------------------------------------
IGH_BRANCH ?= "stable-1.6"
SRC_URI = "git://gitlab.com/etherlab.org/ethercat.git;protocol=https;branch=${IGH_BRANCH}"

# Pin an exact commit on stable-1.6. This SHA is a known-good point on the
# branch; VERIFY it and replace with the commit you actually validate
# against. Never use AUTOREV in a product build.
SRCREV = "703b6117288bbe4e6f74ecb4a6b8ef13f390b898"

S = "${WORKDIR}/git"

# --- Driver selection -------------------------------------------------------
# GENERIC ONLY. ec_generic rides on top of the in-kernel stmmac (dwmac)
# driver of the STM32MP2 GMAC, so we build NO native NIC driver and the
# normal kernel Ethernet driver is left completely untouched. This is the
# low-integration / higher-latency path (fine for soft-RT cycle times).
PACKAGECONFIG ??= "generic"

PACKAGECONFIG[generic]  = "--enable-generic,--disable-generic,"
PACKAGECONFIG[eoe]      = "--enable-eoe,--disable-eoe,"
# Native drivers left disabled — enable one only if you later port a native
# link-layer driver for the STM32MP2 GMAC:
PACKAGECONFIG[8139too]  = "--enable-8139too,--disable-8139too,"
PACKAGECONFIG[e1000e]   = "--enable-e1000e,--disable-e1000e,"
PACKAGECONFIG[r8169]    = "--enable-r8169,--disable-r8169,"

# --- Build ------------------------------------------------------------------
# module-base (NOT the full 'module' class): we drive the kernel-module
# build manually below, because IgH is a hybrid autotools + Kbuild package.
inherit autotools-brokensep pkgconfig module-base systemd

# The kernel build tree must be staged before we configure/build modules.
do_configure[depends] += "virtual/kernel:do_shared_workdir"

EXTRA_OECONF += "--with-linux-dir=${STAGING_KERNEL_BUILDDIR}"
EXTRA_OECONF += "--with-module-dir=kernel/ethercat"
EXTRA_OECONF += "--enable-tool --enable-userlib"

# A fresh git checkout of stable-1.6 has no ChangeLog; automake wants one.
do_configure:prepend() {
    touch ChangeLog
}

# 'make all' builds userspace; the modules need an explicit target.
do_compile:append() {
    oe_runmake modules
}

do_install:append() {
    oe_runmake MODLIB=${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION} modules_install

    # DEY uses systemd — drop the shipped SysV init script.
    rm -rf ${D}${sysconfdir}/init.d/ethercat

    # Prevent udev/modprobe from auto-loading the EtherCAT modules at boot.
    # ethercat.service loads them in the correct order (ec_master first,
    # with the master MAC, then the device module) using the values in
    # /etc/ethercat.conf. Blacklisting keeps load order deterministic.
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

# IgH's build is QA-noisy about build paths; relax as upstream integrators do.
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
ERROR_QA:remove = "buildpaths"
WARN_QA:append = " buildpaths"
