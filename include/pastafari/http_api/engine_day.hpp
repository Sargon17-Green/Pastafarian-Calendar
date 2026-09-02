#pragma once

#include <boost/multiprecision/cpp_int.hpp>
#include <stdexcept>
#include <string>
#include <string_view>

namespace pastafari::http_api {
using Integer = boost::multiprecision::cpp_int;
inline const Integer ENGINE_JDN_OFFSET = Integer{1721425};
inline const Integer FOUNDATION_JDN = Integer{-13334246};
inline const Integer FOUNDATION_ENGINE_DAY = Integer{-15055671};

inline Integer floorDiv(Integer a, const Integer& b) {
    if (b == 0) throw std::domain_error("division by zero");
    Integer q = a / b;
    Integer r = a % b;
    if (r != 0 && ((r > 0) != (b > 0))) --q;
    return q;
}

inline Integer mod(Integer a, const Integer& b) {
    Integer r = a % b;
    if (r < 0) r += (b < 0 ? -b : b);
    return r;
}

inline Integer jdnToEngineDay(const Integer& jdn) { return jdn - ENGINE_JDN_OFFSET; }
inline Integer engineDayToJdn(const Integer& day) { return day + ENGINE_JDN_OFFSET; }

inline bool isCanonicalDecimal(std::string_view s) {
    if (s.empty()) return false;
    std::size_t i = 0;
    if (s[0] == '-') {
        if (s.size() == 1) return false;
        i = 1;
    }
    if (s[i] == '0') return i + 1 == s.size();
    if (s[i] < '1' || s[i] > '9') return false;
    for (++i; i < s.size(); ++i) if (s[i] < '0' || s[i] > '9') return false;
    return true;
}

inline Integer parseCanonicalDecimal(std::string_view s) {
    if (!isCanonicalDecimal(s)) throw std::invalid_argument("integer debet esse decimalis canonicus");
    return Integer{std::string(s)};
}

inline std::string decimal(const Integer& value) { return value.convert_to<std::string>(); }
} // namespace pastafari::http_api
