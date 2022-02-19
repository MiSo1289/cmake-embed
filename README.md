# CMake embed

CMake script for embedding resources in binaries.

Resources are embedded in an object library target, and can be accessed via functions in a generated header.

For the script to work, the `xxd` program must be available to CMake.

## Example usage:

`CMakeLists.txt`
```cmake
include(EmbedResources)

add_embedded_binary_resources(
  foo_resources_binary
  OUT_DIR foo/resources
  HEADER binary.hpp
  NAMESPACE foo::resources
  RESOURCE_NAMES resource_a resource_b
  RESOURCES 
  "${PROJECT_SOURCE_DIR}/data/resource_a.bin"
  "${PROJECT_SOURCE_DIR}/data/resource_b.bin"
)

add_embedded_text_resources(
  foo_resources_text
  OUT_DIR foo/resources
  HEADER text.hpp
  NAMESPACE foo::resources
  RESOURCE_NAMES resource_c
  RESOURCES 
  "${PROJECT_SOURCE_DIR}/data/resource_c.txt"
)

add_executable(foo)
target_sources(foo PRIVATE foo.cpp)
target_link_libraries(
    foo PRIVATE 
    foo_resources_binary foo_resources_text
)
```

`foo.cpp`
```c++
#include <foo/resources/binary.hpp>
#include <foo/resources/text.hpp>

auto main() -> int 
{
    std::span<std::byte const> resource_a = foo::resources::resource_a();
    std::span<std::byte const> resource_b = foo::resources::resource_b();

    std::string_view resource_c = foo::resources::resource_c();

    // ... use the resources ...
}

```

## Using with older C++ standards

You can override the `span`, `byte` and `string_view` types in the generated files to be from a library with a compatible interface instead of `std` (e.g. span-lite, Microsoft.GSL). See the documentation in the `EmbedResources.cmake` script.
