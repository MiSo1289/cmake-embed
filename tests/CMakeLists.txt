enable_testing()
include(EmbedResources)

add_embedded_binary_resources(
  test_resources_binary
  OUT_DIR test_resources
  HEADER binary.hpp
  NAMESPACE test_resources
  RESOURCE_NAMES binary_data
  RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/data.txt"
)

add_embedded_text_resources(
  test_resources_text
  OUT_DIR test_resources
  HEADER text.hpp
  NAMESPACE test_resources
  RESOURCE_NAMES text_data
  RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/data.txt"
)

add_executable(test_embedding)
add_test(test_embedding test_embedding)

target_sources(test_embedding PRIVATE test_embedding.cpp)
target_link_libraries(test_embedding PRIVATE test_resources_binary test_resources_text)
