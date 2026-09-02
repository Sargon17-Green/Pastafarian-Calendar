#pragma once
#include "engine_port.hpp"
#include <string>
#include <string_view>
#include <vector>

namespace pastafari::http_api {

inline constexpr std::string_view DEFAULT_NAME_LANGUAGE = "la";

// Stratum praesentandi tantum: semantica calendarii et cache machinae hic non mutantur.
// Linguae futurae ex indicibus canonicis nomina localia eligent.
std::vector<std::string> supportedNameLanguages();
std::string normalizeNameLanguage(std::string_view language);
CanonicalPastafariDate presentNames(const CanonicalPastafariDate& canonical,
                                    std::string_view language);

} // namespace pastafari::http_api
