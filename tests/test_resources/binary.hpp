#pragma once

#include <cstddef>
#include <span>

namespace test_resources
{

[[nodiscard]] auto binary_data() noexcept -> std::span<std::byte const>;

}  // namespace test_resources
