# meta-custom/recipes-digi/sysinfo/sysinfo.bbappend
#
# Use meta-custom's copy of the sysinfo script (recipes-digi/sysinfo/sysinfo/sysinfo)
# instead of the one in meta-digi-dey, and fill in build-host information.

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The values below come from the build host's filesystem and are not part of the
# task signature, so force do_install to run every time. Remove this line if you
# prefer to run "bitbake -c cleansstate sysinfo" manually after changing
# manifest/project.
do_install[nostamp] = "1"

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

    # replace placeholders in the installed script (bindir or sbindir)
    find ${D} -type f -name sysinfo -exec sed -i \
        -e "s|@CUSTOM_BRANCH@|$branch|" \
        -e "s|@CUSTOM_MANIFEST_XML@|$xml|" \
        -e "s|@CUSTOM_PROJECT_NAME@|$proj|" {} +
}
