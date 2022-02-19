from conans import ConanFile


class CMakeEmbed(ConanFile):
    name = "cmake_embed"
    version = "0.3.0"
    revision_mode = "scm"
    exports_sources = "cmake/*"

    def package(self):
        self.copy("*.cmake", dst="cmake", src="cmake")

    def package_id(self):
        self.info.header_only()

    def package_info(self):
        self.cpp_info.builddirs = ["cmake"]
