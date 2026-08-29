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
using pastafari::oldContiguousMonthDayGuess;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static int occurrenceCountThroughTarget(const std::vector<int>& weaving,
                                        std::size_t targetPosition1) {
    if (targetPosition1 < 1 || targetPosition1 > weaving.size()) {
        throw std::runtime_error("positio target test-only extra fines est");
    }
    const int targetMonthId = weaving[targetPosition1 - 1];
    int count = 0;
    for (std::size_t i = 0; i < targetPosition1; ++i) {
        if (weaving[i] == targetMonthId) ++count;
    }
    return count;
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
        require(oldContiguousMonthDayGuess({1,1,2,2,3,3}, 2) == 2,
                "helper legacy in casu contiguo diem secundum reddere debet");
        require(oldContiguousMonthDayGuess({1,2,1}, 3) == 3,
                "helper legacy in casu intertexto distantiam a prima apparitione pro die mensis sumere debet");

        NormativeOracle oracle;
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();

        const std::vector<int> lengths{4,4,4};
        struct Witness {
            Integer calculationGateIndex;
            std::size_t targetPosition1;
        };
        const std::array<Witness,3> witnesses{{
            {Integer{0}, 4},
            {Integer{7}, 5},
            {Integer{-11}, 4}
        }};

        int discrepancies = 0;
        for (const Witness& witness : witnesses) {
            const Integer calculationDay = oracle.gateValueForTest(
                witness.calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
            const Integer yearFirstDay = year5000.openGateDay + 1;
            const Integer targetDay = yearFirstDay +
                Integer{static_cast<unsigned long long>(witness.targetPosition1 - 1)};
            const LegacyYearAnchor anchor{
                year5000.number,
                yearFirstDay,
                year5000.closeGateDay
            };

            const auto report = manager.executeDiscovery25ContiguousMonthDay(
                anchor,
                targetDay,
                calculationDay,
                lengths,
                witness.targetPosition1);
            require(report.ready,
                    "DISCOVERY 25 report paratus esse debet");
            require(report.handler == "Discovery25ContiguousMonthDayHandler",
                    "handler DISCOVERY 25 activus esse debet");
            require(report.status == "EXPECTED_RED",
                    "DISCOVERY 25 status intentionaliter ruber esse debet");
            require(report.patch24Prepared,
                    "DISCOVERY 25 texturam semanticam PATCH 24 paratam requirit");
            require(report.legacyExecuted,
                    "oldContiguousMonthDayGuess vere exsequi debet");
            require(report.legacyUsedAsSemanticOutput,
                    "guess legacy statum semanticum huius discovery gubernare debet");
            require(report.semanticDayInMonth == report.legacyGuessedDayInMonth,
                    "DISCOVERY 25 correctionem occurrence-count nondum adhibere debet");

            const SauceResult structureSauce = pastafari::reference::sauce(
                calculationDay,
                yearFirstDay);
            const std::vector<int> normativeWeaving = oracle.chooseMonthWeaving(
                structureSauce,
                lengths);
            require(report.semanticWeaving == normativeWeaving,
                    "DISCOVERY 25 texturam iam correctam PATCH 24 mutare non debet");
            require(report.targetMonthId ==
                        report.semanticWeaving[witness.targetPosition1 - 1],
                    "monthId target DISCOVERY 25 a textura discrepat");
            require(oldContiguousMonthDayGuess(
                        report.semanticWeaving,
                        witness.targetPosition1) == report.legacyGuessedDayInMonth,
                    "report DISCOVERY 25 helper legacy directe reproducere debet");

            const int expectedOccurrenceCount = occurrenceCountThroughTarget(
                report.semanticWeaving,
                witness.targetPosition1);
            if (report.semanticDayInMonth != expectedOccurrenceCount) {
                ++discrepancies;
                std::cout
                    << "DISCOVERY25_CICATRIX_DISCREPANTIA"
                    << " GATE=" << witness.calculationGateIndex
                    << " CALCULATION_DAY=" << calculationDay
                    << " TARGET_POSITION=" << witness.targetPosition1
                    << " TARGET_MONTH_ID=" << report.targetMonthId
                    << " FIRST_POSITION=" << report.firstOccurrencePosition1
                    << " LEGACY_GUESS=" << report.legacyGuessedDayInMonth
                    << " OCCURRENCE_COUNT=" << expectedOccurrenceCount
                    << " WEAVING=" << rowText(report.semanticWeaving)
                    << "\n";
            }
        }

        require(discrepancies == 3,
                "DISCOVERY 25 tres discrepantias exactas ex assumptione contigua requirit");
        std::cerr
            << "REGRESSIO_DISCOVERY_25_DEFECIT: tres discrepantiae normativae ex "
               "oldContiguousMonthDayGuess inventae sunt\n";
        return 1;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_25_ERROR: " << error.what() << "\n";
        return 2;
    }
}
