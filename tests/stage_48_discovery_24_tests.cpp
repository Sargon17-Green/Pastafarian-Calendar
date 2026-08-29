#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::legacyChooseEachDaySeparately;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static std::string rowText(const std::vector<int>& row) {
    std::string out = "[";
    for (std::size_t i = 0; i < row.size(); ++i) {
        if (i != 0) out += ",";
        out += std::to_string(row[i]);
    }
    out += "]";
    return out;
}

int main() {
    try {
        NormativeOracle oracle;
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();

        const std::vector<int> lengths{4, 4, 4};
        const std::array<Integer, 3> calculationGateIndices{
            Integer{0}, Integer{2}, Integer{3}
        };
        int legacyDiscrepancies = 0;

        for (const Integer& calculationGateIndex : calculationGateIndices) {
            const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
            const Integer yearFirstDay = year5000.openGateDay + 1;
            const LegacyYearAnchor anchor{
                year5000.number,
                yearFirstDay,
                year5000.closeGateDay
            };

            const auto report = manager.executeDiscovery24MonthWeaving(
                anchor,
                yearFirstDay,
                calculationDay,
                lengths);
            require(report.ready,
                    "DISCOVERY 24 report paratus esse debet");
            require(report.handler == "Patch24MonthWeavingHandler",
                    "post PATCH 24 handler correctus expectatus est");
            require(report.patch20Prepared && report.patch23Prepared,
                    "DISCOVERY 24 PATCH 20 et PATCH 23 parata requirit");
            require(report.multiplicitiesPreserved,
                    "legacyChooseEachDaySeparately multiplicities servare debet");
            require(report.legacyUsedAsSemanticOutput,
                    "cicatrix DISCOVERY 24 ghost legacy ante patch ad output intermedium pervenire debet");
            require(legacyChooseEachDaySeparately(lengths, report.answerRing) ==
                        report.legacyGhost,
                    "ghost DISCOVERY 24 helper legacy directe reproducere debet");

            const SauceResult structureSauce = pastafari::reference::sauce(
                calculationDay,
                yearFirstDay);
            const auto normativeStream = pastafari::reference::askBowl(
                structureSauce,
                4,
                pastafari::reference::SEAL_MONTH_WEAVING);
            require(report.answerRing.first == normativeStream.first &&
                        report.answerRing.directionStep == normativeStream.directionStep,
                    "annulus DISCOVERY 24 a cratere 4 sigillo 32 discrepat");

            const std::vector<int> expected = oracle.chooseMonthWeaving(
                structureSauce,
                lengths);
            require(!report.firstOccurrenceOrderPreserved,
                    "witness DISCOVERY 24 ordinem primae apparitionis infringere debet");
            require(!report.lastOccurrenceOrderPreserved,
                    "witness DISCOVERY 24 ordinem ultimae apparitionis infringere debet");
            require(!report.wholeWeavingOrderLegal,
                    "witness DISCOVERY 24 textura integra legalis esse non debet");

            if (report.legacyGhost != expected) {
                ++legacyDiscrepancies;
                std::cout
                    << "DISCOVERY24_CICATRIX_DISCREPANTIA GATE=" << calculationGateIndex
                    << " CALCULATION_DAY=" << calculationDay
                    << " RING_FIRST=" << report.answerRing.first
                    << " STEP=" << report.answerRing.directionStep
                    << " LEGACY=" << rowText(report.legacyGhost)
                    << " NORMATIVUS=" << rowText(expected)
                    << "\n";
            }
            require(report.patch24Applied && report.patch24LegacyExecuted &&
                        report.patch24CorrectComputed,
                    "PATCH 24 ghost et correct realiter computare debet");
            require(report.patch24CorrectWeaving == expected,
                    "PATCH 24 correct cum oracle texturae integrae congruere debet");
            require(report.semanticWeaving == expected,
                    "regressio DISCOVERY 24 post PATCH 24 viridis esse debet");
            require(report.patch24SemanticWholeWeavingOrderLegal,
                    "output semanticus PATCH 24 textura integra legalis esse debet");
        }

        require(legacyDiscrepancies == 3,
                "DISCOVERY 24 tres discrepantias historicas exactas servare debet");
        std::cout
            << "REGRESSIO_DISCOVERY_24_TRANSIIT: tres cicatrices day-by-day servantur, "
               "sed PATCH 24 output semanticum ad texturam integram legalem dirigit\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_24_ERROR: " << error.what() << "\n";
        return 2;
    }
}
