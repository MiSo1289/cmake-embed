# Module for embedding resources in binaries

find_program(HEXDUMP_COMMAND NAMES xxd)

#[==[
  Adds an object library target containing embedded resources and
  generates a header file for them.
  Usage:
  add_embedded_resources(
    name  # Name of the created target

    OUT_DIR <dir>  # Directory where the header and sources will be created
    HEADER <header>  # Name of the generated header
    NAMESPACE [namespace]  # Namespace of created symbols (optional)
    RESOURCE_NAMES <names [...]>  # Names (symbols) of the resources
    RESOURCES <resources [...]>  # Resource files
  )
]==]
function(add_embedded_resources NAME)
  set(OPTIONS "")
  set(ONE_VALUE_ARGS OUT_DIR HEADER NAMESPACE)
  set(MULTI_VALUE_ARGS RESOURCE_NAMES RESOURCES)
  cmake_parse_arguments(ARGS "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN})

  if(NOT HEXDUMP_COMMAND)
    message(FATAL_ERROR "Cannot embed resources - xxd not found.")
  endif()

  set(FULL_HEADER_PATH "${ARGS_OUT_DIR}/${ARGS_HEADER}")

  add_library("${ARGS_NAME}" OBJECT)
  target_compile_features("${ARGS_NAME}" PUBLIC cxx_std_20)
  # fPIC not enabled automatically for object libraries due to defect in CMake
  set_target_properties(
    "${ARGS_NAME}"

    PROPERTIES
    POSITION_INDEPENDENT_CODE ON
  )

  file(
    "${FULL_HEADER_PATH}"

    WRITE
    "#pragma once\n"
    "\n"
    "#include <cstddef>\n"
    "#include <span>\n"
    "\n"
    "namespace ${ARGS_NAMESPACE}\n"
    "{\n"
  )

  if(DEFINED ARGS_NAMESPACE)
    file(
      "${FULL_HEADER_PATH}"

      APPEND
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
      "${FULL_HEADER_PATH}"

      APPEND
      "[[nodiscard]] auto ${RESOURCE_NAME}() noexcept -> std::span<std::byte>;\n"
    )

    # Write .cpp
    file(
      "${FULL_RESOURCE_UNIT_PATH}"

      WRITE
      "#include \"${ARGS_HEADER}\"\n"
      "\n"
      "#include <cstdint>\n"
      "\n"
    )

    if(DEFINED ARGS_NAMESPACE)
      file(
        "${FULL_RESOURCE_UNIT_PATH}"

        APPEND
        "namespace ${ARGS_NAMESPACE}\n"
        "{\n"
        "\n"
      )
    endif()

    file(
      "${FULL_RESOURCE_UNIT_PATH}"

      APPEND
      "namespace\n"
      "{\n"
      "\n"
      "std::uint8_t const ${RESOURCE_NAME}_data[] = {\n"
      "#include \"${RESOURCE_NAME}.inc\"\n"
      "};\n"
      "\n"
      "}  // namespace\n"
      "\n"
      "auto ${RESOURCE_NAME}() noexcept -> std::span<std::byte>\n"
      "{\n"
      "    return std::as_bytes(${RESOURCE_NAME}_data);\n"
      "}\n"
    )

    if(DEFINED ARGS_NAMESPACE)
      file(
        "${FULL_RESOURCE_UNIT_PATH}"

        APPEND
        "\n"
        "}  // namespace ${ARGS_NAMESPACE}\n"
      )
    endif()

    target_sources("${ARGS_NAME}" PRIVATE "${FULL_RESOURCE_UNIT_PATH}")

    add_custom_command(
      OUTPUT "${FULL_RESOURCE_HEX_PATH}"
      COMMAND "${HEXDUMP_COMMAND}" -i < "${RESOURCE}" > "${FULL_RESOURCE_HEX_PATH}"
      MAIN_DEPENDENCY "${RESOURCE}"
    )

    add_dependencies("${ARGS_NAME}" "${FULL_RESOURCE_HEX_PATH}")
  endforeach()

  if(DEFINED ARGS_NAMESPACE)
    file(
      "${FULL_HEADER_PATH}"

      APPEND
      "\n"
      "}  // namespace ${ARGS_NAMESPACE}\n"
    )
  endif()

  target_sources("${ARGS_NAME}" PUBLIC "${FULL_HEADER_PATH}")
endfunction()
