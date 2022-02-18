# Module for embedding resources in binaries

find_program(HEXDUMP_COMMAND NAMES xxd)

#[==[
  Adds an object library target containing embedded binary resources and
  generates a header file, where you can access them as `span<byte const>`.
  Usage:
  add_embedded_binary_resources(
    name  # Name of the created target

    OUT_DIR <dir>  # Directory where the header and sources will be created
    HEADER <header>  # Name of the generated header
    NAMESPACE [namespace]  # Namespace of created symbols (optional)
    RESOURCE_NAMES <names [...]>  # Names (symbols) of the resources
    RESOURCES <resources [...]>  # Resource files
    SPAN_NAMESPACE [namespace]  # Namespace with the `span` type, default `std`
    SPAN_HEADER [header]  # Header with the `span` type, default `<span>`
    BYTE_NAMESPACE [namespace]  # Namespace with the `byte` type, default `std`
    BYTE_HEADER [header]  # Header with the `byte` type, default `<cstddef>`
  )
]==]
function(add_embedded_binary_resources NAME)
  set(OPTIONS "")
  set(ONE_VALUE_ARGS OUT_DIR HEADER NAMESPACE SPAN_NAMESPACE SPAN_HEADER BYTE_NAMESPACE BYTE_HEADER)
  set(MULTI_VALUE_ARGS RESOURCE_NAMES RESOURCES)
  cmake_parse_arguments(ARGS "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN})

  if(NOT HEXDUMP_COMMAND)
    message(FATAL_ERROR "Cannot embed resources - xxd not found.")
  endif()

  set(FULL_HEADER_PATH "${CMAKE_CURRENT_BINARY_DIR}/${ARGS_OUT_DIR}/${ARGS_HEADER}")

  if(NOT DEFINED ARGS_SPAN_NAMESPACE)
    set(ARGS_SPAN_NAMESPACE "std")
  endif()

  if(NOT DEFINED ARGS_SPAN_HEADER)
    set(ARGS_SPAN_HEADER "<span>")
  endif()

  if(NOT DEFINED ARGS_BYTE_NAMESPACE)
    set(ARGS_BYTE_NAMESPACE "std")
  endif()

  if(NOT DEFINED ARGS_BYTE_HEADER)
    set(ARGS_BYTE_HEADER "<cstddef>")
  endif()

  add_library("${NAME}" OBJECT)
  target_include_directories("${NAME}" PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")

  if(ARGS_SPAN_HEADER STREQUAL "<span>")
    target_compile_features("${NAME}" PUBLIC cxx_std_20)
  else()
    target_compile_features("${NAME}" PUBLIC cxx_std_17)
  endif()

  # fPIC not added automatically to object libraries due to defect in CMake
  set_target_properties(
    "${NAME}"

    PROPERTIES
    POSITION_INDEPENDENT_CODE ON
  )

  file(
    WRITE "${FULL_HEADER_PATH}"

    "#pragma once\n"
    "\n"
    "#include ${ARGS_BYTE_HEADER}\n"
    "#include ${ARGS_SPAN_HEADER}\n"
    "\n"
  )

  if(DEFINED ARGS_NAMESPACE)
    file(
      APPEND "${FULL_HEADER_PATH}"

      "namespace ${ARGS_NAMESPACE}\n"
      "{\n"
      "\n"
    )
  endif()

  foreach(RESOURCE_NAME RESOURCE IN ZIP_LISTS ARGS_RESOURCE_NAMES ARGS_RESOURCES)
    set(FULL_RESOURCE_UNIT_PATH "${ARGS_OUT_DIR}/${RESOURCE_NAME}.cpp")
    set(FULL_RESOURCE_HEX_PATH "${ARGS_OUT_DIR}/${RESOURCE_NAME}.inc")

    # Add symbol to header
    file(
      APPEND "${FULL_HEADER_PATH}"

      "[[nodiscard]] auto ${RESOURCE_NAME}() noexcept -> ${ARGS_SPAN_NAMESPACE}::span<${ARGS_BYTE_NAMESPACE}::byte const>;\n"
      "\n"
    )

    # Write .cpp
    file(
      WRITE "${FULL_RESOURCE_UNIT_PATH}"

      "#include \"${ARGS_HEADER}\"\n"
      "\n"
      "#include <cstdint>\n"
      "\n"
    )

    if(DEFINED ARGS_NAMESPACE)
      file(
        APPEND "${FULL_RESOURCE_UNIT_PATH}"

        "namespace ${ARGS_NAMESPACE}\n"
        "{\n"
        "\n"
      )
    endif()

    file(
      APPEND "${FULL_RESOURCE_UNIT_PATH}"

      "namespace\n"
      "{\n"
      "\n"
      "std::uint8_t const ${RESOURCE_NAME}_data[] = {\n"
      "#include \"${RESOURCE_NAME}.inc\"\n"
      "};\n"
      "\n"
      "}  // namespace\n"
      "\n"
      "auto ${RESOURCE_NAME}() noexcept -> ${ARGS_SPAN_NAMESPACE}::span<${ARGS_BYTE_NAMESPACE}::byte const>\n"
      "{\n"
      "    return ${ARGS_SPAN_NAMESPACE}::as_bytes(${ARGS_SPAN_NAMESPACE}::span{${RESOURCE_NAME}_data});\n"
      "}\n"
    )

    if(DEFINED ARGS_NAMESPACE)
      file(
        APPEND "${FULL_RESOURCE_UNIT_PATH}"

        "\n"
        "}  // namespace ${ARGS_NAMESPACE}\n"
      )
    endif()

    target_sources("${NAME}" PRIVATE "${FULL_RESOURCE_UNIT_PATH}")

    add_custom_command(
      OUTPUT "${FULL_RESOURCE_HEX_PATH}"
      COMMAND "${HEXDUMP_COMMAND}" -i < "${RESOURCE}" > "${FULL_RESOURCE_HEX_PATH}"
      MAIN_DEPENDENCY "${RESOURCE}"
    )
    list(APPEND RESOURCES_HEX_FILES "${FULL_RESOURCE_HEX_PATH}")
  endforeach()

  if(DEFINED ARGS_NAMESPACE)
    file(
      APPEND "${FULL_HEADER_PATH}"

      "}  // namespace ${ARGS_NAMESPACE}\n"
    )
  endif()

  target_sources("${NAME}" PUBLIC "${FULL_HEADER_PATH}")

  add_custom_target("${NAME}_hexdump" DEPENDS "${RESOURCES_HEX_FILES}")
  add_dependencies("${NAME}" "${NAME}_hexdump")
endfunction()

#[==[
  Adds an object library target containing embedded text resources and
  generates a header file, where you can access them as `string_view`.
  Usage:
  add_embedded_text_resources(
    name  # Name of the created target

    OUT_DIR <dir>  # Directory where the header and sources will be created
    HEADER <header>  # Name of the generated header
    NAMESPACE [namespace]  # Namespace of created symbols (optional)
    RESOURCE_NAMES <names [...]>  # Names (symbols) of the resources
    RESOURCES <resources [...]>  # Resource files
    STRING_VIEW_NAMESPACE [namespace]  # Namespace with the `string_view` type, default `std`
    STRING_VIEW_HEADER [header]  # Header with the `string_view` type, default `<string_view>`
  )
]==]
function(add_embedded_text_resources NAME)
  set(OPTIONS "")
  set(ONE_VALUE_ARGS OUT_DIR HEADER NAMESPACE STRING_VIEW_NAMESPACE STRING_VIEW_HEADER)
  set(MULTI_VALUE_ARGS RESOURCE_NAMES RESOURCES)
  cmake_parse_arguments(ARGS "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN})

  if(NOT HEXDUMP_COMMAND)
    message(FATAL_ERROR "Cannot embed resources - xxd not found.")
  endif()

  set(FULL_HEADER_PATH "${CMAKE_CURRENT_BINARY_DIR}/${ARGS_OUT_DIR}/${ARGS_HEADER}")

  if(NOT DEFINED ARGS_STRING_VIEW_NAMESPACE)
    set(ARGS_STRING_VIEW_NAMESPACE "std")
  endif()

  if(NOT DEFINED ARGS_STRING_VIEW_HEADER)
    set(ARGS_STRING_VIEW_HEADER "<string_view>")
  endif()

  add_library("${NAME}" OBJECT)
  target_include_directories("${NAME}" PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")

  target_compile_features("${NAME}" PUBLIC cxx_std_17)

  # fPIC not added automatically to object libraries due to defect in CMake
  set_target_properties(
    "${NAME}"

    PROPERTIES
    POSITION_INDEPENDENT_CODE ON
  )

  file(
    WRITE "${FULL_HEADER_PATH}"

    "#pragma once\n"
    "\n"
    "#include ${ARGS_STRING_VIEW_HEADER}\n"
    "\n"
  )

  if(DEFINED ARGS_NAMESPACE)
    file(
      APPEND "${FULL_HEADER_PATH}"

      "namespace ${ARGS_NAMESPACE}\n"
      "{\n"
      "\n"
    )
  endif()

  foreach(RESOURCE_NAME RESOURCE IN ZIP_LISTS ARGS_RESOURCE_NAMES ARGS_RESOURCES)
    set(FULL_RESOURCE_UNIT_PATH "${ARGS_OUT_DIR}/${RESOURCE_NAME}.cpp")
    set(FULL_RESOURCE_HEX_PATH "${ARGS_OUT_DIR}/${RESOURCE_NAME}.inc")

    # Add symbol to header
    file(
      APPEND "${FULL_HEADER_PATH}"

      "[[nodiscard]] auto ${RESOURCE_NAME}() noexcept -> ${ARGS_STRING_VIEW_NAMESPACE}::string_view;\n"
      "\n"
    )

    # Write .cpp
    file(
      WRITE "${FULL_RESOURCE_UNIT_PATH}"

      "#include \"${ARGS_HEADER}\"\n"
      "\n"
      "#include <iterator>\n"
      "\n"
    )

    if(DEFINED ARGS_NAMESPACE)
      file(
        APPEND "${FULL_RESOURCE_UNIT_PATH}"

        "namespace ${ARGS_NAMESPACE}\n"
        "{\n"
        "\n"
      )
    endif()

    file(
      APPEND "${FULL_RESOURCE_UNIT_PATH}"

      "namespace\n"
      "{\n"
      "\n"
      "char const ${RESOURCE_NAME}_data[] = {\n"
      "#include \"${RESOURCE_NAME}.inc\"\n"
      "};\n"
      "\n"
      "}  // namespace\n"
      "\n"
      "auto ${RESOURCE_NAME}() noexcept -> ${ARGS_STRING_VIEW_NAMESPACE}::string_view\n"
      "{\n"
      "    return ${ARGS_STRING_VIEW_NAMESPACE}::string_view{${RESOURCE_NAME}_data, std::size(${RESOURCE_NAME}_data)};\n"
      "}\n"
    )

    if(DEFINED ARGS_NAMESPACE)
      file(
        APPEND "${FULL_RESOURCE_UNIT_PATH}"

        "\n"
        "}  // namespace ${ARGS_NAMESPACE}\n"
      )
    endif()

    target_sources("${NAME}" PRIVATE "${FULL_RESOURCE_UNIT_PATH}")

    add_custom_command(
      OUTPUT "${FULL_RESOURCE_HEX_PATH}"
      COMMAND "${HEXDUMP_COMMAND}" -i < "${RESOURCE}" > "${FULL_RESOURCE_HEX_PATH}"
      MAIN_DEPENDENCY "${RESOURCE}"
    )
    list(APPEND RESOURCES_HEX_FILES "${FULL_RESOURCE_HEX_PATH}")
  endforeach()

  if(DEFINED ARGS_NAMESPACE)
    file(
      APPEND "${FULL_HEADER_PATH}"

      "}  // namespace ${ARGS_NAMESPACE}\n"
    )
  endif()

  target_sources("${NAME}" PUBLIC "${FULL_HEADER_PATH}")

  add_custom_target("${NAME}_hexdump" DEPENDS "${RESOURCES_HEX_FILES}")
  add_dependencies("${NAME}" "${NAME}_hexdump")
endfunction()
