#include "pastafari/http_api/cors.hpp"
#include <algorithm>
#include <cctype>
#include <cstdlib>

namespace pastafari::http_api {
namespace {
std::string trim(std::string_view value) {
    std::size_t begin = 0;
    std::size_t end = value.size();
    while (begin < end && std::isspace(static_cast<unsigned char>(value[begin]))) ++begin;
    while (end > begin && std::isspace(static_cast<unsigned char>(value[end - 1]))) --end;
    return std::string(value.substr(begin, end - begin));
}
}

std::vector<std::string> parseCorsOrigins(std::string_view value) {
    std::vector<std::string> out;
    std::size_t pos = 0;
    while (pos <= value.size()) {
        const auto comma = value.find(',', pos);
        const auto piece = value.substr(pos, comma == std::string_view::npos ? value.size() - pos : comma - pos);
        auto origin = trim(piece);
        if (!origin.empty() && std::find(out.begin(), out.end(), origin) == out.end()) out.push_back(std::move(origin));
        if (comma == std::string_view::npos) break;
        pos = comma + 1;
    }
    return out;
}

CorsPolicy::CorsPolicy(std::vector<std::string> allowedOrigins)
    : allowedOrigins_(std::move(allowedOrigins)) {}

CorsPolicy CorsPolicy::fromEnvironment() {
    if (const char* configured = std::getenv("PASTAFARI_CORS_ORIGINS")) {
        return CorsPolicy(parseCorsOrigins(configured));
    }
    return CorsPolicy({std::string(DEFAULT_BROWSER_ORIGIN)});
}

bool CorsPolicy::allows(std::string_view origin) const {
    return std::any_of(allowedOrigins_.begin(), allowedOrigins_.end(),
                       [origin](const std::string& allowed) { return allowed == origin; });
}

} // namespace pastafari::http_api
