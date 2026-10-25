# meta-custom/recipes-digi/sysinfo/sysinfo.bbappend
#
# Use meta-custom's copy of the sysinfo script (recipes-digi/sysinfo/sysinfo/sysinfo)
# instead of the one in meta-digi-dey, and fill in build-host information.

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Helper that finds the build host's IPv4 address; only used at build time,
# it is not installed in the image.
SRC_URI += "file://get-build-ip.py"

# Optional: force the network interface used for the "Build host" IP
# (e.g. CUSTOM_BUILD_IF = "ens160" in local.conf). Empty = auto-detect the first
# wired physical NIC, falling back to the default-route interface.
CUSTOM_BUILD_IF ?= ""

# The values below come from the build host's filesystem and are not part of the
# task signature, so force do_install to run every time. Remove this line if you
# prefer to run "bitbake -c cleansstate sysinfo" manually after changing
# manifest/project.
do_install[nostamp] = "1"

# local.conf content is reported starting from the line AFTER the first line
# containing this marker.
CUSTOM_EULA_MARKER ?= "ACCEPT_EULA_${MACHINE}"

do_install:append() {
    topdir="${TOPDIR}"

    # DEY project name: first directory after "workspace/"
    proj="$(echo "$topdir" | sed -n 's|.*/workspace/\([^/]*\).*|\1|p')"
    [ -z "$proj" ] && proj="$(basename "$topdir")"

    # repo root: walk up from the build dir until a .repo directory is found
    root="$topdir"
    while [ "$root" != "/" ] && [ ! -d "$root/.repo" ]; do
        root="$(dirname "$root")"
    done

    # manifest xml currently in use (.repo/manifest.xml has <include name="...">)
    xml="unknown"
    if [ -f "$root/.repo/manifest.xml" ]; then
        xml="$(sed -n 's/.*<include[[:space:]]*name="\([^"]*\)".*/\1/p' \
               "$root/.repo/manifest.xml" | head -n 1)"
        [ -z "$xml" ] && xml="$(basename "$(readlink -f "$root/.repo/manifest.xml")")"
        [ -z "$xml" ] && xml="unknown"
    fi

    # meta-custom branch, taken from the revision attribute of its <project> entry
    branch="unknown"
    if [ -f "$root/.repo/manifests/$xml" ]; then
        branch="$(sed -n '/<project[^>]*name="meta-custom\.git"/s/.*revision="\([^"]*\)".*/\1/p' \
                  "$root/.repo/manifests/$xml" | head -n 1)"
        [ -z "$branch" ] && branch="unknown"
    fi

    # build machine hostname and primary IPv4 address
    buildhost="$(hostname 2>/dev/null)"
    [ -z "$buildhost" ] && buildhost="unknown"
    # IPv4 of the first wired physical NIC (see get-build-ip.py for the rules)
    buildip="$(python3 ${WORKDIR}/get-build-ip.py "${CUSTOM_BUILD_IF}" 2>/dev/null || true)"
    # last resort: first address reported by hostname -I
    [ -z "$buildip" ] && buildip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    [ -z "$buildip" ] && buildip="unknown"

    # build date (build host's local time, with UTC offset)
    builddate="$(date "+%Y-%m-%d %H:%M:%S %z")"

    # tail of conf/local.conf: everything after the line containing the EULA marker
    install -d ${D}${sysconfdir}
    localconf_out="${D}${sysconfdir}/sysinfo-local.conf.txt"
    : > "$localconf_out"
    if [ -f "$topdir/conf/local.conf" ]; then
        awk -v m="${CUSTOM_EULA_MARKER}" 'f{print; next} index($0,m){f=1}' \
            "$topdir/conf/local.conf" > "$localconf_out"
        # Optional: mask likely secrets before they end up in the report, e.g.
        # sed -i -E 's/^([^#]*(PASSWORD|PASSWD|SECRET|TOKEN|CREDENTIAL)[^=]*=).*/\1 "<redacted>"/' "$localconf_out"
    fi

    # replace placeholders in the installed script (bindir or sbindir)
    find ${D} -type f -name sysinfo -exec sed -i \
        -e "s|@CUSTOM_BRANCH@|$branch|" \
        -e "s|@CUSTOM_MANIFEST_XML@|$xml|" \
        -e "s|@CUSTOM_PROJECT_NAME@|$proj|" \
        -e "s|@CUSTOM_BUILD_HOST@|$buildhost|" \
        -e "s|@CUSTOM_BUILD_IP@|$buildip|" \
        -e "s|@CUSTOM_BUILD_DATE@|$builddate|" {} +
}

FILES:${PN} += "${sysconfdir}/sysinfo-local.conf.txt"
