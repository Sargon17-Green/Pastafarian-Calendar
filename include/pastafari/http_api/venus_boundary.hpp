#pragma once
#include "engine_day.hpp"
#include <chrono>
#include <string>

namespace pastafari::http_api {
struct Observer { double latitude; double longitude; double elevationM; };
inline constexpr Observer KISURRA_OBSERVER{31.8383, 45.4810, 0.0};
inline constexpr const char* VENUS_BOUNDARY_MODEL_VERSION = "venus-lower-transit-jpl-approx-1";

struct VenusBoundary {
    Integer dayJdn;
    double jd{};
    Observer observer{};
    std::string modelVersion;
};
struct CalculationDayResolution {
    Integer jdn;
    Integer engineDay;
    VenusBoundary previousBoundary;
    VenusBoundary nextBoundary;
    Observer observer{};
    std::string modelVersion;
};
class AstronomyError : public std::runtime_error { public: using std::runtime_error::runtime_error; };
VenusBoundary boundaryForDayJdn(const Integer& dayJdn, Observer observer = KISURRA_OBSERVER);
CalculationDayResolution currentDayAt(std::chrono::system_clock::time_point instant,
                                      Observer observer = KISURRA_OBSERVER);
CalculationDayResolution currentDayAtUnixMilliseconds(std::int64_t millis,
                                                       Observer observer = KISURRA_OBSERVER);
} // namespace pastafari::http_api
