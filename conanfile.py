from conans import ConanFile


class CMakeEmbed(ConanFile):
    name = "cmake_embed"
    version = "0.1.0"
    revision_mode = "scm"
    exports_sources = "cmake/*", "EmbedResourcesConfig.cmake"

    def package_id(self):
        self.info.header_only()

    def package(self):
        self.copy("*.cmake", dst="cmake", src="cmake")
        self.copy("EmbedResourcesConfig.cmake", dst=".", src=".")
