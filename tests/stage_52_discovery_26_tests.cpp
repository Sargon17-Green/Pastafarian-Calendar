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

        int legacyDiscrepancies = 0;
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
            const auto diagnostic =
                manager.executeUnpatchedDiscovery26OpeningGateYearMembershipDiagnostic(
                    anchor,
                    targetDay,
                    calculationDay);
            const auto report = manager.executeDiscovery26OpeningGateYearMembership(
                anchor,
                targetDay,
                calculationDay);

            require(diagnostic.ready,
                    "diagnosticum DISCOVERY 26 paratum esse debet");
            require(diagnostic.handler == "Discovery26OpeningGateYearMembershipHandler",
                    "diagnosticum DISCOVERY 26 handler legacy servare debet");
            require(diagnostic.status == "EXPECTED_RED",
                    "diagnosticum DISCOVERY 26 intentionaliter rubrum manere debet");
            require(diagnostic.legacyUsedAsSemanticOutput,
                    "diagnosticum DISCOVERY 26 annum legacy ad output mittere debet");
            require(diagnostic.legacyClosedIntervalAccepted,
                    "diagnosticum DISCOVERY 26 intervalum [open,close] accipere debet");
            require(diagnostic.targetAtOpeningGate,
                    "witness diagnosticus target ipsum opening gate esse debet");
            require(diagnostic.outputYear.number == year5000.number,
                    "legacy strict-backward search opening gate anno novo attribuere debet");
            require(diagnostic.outputYear.openGateDay == targetDay,
                    "legacy witness opening gate ut initium anni novi servare debet");

            require(normative.number == year5000.number - 1,
                    "oracle opening gate anno priori attribuere debet");
            require(normative.closeGateDay == targetDay,
                    "oracle opening gate ut closing gate anni prioris servare debet");
            require(normative.openGateDay < targetDay &&
                        targetDay <= normative.closeGateDay,
                    "oracle intervalum (open,close] servare debet");

            if (!sameYear(diagnostic.outputYear, normative)) {
                ++legacyDiscrepancies;
                std::cout
                    << "DISCOVERY26_CICATRIX_DISCREPANTIA_OPENING_GATE"
                    << " CALCULATION_GATE=" << calculationGateIndex
                    << " CALCULATION_DAY=" << calculationDay
                    << " TARGET_DAY=" << targetDay
                    << " LEGACY_YEAR=" << diagnostic.outputYear.number
                    << " LEGACY_OPEN=" << diagnostic.outputYear.openGateDay
                    << " LEGACY_CLOSE=" << diagnostic.outputYear.closeGateDay
                    << " NORMATIVE_YEAR=" << normative.number
                    << " NORMATIVE_OPEN=" << normative.openGateDay
                    << " NORMATIVE_CLOSE=" << normative.closeGateDay
                    << "\n";
            }

            require(report.ready && report.patch26Applied,
                    "regressio DISCOVERY 26 post PATCH 26 viridis esse debet");
            require(report.handler == "Patch26OpeningGateYearMembershipHandler",
                    "post PATCH 26 handler correctus expectatus est");
            require(report.patch26LegacyExecuted && report.patch26CorrectComputed,
                    "PATCH 26 cicatricem legacy et iter correctum computare debet");
            require(sameYear(report.legacyOutputYearBeforePatch, year5000),
                    "PATCH 26 annum legacy ante detour servare debet");
            require(sameYear(report.correctOutputYear, normative),
                    "PATCH 26 annum correctum normativum servare debet");
            require(sameYear(report.outputYear, normative),
                    "PATCH 26 output semanticum normativum reddere debet");
            require(report.patch26AuthoritativeIntervalAccepted,
                    "PATCH 26 intervalum (open,close] acceptare debet");
            require(!report.patch26LegacyEqualsCorrect &&
                        !report.patch26LegacyReturned,
                    "opening-gate witness correctum loco ghost eligere debet");

            const Integer interiorTarget = year5000.openGateDay + 1;
            const Year interiorNormative = oracle.findTargetYear(
                calculationDay,
                interiorTarget);
            const auto interiorDiagnostic =
                manager.executeUnpatchedDiscovery26OpeningGateYearMembershipDiagnostic(
                    anchor,
                    interiorTarget,
                    calculationDay);
            const auto interior = manager.executeDiscovery26OpeningGateYearMembership(
                anchor,
                interiorTarget,
                calculationDay);
            require(sameYear(interiorDiagnostic.outputYear, interiorNormative),
                    "DISCOVERY 26 extra opening gate legacy annum normativum servare debet");
            require(sameYear(interior.outputYear, interiorNormative),
                    "PATCH 26 extra opening gate annum normativum servare debet");
            require(interior.patch26LegacyEqualsCorrect &&
                        interior.patch26LegacyReturned,
                    "PATCH 26 casu interiori ghost iam rectum retinere debet");
        }

        require(legacyDiscrepancies == 3,
                "DISCOVERY 26 tres discrepantias historicas exactas opening-gate servare debet");
        std::cout
            << "REGRESSIO_DISCOVERY_26_TRANSIIT: tres cicatrices [open,close] servantur, "
               "sed PATCH 26 membership (open,close] restituit\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_26_ERROR: " << error.what() << "\n";
        return 2;
    }
}
