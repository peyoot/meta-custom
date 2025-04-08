# meta-custom/recipes-security/optee/optee-os-stm32mp_4.0.0.bbappend

#define an expected srcrev to check if patch need update or not
EXPECTED_SRCREV = "5c00c71b64a32a4f4bd7266ae88d34b7a07ebe5a"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://0001-ccmp25-dvk-adjust-dts-configuration.patch"

# add task to check upstream srcrev 

addtask check_src_rev after do_unpack before do_patch
python check_src_rev() {
    import subprocess

    # go to src dir and get current rev
    src_dir = d.getVar('S')
    cmd = "git rev-parse HEAD"
    result = subprocess.run(cmd, shell=True, cwd=src_dir, capture_output=True, text=True)
    current_rev = result.stdout.strip()

    # get expected_srcrev
    expected_rev = d.getVar('EXPECTED_SRCREV')

    # compare two commit version
    if current_rev != expected_rev:
        bb.fatal("optee-os-stm32mp version is different from the patch expected! SRC: %s , expected: %s . please use latest src to generate new patch file." % (current_rev, expected_rev))
    else:
        bb.note("optee-os-stm32mp src version is expected: %s" % current_rev)
}