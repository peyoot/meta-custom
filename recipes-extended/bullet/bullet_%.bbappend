# bullet_%.bbappend
# meta-custom/recipes-extended/bullet/
#
# WHY THIS EXISTS
# MoveIt uses only Bullet's collision library (BulletCollision / LinearMath),
# which is pure math and needs no OpenGL. The meta-ros bullet recipe, however,
# unconditionally adds 'libglu' to DEPENDS whenever 'opengl' is a DISTRO_FEATURE:
#
#     DEPENDS += "${@bb.utils.contains('DISTRO_FEATURES','opengl', \
#                  'virtual/libgl libglu','',d)}"
#
# DEY / OpenSTLinux keeps 'opengl' in DISTRO_FEATURES for the Wayland/GLES GPU
# stack, but NOT 'x11'. libglu (GLU) has REQUIRED_DISTRO_FEATURES = "x11", so on
# a headless Wayland image it is unbuildable and drags bullet -> moveit-core down
# with it. Bullet's GL demos are already disabled in the recipe
# (BUILD_OPENGL3_DEMOS=OFF, BUILD_CPU_DEMOS=OFF, ...), so GLU is never used.
#
# Drop only libglu. virtual/libgl is kept because on DEY it is provided by the
# ST GPU userspace (EGL/GLES) without requiring x11; if your configuration also
# couples virtual/libgl to x11, add it to the remove list as well.

DEPENDS:remove = "libglu"

# Optional belt-and-suspenders: MoveIt does not use pybullet or Bullet's EGL
# rendering. Uncomment to fully decouple Bullet from the GL/EGL stack if you
# hit further GL-related build issues and don't need pybullet:
#
# EXTRA_OECMAKE:remove = "-DBT_USE_EGL=ON"
# EXTRA_OECMAKE += "-DBUILD_PYBULLET=OFF"