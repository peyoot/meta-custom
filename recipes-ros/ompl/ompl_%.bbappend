# ompl_%.bbappend
# meta-custom/recipes-ros/ompl/
#
# WHY THIS EXISTS
# ompl is a ROS package with <build_type>cmake</build_type> (NOT ament), so it
# inherits ros_cmake and does NOT get meta-ros's global "-DBUILD_TESTING=OFF"
# that ament packages receive. As a result OMPL builds its tests, demos and
# Python bindings by default — all wasted on a headless target and heavy on RAM
# (Boost.Test translation units), i.e. another OOM candidate on small builders.
#
# moveit-planners-ompl only links the OMPL C++ library (libompl), so we can
# safely turn everything else off.

EXTRA_OECMAKE += " \
    -DOMPL_BUILD_TESTS=OFF \
    -DOMPL_BUILD_DEMOS=OFF \
    -DOMPL_BUILD_PYTESTS=OFF \
    -DOMPL_BUILD_PYBINDINGS=OFF \
    -DOMPL_REGISTRATION=OFF \
"
