#include "binary.hpp"

#include <cstdint>

namespace test_resources
{

namespace
{

std::uint8_t const binary_data_data[] = {
#include "binary_data.inc"
};

}  // namespace

auto binary_data() noexcept -> std::span<std::byte const>
{
    return std::as_bytes(std::span{binary_data_data});
}

}  // namespace test_resources
