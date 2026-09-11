# fcl_%.bbappend
# meta-custom/recipes-extended/fcl/
#
# WHY THIS EXISTS
# FCL's test suite (test_fcl_*.cpp) is extremely heavy to compile: each
# translation unit instantiates large Eigen/FCL template trees and a single
# cc1plus can exceed several GB of RAM. On a memory-constrained builder the
# kernel OOM killer terminates cc1plus mid-compile. In the log this shows up as
# a MISLEADING assembler error:
#
#   {standard input}: Error: leb128 operand is an undefined symbol: .L
#   aarch64-dey-linux-g++: fatal error: Killed signal terminated program cc1plus
#
# The real cause is the OOM kill (the "Killed ... cc1plus" line); the leb128 /
# "end of file not at end of a line" messages are just the assembler choking on
# the truncated output of the killed compiler.
#
# The target image never needs FCL's unit tests, so disable them. This drops
# the heaviest translation units entirely and resolves the OOM.

EXTRA_OECMAKE += "-DFCL_BUILD_TESTS=OFF -DBUILD_TESTING=OFF"