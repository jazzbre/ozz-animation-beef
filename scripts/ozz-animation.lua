project "ozz-animation"
	kind "StaticLib"
	windowstargetplatformversion("10.0")

	includedirs {
		path.join(SOURCE_DIR, "ozz-animation/include"),
      path.join(SOURCE_DIR, "ozz-animation/src")
	}

	files {
      path.join(SOURCE_DIR, "ozz-animation/include/**.h"),
      path.join(SOURCE_DIR, "ozz-animation/src/base/**.cc"),
      path.join(SOURCE_DIR, "ozz-animation/src/animation/runtime/*.cc"),
      path.join(SOURCE_DIR, "ozz-animation/src/geometry/**.cc"),
      path.join(SOURCE_DIR, "../csrc/**.cc"),
      path.join(SOURCE_DIR, "../csrc/**.h"),
	}

	configuration {}
