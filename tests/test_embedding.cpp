#include <algorithm>
#include <array>
#include <cassert>
#include <span>
#include <string_view>

#include <test_resources/binary.hpp>
#include <test_resources/text.hpp>

auto main() -> int
{
    using namespace std::literals;

    constexpr auto expected = "Hello world"sv;
    
    assert(std::ranges::equal(test_resources::binary_data(), std::as_bytes(std::span{expected})));
    assert(test_resources::text_data() == expected);
}
