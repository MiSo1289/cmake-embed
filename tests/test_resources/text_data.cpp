#include "text.hpp"

#include <iterator>

namespace test_resources
{

namespace
{

char const text_data_data[] = {
#include "text_data.inc"
};

}  // namespace

auto text_data() noexcept -> std::string_view
{
    return std::string_view{text_data_data, std::size(text_data_data)};
}

}  // namespace test_resources
