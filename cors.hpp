#pragma once
#include <string>
#include <string_view>
#include <vector>

namespace pastafari::http_api {

inline constexpr std::string_view DEFAULT_BROWSER_ORIGIN =
    "https://bwtbdyqtmsprytgydym-cpu.github.io";

class CorsPolicy {
    std::vector<std::string> allowedOrigins_;
public:
    explicit CorsPolicy(std::vector<std::string> allowedOrigins);
    static CorsPolicy fromEnvironment();
    bool allows(std::string_view origin) const;
    const std::vector<std::string>& allowedOrigins() const noexcept { return allowedOrigins_; }
};

std::vector<std::string> parseCorsOrigins(std::string_view value);

} // namespace pastafari::http_api
