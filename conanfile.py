from conans import ConanFile


class CMakeEmbed(ConanFile):
    name = "cmake_embed"
    version = "0.3.0"
    description = "CMake script for embedding resources in binaries."
    homepage = "https://github.com/MiSo1289/cmake-embed"
    url = "https://github.com/MiSo1289/cmake-embed"
    license = "MIT"
    revision_mode = "scm"
    exports_sources = "cmake/*"

    def package(self):
        self.copy("*.cmake", dst="cmake", src="cmake")

    def package_id(self):
        self.info.header_only()

    def package_info(self):
        self.cpp_info.builddirs = ["cmake"]
