#pragma once

#include <boost/multiprecision/cpp_int.hpp>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

namespace pastafari {

using Integer = boost::multiprecision::cpp_int;

struct BaseMonsterContext {
    Integer calculationDay;
    Integer targetDay;
    std::string phase;
    std::string status;
    std::vector<std::string> branchTrace;
    std::vector<std::string> logs;
    std::map<std::string, Integer> metrics;
};

struct BaseRunReport {
    std::string phase;
    std::string status;
    std::size_t branchCount;
};

class BaseValidationError final : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

class BaseValidationManager {
public:
    void requireNeutralBootstrapState(const BaseMonsterContext& ctx) const;
};

class BaseMetricsShell {
public:
    void bump(BaseMonsterContext& ctx, const std::string& key) const;
};

class BaseDispatcher {
public:
    void dispatch(BaseMonsterContext& ctx,
                  const BaseValidationManager& validator,
                  const BaseMetricsShell& metrics) const;
};

class BaseMonsterManager {
public:
    BaseRunReport execute(const Integer& calculationDay, const Integer& targetDay) const;
};

} // namespace pastafari
