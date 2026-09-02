#pragma once
#include "engine_day.hpp"
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace pastafari::http_api {
struct CivilDate { Integer year; int month{}; int day{}; };
struct ParseCandidate { std::string format; CivilDate date; Integer jdn; Integer engineDay; };
struct ResolvedDate {
    std::string source;
    std::string calendar;
    std::string detectedFormat;
    std::string normalized;
    Integer jdn;
    Integer engineDay;
};
class DateError : public std::runtime_error {
public:
    std::string code;
    explicit DateError(std::string c, std::string m) : std::runtime_error(std::move(m)), code(std::move(c)) {}
};

Integer gregorianToJdn(const CivilDate& d);
Integer julianToJdn(const CivilDate& d);
Integer hebrewToJdn(const CivilDate& d);
Integer islamicCivilToJdn(const CivilDate& d);
CivilDate jdnToGregorian(const Integer& jdn);
std::string normalizeYmd(const CivilDate& d);
ResolvedDate resolveDate(std::string_view value,
                         std::string_view calendar = "gregorian",
                         std::string_view format = "auto");
std::vector<std::string> supportedCalendars();
} // namespace pastafari::http_api
