#pragma once
#include "engine_day.hpp"
#include <cstddef>
#include <string>

namespace pastafari::http_api {
struct CanonicalPastafariDate {
    Integer year;
    std::size_t cutletIndex{};
    std::string cutletName;
    Integer dayInCutlet;
    std::size_t monthIndex{};
    std::string monthName;
    Integer dayInMonth;
};
class EnginePort {
public:
    virtual ~EnginePort()=default;
    virtual CanonicalPastafariDate calculate(const Integer& calculationDay,const Integer& targetDay)=0;
};
class CeleritasEnginePort final:public EnginePort {
public: CanonicalPastafariDate calculate(const Integer&,const Integer&) override;
};
} // namespace pastafari::http_api
