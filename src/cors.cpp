#include "pastafari/http_api/cors.hpp"
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <stdexcept>

namespace pastafari::http_api {
namespace {
std::string trim(std::string_view value) {
    std::size_t begin = 0;
    std::size_t end = value.size();
    while (begin < end && std::isspace(static_cast<unsigned char>(value[begin]))) ++begin;
    while (end > begin && std::isspace(static_cast<unsigned char>(value[end - 1]))) --end;
    return std::string(value.substr(begin, end - begin));
}

bool parseBooleanFlag(std::string_view raw) {
    std::string value = trim(raw);
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
    if (value == "1" || value == "true" || value == "yes" || value == "on") return true;
    if (value == "0" || value == "false" || value == "no" || value == "off") return false;
    throw std::invalid_argument("PASTAFARI_CORS_ALLOW_NULL_ORIGIN must be 1/0, true/false, yes/no, or on/off");
}
}

std::vector<std::string> parseCorsOrigins(std::string_view value) {
    std::vector<std::string> out;
    std::size_t pos = 0;
    while (pos <= value.size()) {
        const auto comma = value.find(',', pos);
        const auto piece = value.substr(pos, comma == std::string_view::npos ? value.size() - pos : comma - pos);
        auto origin = trim(piece);
        if (!origin.empty() && origin != "null" &&
            std::find(out.begin(), out.end(), origin) == out.end()) {
            out.push_back(std::move(origin));
        }
        if (comma == std::string_view::npos) break;
        pos = comma + 1;
    }
    return out;
}

CorsPolicy::CorsPolicy(std::vector<std::string> allowedOrigins, bool allowNullOrigin)
    : allowedOrigins_(std::move(allowedOrigins)), allowNullOrigin_(allowNullOrigin) {}

CorsPolicy CorsPolicy::fromEnvironment() {
    bool allowNullOrigin = DEFAULT_ALLOW_NULL_ORIGIN;
    if (const char* configuredNull = std::getenv("PASTAFARI_CORS_ALLOW_NULL_ORIGIN")) {
        allowNullOrigin = parseBooleanFlag(configuredNull);
    }

    if (const char* configured = std::getenv("PASTAFARI_CORS_ORIGINS")) {
        return CorsPolicy(parseCorsOrigins(configured), allowNullOrigin);
    }
    return CorsPolicy({std::string(DEFAULT_BROWSER_ORIGIN)}, allowNullOrigin);
}

bool CorsPolicy::allows(std::string_view origin) const {
    if (origin == "null") return allowNullOrigin_;
    return std::any_of(allowedOrigins_.begin(), allowedOrigins_.end(),
                       [origin](const std::string& allowed) { return allowed == origin; });
}

} // namespace pastafari::http_api
