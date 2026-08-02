# control-toolbox_%.bbappend
# meta-custom/recipes-ros/control-toolbox/
#
# WHY THIS EXISTS
# do_patch fails with:
#   Hunk #1 FAILED ... custom_validators.hpp
#   Patch use-upstream-tl-expected.patch can be reverse-applied
#
# "can be reverse-applied" means the change is ALREADY present in the checked-
# out source. This meta-ros snapshot still carries use-upstream-tl-expected.patch,
# but the pinned control_toolbox source already switched to the upstream
# tl::expected, so the patch is redundant and conflicts. Current meta-ros tip
# has dropped this patch entirely and relies on the DEPENDS on libexpected-dev
# (provided by cpp-polyfills/tl-expected) instead.
#
# Drop the redundant patch. The source keeps exactly the state the patch wanted.
#
# NOTE: the string below must match the SRC_URI entry EXACTLY as it appears in
# your recipe. Confirm with:
#   grep -rn "use-upstream-tl-expected" sources/meta-ros/
# and adjust if it carries extra params (e.g. ;striplevel=1).

SRC_URI:remove = "file://use-upstream-tl-expected.patch"