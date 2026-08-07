# tl-expected_%.bbappend
# meta-custom/recipes-devtools/tl-expected/
#
# WHY THIS EXISTS
# do_rootfs fails with:
#   nothing provides tl-expected needed by rsl-... / joint-trajectory-controller-...
#
# tl-expected (meta-ros's hand-written recipes-devtools/tl-expected, which
# replaces the BBMASK'd cpp-polyfills generated recipe) is a HEADER-ONLY
# library: all files land in tl-expected-dev, so the runtime package
# ${PN} (tl-expected) is empty and — by OE default — not emitted at all.
#
# But ROS consumers RDEPEND on the runtime package tl-expected (their
# package.xml <depend> maps via ROS_UNRESOLVED_DEP-libexpected-dev = "tl-expected").
# With no runtime tl-expected package, rootfs assembly can't resolve it.
#
# Emit an empty runtime package so the dependency resolves. This is the same
# pattern meta-ros already uses for pybind11-vendor. The dependency is
# effectively build-time only (headers compiled in), so an empty runtime
# package is semantically correct.

ALLOW_EMPTY:${PN} = "1"