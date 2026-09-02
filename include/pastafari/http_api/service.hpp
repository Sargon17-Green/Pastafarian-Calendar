#pragma once
#include "date_conversion.hpp"
#include "engine_port.hpp"
#include "name_language.hpp"
#include "venus_boundary.hpp"
#include <chrono>
#include <optional>
#include <string>
#include <vector>
namespace pastafari::http_api {
struct TargetSpec { std::string value; std::string calendar="gregorian"; std::string format="auto"; };
enum class CalculationMode { RequestInstant, Instant, EngineDay };
struct CalculationSpec { CalculationMode mode=CalculationMode::RequestInstant; std::string value; };
struct ResolvedCalculation {
    std::string source;
    std::string instant;
    Integer engineDay;
    std::optional<Integer> jdn;
    std::optional<double> previousBoundaryJd,nextBoundaryJd;
    std::string modelVersion;
};
struct SingleResult {
    ResolvedCalculation calculation;
    ResolvedDate target;
    std::string language=std::string(DEFAULT_NAME_LANGUAGE);
    CanonicalPastafariDate date;
};
std::int64_t parseRfc3339Milliseconds(std::string_view value);
std::string formatRfc3339Milliseconds(std::int64_t millis);
class CalendarService {
    EnginePort& engine_;
public:
    explicit CalendarService(EnginePort&e):engine_(e){}
    ResolvedCalculation resolveCalculation(const CalculationSpec&,std::int64_t sampledRequestMillis) const;
    SingleResult calculate(const TargetSpec&,const CalculationSpec&,std::int64_t sampledRequestMillis,
                           std::string_view language=DEFAULT_NAME_LANGUAGE);
    std::vector<SingleResult> calculateBatch(const std::vector<TargetSpec>&,const CalculationSpec&,std::int64_t sampledRequestMillis,
                                            std::string_view language=DEFAULT_NAME_LANGUAGE);
};
} // namespace pastafari::http_api
