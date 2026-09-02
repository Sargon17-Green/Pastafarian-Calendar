#pragma once
#include <string>
#include <string_view>
#include <vector>

namespace pastafari::http_api {

inline constexpr std::string_view DEFAULT_BROWSER_ORIGIN =
    "https://bwtbdyqtmsprytgydym-cpu.github.io";
inline constexpr bool DEFAULT_ALLOW_NULL_ORIGIN = true;

class CorsPolicy {
    std::vector<std::string> allowedOrigins_;
    bool allowNullOrigin_ = DEFAULT_ALLOW_NULL_ORIGIN;
public:
    explicit CorsPolicy(std::vector<std::string> allowedOrigins,
                        bool allowNullOrigin = DEFAULT_ALLOW_NULL_ORIGIN);
    static CorsPolicy fromEnvironment();
    bool allows(std::string_view origin) const;
    bool allowsNullOrigin() const noexcept { return allowNullOrigin_; }
    const std::vector<std::string>& allowedOrigins() const noexcept { return allowedOrigins_; }
};

std::vector<std::string> parseCorsOrigins(std::string_view value);

} // namespace pastafari::http_api
