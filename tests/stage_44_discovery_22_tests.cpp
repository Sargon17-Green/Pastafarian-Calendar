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
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool hasRepeat(const std::vector<int>& values) {
    for (std::size_t i = 0; i < values.size(); ++i) {
        for (std::size_t j = i + 1; j < values.size(); ++j) {
            if (values[i] == values[j]) return true;
        }
    }
    return false;
}

static std::vector<int> masterCutletIndices() {
    std::vector<int> out;
    out.reserve(17);
    for (int canonicalIndex = 1; canonicalIndex <= 17; ++canonicalIndex) {
        out.push_back(canonicalIndex);
    }
    return out;
}

int main() {
    try {
        const std::vector<int> master = masterCutletIndices();
        require(pastafari::legacyNameRowWithRepeats(master, Integer{1}, 4) ==
                    std::vector<int>({1,1,1,1}),
                "generator legacy gradum primum quattuor repetitiones producere debet");
        require(pastafari::legacyNameRowWithRepeats(master, Integer{18}, 3) ==
                    std::vector<int>({1,2,1}),
                "generator legacy rank-1 per digitos basis XVII a parte minima legere debet");
        require(pastafari::legacyNameRowContainsRepeat(
                    pastafari::legacyNameRowWithRepeats(master, Integer{18}, 3)),
                "diagnosticum repetitionis generatoris legacy falsum est");

        NormativeOracle oracle;
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();

        const std::array<Integer, 3> calculationGateIndices{
            Integer{0}, Integer{1}, Integer{2}
        };

        int rawDiscrepancies = 0;
        for (const Integer& calculationGateIndex : calculationGateIndices) {
            const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
            require(year5000.openGateIndex < calculationGateIndex &&
                    calculationGateIndex < year5000.closeGateIndex,
                    "witness DISCOVERY 22 portam calculationis intra annum 5000 requirit");

            const Integer yearFirstDay = year5000.openGateDay + 1;
            const SauceResult structureSauce = pastafari::reference::sauce(
                calculationDay,
                yearFirstDay);
            const int cutletCount = oracle.chooseCutletCount(structureSauce, year5000);
            const std::vector<int> normativeNames = oracle.chooseCutletNameIndices(
                structureSauce,
                cutletCount);
            const LegacyYearAnchor anchor{
                year5000.number,
                yearFirstDay,
                year5000.closeGateDay
            };

            const auto report = manager.executeDiscovery22RepeatedCutletNames(
                anchor,
                yearFirstDay,
                calculationDay,
                calculationGateIndex,
                cutletCount);
            require(report.ready && report.patch22Applied,
                    "PATCH 22 regressionem DISCOVERY 22 corrigere debet");
            require(report.handler == "Patch22RepeatedCutletNameHandler",
                    "handler PATCH 22 viae activae expectatus est");
            require(report.patch22LegacyExecuted,
                    "generator legacy ante PATCH 22 vere exsequi debet");
            require(report.legacyContainsRepeat && hasRepeat(report.legacyNameIndices),
                    "cicatrix DISCOVERY 22 repetitionem servare debet");
            require(report.patch22CorrectComputed,
                    "partial-permutation correct PATCH 22 computari debet");
            require(report.patch22CorrectNameIndices == normativeNames,
                    "correct PATCH 22 ab oracle normativo differt");
            require(report.semanticNameIndices == normativeNames,
                    "output semanticus PATCH 22 ab oracle normativo differt");
            require(!hasRepeat(report.semanticNameIndices),
                    "output semanticus PATCH 22 repetitionem continere non debet");

            const auto diagnostic = manager.executeUnpatchedDiscovery22RepeatedCutletNamesDiagnostic(
                anchor,
                yearFirstDay,
                calculationDay,
                calculationGateIndex,
                cutletCount);
            require(diagnostic.ready,
                    "diagnosticum DISCOVERY 22 paratum esse debet");
            require(diagnostic.handler == "Discovery22RepeatedCutletNameHandler",
                    "diagnosticum handler historicum servare debet");
            require(!diagnostic.patch22Applied,
                    "diagnosticum DISCOVERY 22 PATCH 22 applicare non debet");
            require(diagnostic.legacyNameIndices == report.legacyNameIndices,
                    "candidatus bad inter viam activam et diagnosticum mutatus est");
            require(diagnostic.legacyContainsRepeat,
                    "diagnosticum repetitionem historicam servare debet");

            if (report.legacyNameIndices != normativeNames) {
                ++rawDiscrepancies;
            }
        }

        require(rawDiscrepancies == 3,
                "tres discrepantiae raw DISCOVERY 22 post PATCH 22 servandae sunt");
        std::cout << "REGRESSIO_DISCOVERY_22_POST_PATCH_TRANSIIT\n";
        std::cout << "RAW_DISCOVERY_22_DISCREPANCIES=3\n";
        std::cout << "SEMANTIC_DISCOVERY_22_DISCREPANCIES=0\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_22_POST_PATCH_ERROR: " << error.what() << "\n";
        return 1;
    }
}
