#include "pastafari/http_api/name_language.hpp"
#include "pastafari/http_api/date_conversion.hpp"
#include <cctype>

namespace pastafari::http_api {

std::vector<std::string> supportedNameLanguages(){
    return {std::string(DEFAULT_NAME_LANGUAGE)};
}

std::string normalizeNameLanguage(std::string_view language){
    if(language.empty()) return std::string(DEFAULT_NAME_LANGUAGE);
    std::string normalized(language);
    for(char& c:normalized) c=static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    if(normalized==DEFAULT_NAME_LANGUAGE) return normalized;
    throw DateError("LANGUAGE_NOT_SUPPORTED",
                    "lingua nominum nondum sustinetur: "+std::string(language));
}

CanonicalPastafariDate presentNames(const CanonicalPastafariDate& canonical,
                                    std::string_view language){
    // Hodie catalogus Latinus solus adest. Linguae addendae postea ex
    // cutletIndex/monthIndex eligentur, numquam ex computatione machinae mutata.
    (void)normalizeNameLanguage(language);
    return canonical;
}

} // namespace pastafari::http_api
