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

static std::string listText(const std::vector<int>& values) {
    std::string out = "[";
    for (std::size_t i = 0; i < values.size(); ++i) {
        if (i != 0) out += ",";
        out += std::to_string(values[i]);
    }
    return out + "]";
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

        int discrepancies = 0;
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
            const Integer normativeSpace = pastafari::reference::fallingFactorial(
                17,
                cutletCount);
            const auto normativeStream = pastafari::reference::askBowl(
                structureSauce,
                5,
                pastafari::reference::SEAL_CUTLET_NAMES);
            const Integer normativeRank = pastafari::reference::chooseRank(
                normativeStream,
                normativeSpace);
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

            require(report.ready,
                    "report DISCOVERY 22 paratus esse debet");
            require(report.handler == "Discovery22RepeatedCutletNameHandler",
                    "handler DISCOVERY 22 expectatus est");
            require(report.patch20Prepared && report.patch21Prepared,
                    "DISCOVERY 22 PATCH 20 et PATCH 21 antecedentes vere exercere debet");
            require(report.masterNameCount == 17,
                    "catalogus XVII nominum segmentorum servandus est");
            require(report.cutletCount == cutletCount,
                    "numerus nominum legacy a numero segmentorum differt");
            require(report.selectionSpaceCount == normativeSpace,
                    "spatium selectionis nominum a falling factorial normativo differt");
            require(report.selectionRank == normativeRank,
                    "rank selectionis legacy a rank normativo eiusdem annuli differt");
            require(report.legacyNameIndices.size() ==
                        static_cast<std::size_t>(cutletCount),
                    "generator legacy numerum nominum falsum reddidit");
            require(report.legacyContainsRepeat,
                    "witness DISCOVERY 22 repetitionem canonicalIndex detegere debet");
            require(hasRepeat(report.legacyNameIndices),
                    "ordo legacy witness duplicationem re vera continere debet");

            if (report.legacyNameIndices != normativeNames) {
                ++discrepancies;
                std::cout << "DISCREPANTIA_NOMINUM_REPETITORUM"
                          << " calculationGateIndex=" << calculationGateIndex
                          << " calculationDay=" << calculationDay
                          << " cutletCount=" << cutletCount
                          << " rank=" << report.selectionRank
                          << " legacy=" << listText(report.legacyNameIndices)
                          << " normativus=" << listText(normativeNames)
                          << "\n";
            }
        }

        if (discrepancies == 0) {
            std::cout << "REGRESSIO_DISCOVERY_22_TRANSIIT\n";
            return 0;
        }
        if (discrepancies == 3) {
            std::cerr << "REGRESSIO_DISCOVERY_22_DEFECIT: 3 ordines legacy canonicalIndex repetitos loco partialium permutationum distinctarum reddiderunt\n";
            return 1;
        }
        std::cerr << "REGRESSIO_DISCOVERY_22_INEXPECTATA: discrepantiae="
                  << discrepancies << "\n";
        return 2;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_22_ERROR: " << error.what() << "\n";
        return 3;
    }
}
