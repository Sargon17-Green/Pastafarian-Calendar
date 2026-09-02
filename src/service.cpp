#include "pastafari/http_api/service.hpp"
#include <cctype>
#include <limits>
#include <sstream>

namespace pastafari::http_api {
namespace {
long long floorToLongLong(const Integer& v) {
    try { return v.convert_to<long long>(); }
    catch (...) { throw DateError("INVALID_INSTANT", "nota temporis extra spatium sustentatum est"); }
}

bool allDigits(std::string_view s) {
    if (s.empty()) return false;
    for (char c : s) if (!std::isdigit(static_cast<unsigned char>(c))) return false;
    return true;
}

int parseFixed(std::string_view s) {
    if (!allDigits(s)) throw DateError("INVALID_INSTANT", "momentum debet esse RFC3339 cum zona temporaria");
    int value = 0;
    for (char c : s) value = value * 10 + (c - '0');
    return value;
}

[[noreturn]] void invalidInstant() {
    throw DateError("INVALID_INSTANT", "momentum debet esse RFC3339 cum zona temporaria");
}
} // namespace

std::int64_t parseRfc3339Milliseconds(std::string_view s) {
    if (s.size() < 20 || s[4] != '-' || s[7] != '-' || s[10] != 'T' ||
        s[13] != ':' || s[16] != ':') {
        invalidInstant();
    }

    const int y = parseFixed(s.substr(0,4));
    const int mo = parseFixed(s.substr(5,2));
    const int d = parseFixed(s.substr(8,2));
    const int h = parseFixed(s.substr(11,2));
    const int mi = parseFixed(s.substr(14,2));
    const int sec = parseFixed(s.substr(17,2));
    if (h > 23 || mi > 59 || sec > 59) throw DateError("INVALID_INSTANT", "tempus horologii invalidum est");

    std::size_t pos = 19;
    int ms = 0;
    if (pos < s.size() && s[pos] == '.') {
        ++pos;
        const std::size_t fractionStart = pos;
        while (pos < s.size() && std::isdigit(static_cast<unsigned char>(s[pos]))) ++pos;
        const std::size_t digits = pos - fractionStart;
        if (digits < 1 || digits > 3) invalidInstant();
        ms = parseFixed(s.substr(fractionStart, digits));
        if (digits == 1) ms *= 100;
        else if (digits == 2) ms *= 10;
    }

    long long offsetSeconds = 0;
    if (pos < s.size() && s[pos] == 'Z') {
        if (pos + 1 != s.size()) invalidInstant();
    } else {
        if (pos + 6 != s.size() || (s[pos] != '+' && s[pos] != '-') || s[pos+3] != ':') invalidInstant();
        const int oh = parseFixed(s.substr(pos+1,2));
        const int om = parseFixed(s.substr(pos+4,2));
        if (oh > 23 || om > 59) throw DateError("INVALID_INSTANT", "discrimen zonae temporariae invalidum est");
        offsetSeconds = (oh * 3600LL + om * 60LL) * (s[pos] == '+' ? 1 : -1);
    }

    const Integer jdn = gregorianToJdn({Integer{y}, mo, d});
    const Integer days = jdn - Integer{2440588}; // 1970-01-01 media nox civilis.
    const long long dayCount = floorToLongLong(days);
    const __int128 total = static_cast<__int128>(dayCount) * 86400000
        + ((h * 3600LL + mi * 60LL + sec - offsetSeconds) * 1000LL) + ms;
    if (total < std::numeric_limits<std::int64_t>::min() || total > std::numeric_limits<std::int64_t>::max()) {
        throw DateError("INVALID_INSTANT", "momentum extra spatium millisecondorum int64 est");
    }
    return static_cast<std::int64_t>(total);
}

std::string formatRfc3339Milliseconds(std::int64_t millis) {
    std::int64_t days = millis / 86400000;
    std::int64_t rem = millis % 86400000;
    if (rem < 0) { rem += 86400000; --days; }
    const auto d = jdnToGregorian(Integer{2440588} + days);
    const int h = static_cast<int>(rem / 3600000); rem %= 3600000;
    const int mi = static_cast<int>(rem / 60000); rem %= 60000;
    const int sec = static_cast<int>(rem / 1000);
    const int ms = static_cast<int>(rem % 1000);
    std::ostringstream o;
    o << d.year << '-'; o.width(2); o.fill('0'); o << d.month << '-'; o.width(2); o << d.day
      << 'T'; o.width(2); o << h << ':'; o.width(2); o << mi << ':'; o.width(2); o << sec
      << '.'; o.width(3); o << ms << 'Z';
    return o.str();
}

ResolvedCalculation CalendarService::resolveCalculation(const CalculationSpec& s, std::int64_t requestMs) const {
    if (s.mode == CalculationMode::EngineDay) {
        Integer d;
        try { d = parseCanonicalDecimal(s.value); }
        catch (...) { throw DateError("INVALID_INTEGER", "calculation engine-day debet esse decimalis canonicus"); }
        return {"explicit-engine-day", "", d, std::nullopt, std::nullopt, std::nullopt, ""};
    }
    const std::int64_t ms = s.mode == CalculationMode::Instant ? parseRfc3339Milliseconds(s.value) : requestMs;
    const auto r = currentDayAtUnixMilliseconds(ms);
    return {s.mode == CalculationMode::Instant ? "explicit-instant" : "request-instant",
            formatRfc3339Milliseconds(ms), r.engineDay, r.jdn,
            r.previousBoundary.jd, r.nextBoundary.jd, r.modelVersion};
}

SingleResult CalendarService::calculate(const TargetSpec& t, const CalculationSpec& c, std::int64_t ms,
                                        std::string_view language) {
    const auto normalizedLanguage = normalizeNameLanguage(language);
    const auto rc = resolveCalculation(c, ms);
    const auto rt = resolveDate(t.value, t.calendar, t.format);
    const auto canonical = engine_.calculate(rc.engineDay, rt.engineDay);
    return {rc, rt, normalizedLanguage, presentNames(canonical, normalizedLanguage)};
}

std::vector<SingleResult> CalendarService::calculateBatch(const std::vector<TargetSpec>& ts,
                                                          const CalculationSpec& c,
                                                          std::int64_t ms,
                                                          std::string_view language) {
    if (ts.size() > 1024) throw DateError("BATCH_TOO_LARGE", "numerus maximus elementorum in batch est 1024");
    const auto normalizedLanguage = normalizeNameLanguage(language);
    const auto rc = resolveCalculation(c, ms);
    std::vector<SingleResult> out;
    out.reserve(ts.size());
    for (const auto& t : ts) {
        const auto rt = resolveDate(t.value, t.calendar, t.format);
        const auto canonical = engine_.calculate(rc.engineDay, rt.engineDay);
        out.push_back({rc, rt, normalizedLanguage, presentNames(canonical, normalizedLanguage)});
    }
    return out;
}
} // namespace pastafari::http_api
