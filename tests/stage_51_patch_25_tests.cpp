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
using pastafari::MonthDayOccurrencePatchWrapper;
using pastafari::countMonthOccurrencesThroughTarget;
using pastafari::oldContiguousMonthDayGuess;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static int bruteOccurrenceCount(const std::vector<int>& weaving,
                                std::size_t targetPosition1) {
    if (targetPosition1 < 1 || targetPosition1 > weaving.size()) {
        throw std::runtime_error("positio target test-only extra fines est");
    }
    const int monthId = weaving[targetPosition1 - 1];
    int count = 0;
    for (std::size_t i = 0; i < targetPosition1; ++i) {
        if (weaving[i] == monthId) ++count;
    }
    return count;
}

int main() {
    try {
        require(countMonthOccurrencesThroughTarget({1,1,2,2,3,3}, 2) == 2,
                "PATCH 25 casum contiguum recte numerare debet");
        require(countMonthOccurrencesThroughTarget({1,2,1}, 3) == 2,
                "PATCH 25 target ipsum in occurrence-count includere debet");
        require(countMonthOccurrencesThroughTarget({1,2,3,2,1,2}, 6) == 3,
                "PATCH 25 occurrence-count intertextum exactum esse debet");

        const MonthDayOccurrencePatchWrapper wrapper;
        const std::vector<int> equalWeaving{1,1,2,2};
        const int equalLegacy = oldContiguousMonthDayGuess(equalWeaving, 2);
        const auto equalDecision = wrapper.repair(equalWeaving, 2, equalLegacy);
        require(equalDecision.legacyEqualsCorrect,
                "PATCH 25 ramum ghost==correct probare debet");
        require(equalDecision.legacyReturned &&
                    equalDecision.outputDayInMonth == equalLegacy,
                "PATCH 25 ghost rectum retinere debet");

        const std::vector<int> differentWeaving{1,2,1};
        const int differentLegacy = oldContiguousMonthDayGuess(differentWeaving, 3);
        const auto differentDecision = wrapper.repair(
            differentWeaving,
            3,
            differentLegacy);
        require(!differentDecision.legacyEqualsCorrect &&
                    !differentDecision.legacyReturned,
                "PATCH 25 ramum ghost!=correct probare debet");
        require(differentDecision.correctDayInMonth == 2 &&
                    differentDecision.outputDayInMonth == 2,
                "PATCH 25 occurrence-count correctum loco ghost reddere debet");

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

        int repaired = 0;
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

            const auto raw =
                manager.executeUnpatchedDiscovery25ContiguousMonthDayDiagnostic(
                    anchor,
                    targetDay,
                    calculationDay,
                    lengths,
                    witness.targetPosition1);
            const auto patched = manager.executeDiscovery25ContiguousMonthDay(
                anchor,
                targetDay,
                calculationDay,
                lengths,
                witness.targetPosition1);

            require(raw.ready && raw.handler == "Discovery25ContiguousMonthDayHandler",
                    "PATCH 25 diagnosticum cicatricem DISCOVERY 25 servare debet");
            require(raw.semanticDayInMonth == raw.legacyGuessedDayInMonth,
                    "diagnosticum raw guess legacy ipsum reddere debet");
            require(!raw.patch25Applied,
                    "diagnosticum raw PATCH 25 applicare non debet");
            require(patched.ready && patched.handler == "Patch25ContiguousMonthDayHandler",
                    "PATCH 25 handler activus esse debet");
            require(patched.patch25Applied && patched.patch25LegacyExecuted &&
                        patched.patch25CorrectComputed,
                    "PATCH 25 legacy ante correctionem et correct postea computare debet");
            require(patched.semanticWeaving == raw.semanticWeaving,
                    "PATCH 25 weaving PATCH 24 mutare non debet");
            require(patched.legacyGuessedDayInMonth == raw.legacyGuessedDayInMonth,
                    "PATCH 25 ghost oldContiguousMonthDayGuess byte-semantice servare debet");

            const int expected = bruteOccurrenceCount(
                patched.semanticWeaving,
                witness.targetPosition1);
            require(countMonthOccurrencesThroughTarget(
                        patched.semanticWeaving,
                        witness.targetPosition1) == expected,
                    "PATCH 25 helper productionis cum brute C++ congruere debet");
            require(patched.patch25CorrectDayInMonth == expected,
                    "PATCH 25 correct occurrence-count in report servare debet");
            require(patched.semanticDayInMonth == expected,
                    "PATCH 25 semantic day-in-month occurrence-count esse debet");
            require(raw.semanticDayInMonth != expected,
                    "tres witness cicatricem DISCOVERY 25 realem servare debent");
            require(!patched.patch25LegacyEqualsCorrect &&
                        !patched.patch25LegacyReturned,
                    "tres witness PATCH 25 correct loco ghost eligere debent");
            ++repaired;
        }

        require(repaired == 3,
                "PATCH 25 tres witness DISCOVERY 25 reparare debet");
        std::cout
            << "REGRESSIO_PATCH_25_TRANSIIT: occurrence-count target inclusum, "
               "ghost==correct, ghost!=correct et tres witness reales probati sunt\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_25_ERROR: " << error.what() << "\n";
        return 1;
    }
}
