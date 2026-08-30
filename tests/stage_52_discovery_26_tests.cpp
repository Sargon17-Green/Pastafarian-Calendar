#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool sameYear(const pastafari::Patch18YearRecord& actual,
                     const Year& expected) {
    return actual.number == expected.number &&
           actual.openGateIndex == expected.openGateIndex &&
           actual.closeGateIndex == expected.closeGateIndex &&
           actual.openGateDay == expected.openGateDay &&
           actual.closeGateDay == expected.closeGateDay;
}

int main() {
    try {
        NormativeOracle oracle;
        BaseMonsterManager manager;

        const std::array<Integer,3> calculationGateIndices{
            Integer{0}, Integer{7}, Integer{-11}
        };

        int discrepancies = 0;
        for (const Integer& calculationGateIndex : calculationGateIndices) {
            const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
            const LegacyYearAnchor anchor{
                year5000.number,
                year5000.openGateDay + 1,
                year5000.closeGateDay
            };

            const Integer targetDay = year5000.openGateDay;
            const Year normative = oracle.findTargetYear(calculationDay, targetDay);
            const auto report = manager.executeDiscovery26OpeningGateYearMembership(
                anchor,
                targetDay,
                calculationDay);

            require(report.ready,
                    "DISCOVERY 26 report paratus esse debet");
            require(report.handler == "Discovery26OpeningGateYearMembershipHandler",
                    "DISCOVERY 26 handler legacy membership expectatus est");
            require(report.status == "EXPECTED_RED",
                    "DISCOVERY 26 intentionaliter rubrum esse debet");
            require(report.legacyUsedAsSemanticOutput,
                    "DISCOVERY 26 annum legacy ad output semanticum mittere debet");
            require(report.legacyClosedIntervalAccepted,
                    "DISCOVERY 26 intervalum legacy [open,close] accipere debet");
            require(report.targetAtOpeningGate,
                    "witness DISCOVERY 26 target ipsum opening gate esse debet");
            require(report.outputYear.openGateDay <= targetDay &&
                        targetDay <= report.outputYear.closeGateDay,
                    "output legacy intra intervalum clausum [open,close] esse debet");
            require(report.outputYear.number == year5000.number,
                    "legacy strict-backward search opening gate anno novo attribuere debet");
            require(report.outputYear.openGateDay == targetDay,
                    "legacy witness opening gate ipsum ut initium anni output servare debet");

            require(normative.number == year5000.number - 1,
                    "oracle opening gate anno priori attribuere debet");
            require(normative.closeGateDay == targetDay,
                    "oracle opening gate ut closing gate anni prioris servare debet");
            require(normative.openGateDay < targetDay &&
                        targetDay <= normative.closeGateDay,
                    "oracle intervalum (open,close] servare debet");

            if (!sameYear(report.outputYear, normative)) {
                ++discrepancies;
                std::cout
                    << "DISCOVERY26_DISCREPANTIA_OPENING_GATE"
                    << " CALCULATION_GATE=" << calculationGateIndex
                    << " CALCULATION_DAY=" << calculationDay
                    << " TARGET_DAY=" << targetDay
                    << " LEGACY_YEAR=" << report.outputYear.number
                    << " LEGACY_OPEN=" << report.outputYear.openGateDay
                    << " LEGACY_CLOSE=" << report.outputYear.closeGateDay
                    << " NORMATIVE_YEAR=" << normative.number
                    << " NORMATIVE_OPEN=" << normative.openGateDay
                    << " NORMATIVE_CLOSE=" << normative.closeGateDay
                    << "\n";
            }

            const Integer interiorTarget = year5000.openGateDay + 1;
            const Year interiorNormative = oracle.findTargetYear(
                calculationDay,
                interiorTarget);
            const auto interior = manager.executeDiscovery26OpeningGateYearMembership(
                anchor,
                interiorTarget,
                calculationDay);
            require(sameYear(interior.outputYear, interiorNormative),
                    "DISCOVERY 26 extra opening gate annum normativum servare debet");
            require(!interior.targetAtOpeningGate,
                    "control interior target opening gate falso notare non debet");
        }

        require(discrepancies == 3,
                "DISCOVERY 26 tres discrepantias exactas opening-gate requirit");
        std::cerr
            << "REGRESSIO_DISCOVERY_26_DEFECIT: legacy intervalum [open,close] "
               "opening gate anno novo attribuit, sed norma (open,close] annum priorem requirit\n";
        return 1;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_26_ERROR: " << error.what() << "\n";
        return 2;
    }
}
