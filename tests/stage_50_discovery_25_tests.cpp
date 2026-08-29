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
using pastafari::countMonthOccurrencesThroughTarget;
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

        int legacyDiscrepancies = 0;
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

            const auto diagnostic =
                manager.executeUnpatchedDiscovery25ContiguousMonthDayDiagnostic(
                    anchor,
                    targetDay,
                    calculationDay,
                    lengths,
                    witness.targetPosition1);
            const auto report = manager.executeDiscovery25ContiguousMonthDay(
                anchor,
                targetDay,
                calculationDay,
                lengths,
                witness.targetPosition1);
            require(diagnostic.ready,
                    "diagnosticum DISCOVERY 25 paratum esse debet");
            require(diagnostic.handler == "Discovery25ContiguousMonthDayHandler",
                    "diagnosticum handler DISCOVERY 25 cicatricem servare debet");
            require(diagnostic.status == "EXPECTED_RED",
                    "diagnosticum DISCOVERY 25 intentionaliter rubrum manere debet");
            require(!diagnostic.patch25Applied,
                    "diagnosticum DISCOVERY 25 PATCH 25 applicare non debet");
            require(report.ready,
                    "PATCH 25 report paratus esse debet");
            require(report.handler == "Patch25ContiguousMonthDayHandler",
                    "post PATCH 25 handler correctus expectatus est");
            require(report.patch24Prepared,
                    "DISCOVERY 25 texturam semanticam PATCH 24 paratam requirit");
            require(report.legacyExecuted,
                    "oldContiguousMonthDayGuess vere exsequi debet");
            require(report.legacyUsedAsSemanticOutput,
                    "guess legacy statum semanticum intermedium ante PATCH 25 gubernare debet");
            require(report.patch25Applied && report.patch25LegacyExecuted &&
                        report.patch25CorrectComputed,
                    "PATCH 25 ghost legacy et occurrence-count correctum computare debet");
            require(report.semanticWeaving == diagnostic.semanticWeaving,
                    "PATCH 25 texturam semanticam PATCH 24 mutare non debet");
            require(report.legacyGuessedDayInMonth ==
                        diagnostic.legacyGuessedDayInMonth,
                    "PATCH 25 cicatricem oldContiguousMonthDayGuess servare debet");

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
            require(countMonthOccurrencesThroughTarget(
                        report.semanticWeaving,
                        witness.targetPosition1) == expectedOccurrenceCount,
                    "helper productionis occurrence-count cum test-side reference congruere debet");
            if (diagnostic.semanticDayInMonth != expectedOccurrenceCount) {
                ++legacyDiscrepancies;
                std::cout
                    << "DISCOVERY25_CICATRIX_DISCREPANTIA"
                    << " GATE=" << witness.calculationGateIndex
                    << " CALCULATION_DAY=" << calculationDay
                    << " TARGET_POSITION=" << witness.targetPosition1
                    << " TARGET_MONTH_ID=" << report.targetMonthId
                    << " FIRST_POSITION=" << report.firstOccurrencePosition1
                    << " LEGACY_GUESS=" << diagnostic.legacyGuessedDayInMonth
                    << " OCCURRENCE_COUNT=" << expectedOccurrenceCount
                    << " WEAVING=" << rowText(report.semanticWeaving)
                    << "\n";
            }
            require(report.patch25CorrectDayInMonth == expectedOccurrenceCount,
                    "PATCH 25 correct occurrence-count exactum esse debet");
            require(report.semanticDayInMonth == expectedOccurrenceCount,
                    "regressio DISCOVERY 25 post PATCH 25 viridis esse debet");
            require(!report.patch25LegacyEqualsCorrect && !report.patch25LegacyReturned,
                    "tres witness DISCOVERY 25 detour correctum loco ghost eligere debent");
        }

        require(legacyDiscrepancies == 3,
                "DISCOVERY 25 tres discrepantias historicas exactas servare debet");
        std::cout
            << "REGRESSIO_DISCOVERY_25_TRANSIIT: tres cicatrices contiguous servantur, "
               "sed PATCH 25 diem mensis per occurrence-count corrigit\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_25_ERROR: " << error.what() << "\n";
        return 2;
    }
}
