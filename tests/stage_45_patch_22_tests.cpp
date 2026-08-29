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
using pastafari::RepeatedNamePatchWrapper;
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

static void enumerateDistinctRowsRec(const std::vector<int>& master,
                                     int itemCount,
                                     std::vector<int>& prefix,
                                     std::vector<bool>& used,
                                     std::vector<std::vector<int>>& out) {
    if (static_cast<int>(prefix.size()) == itemCount) {
        out.push_back(prefix);
        return;
    }
    for (std::size_t i = 0; i < master.size(); ++i) {
        if (used[i]) continue;
        used[i] = true;
        prefix.push_back(master[i]);
        enumerateDistinctRowsRec(master, itemCount, prefix, used, out);
        prefix.pop_back();
        used[i] = false;
    }
}

static std::vector<std::vector<int>> enumerateDistinctRows(const std::vector<int>& master,
                                                            int itemCount) {
    std::vector<std::vector<int>> out;
    std::vector<int> prefix;
    std::vector<bool> used(master.size(), false);
    enumerateDistinctRowsRec(master, itemCount, prefix, used, out);
    return out;
}

static void provePartialPermutationUnrankOnSmallSpaces() {
    for (int masterCount = 1; masterCount <= 6; ++masterCount) {
        std::vector<int> master;
        for (int index = 1; index <= masterCount; ++index) master.push_back(index);
        for (int itemCount = 0; itemCount <= masterCount; ++itemCount) {
            const auto expected = enumerateDistinctRows(master, itemCount);
            const Integer space = pastafari::legacyCutletNameSelectionSpaceCount(
                masterCount,
                itemCount);
            require(space == Integer{expected.size()},
                    "spatium partialis permutationis a force brute differt");
            for (std::size_t rank0 = 0; rank0 < expected.size(); ++rank0) {
                const auto actual = pastafari::partialPermutationNameRowUnrank(
                    master,
                    Integer{rank0 + 1},
                    itemCount);
                require(actual == expected[rank0],
                        "partial-permutation unrank ordinem lexicographicum force brute non servat");
            }
        }
    }
}

static void proveBadEqualsCorrectDetour() {
    const RepeatedNamePatchWrapper wrapper;
    const std::vector<int> master{1,2,3};

    const std::vector<int> equalBad = pastafari::legacyNameRowWithRepeats(
        master,
        Integer{2},
        1);
    const auto equalDecision = wrapper.repair(master, Integer{2}, 1, equalBad);
    require(equalDecision.badEqualsCorrect,
            "casus bad==correct PATCH 22 inveniri debet");
    require(equalDecision.legacyReturned,
            "bad reddi licet tantum in casu bad==correct");
    require(equalDecision.outputNameIndices == equalBad,
            "casus bad==correct ipsum bad reddere debet");

    const std::vector<int> unequalBad = pastafari::legacyNameRowWithRepeats(
        master,
        Integer{1},
        2);
    const auto unequalDecision = wrapper.repair(master, Integer{1}, 2, unequalBad);
    require(!unequalDecision.badEqualsCorrect,
            "casus bad!=correct PATCH 22 inveniri debet");
    require(!unequalDecision.legacyReturned,
            "bad cum bad!=correct reddi non licet");
    require(unequalDecision.correctNameIndices == std::vector<int>({1,2}),
            "correct partial-permutation casus parvi discrepat");
    require(unequalDecision.outputNameIndices == unequalDecision.correctNameIndices,
            "casus bad!=correct correct reddere debet");
}

int main() {
    try {
        provePartialPermutationUnrankOnSmallSpaces();
        proveBadEqualsCorrectDetour();

        NormativeOracle oracle;
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();
        const std::array<Integer, 3> calculationGateIndices{
            Integer{0}, Integer{1}, Integer{2}
        };

        int repairedWitnesses = 0;
        for (const Integer& calculationGateIndex : calculationGateIndices) {
            const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
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
            require(report.ready && report.patch22Applied,
                    "PATCH 22 via activa parata esse debet");
            require(report.handler == "Patch22RepeatedCutletNameHandler",
                    "handler PATCH 22 expectatus est");
            require(report.patch20Prepared && report.patch21Prepared,
                    "PATCH 22 gradus 20 et 21 antecedentes servare debet");
            require(report.patch22LegacyExecuted,
                    "bad legacy ante correct vere computari debet");
            require(report.patch22CorrectComputed,
                    "correct partial-permutation vere computari debet");
            require(report.selectionSpaceCount == normativeSpace,
                    "spatium PATCH 22 a falling factorial normativo differt");
            require(report.selectionRank == normativeRank,
                    "rank PATCH 22 ab answer ring normativo differt");
            require(report.legacyContainsRepeat && hasRepeat(report.legacyNameIndices),
                    "witness PATCH 22 cicatricem repeat raw servare debet");
            require(!report.patch22BadEqualsCorrect,
                    "tres witness defectivi bad!=correct esse debent");
            require(!report.patch22LegacyReturned,
                    "bad defectivus ad output semanticum pervenire non debet");
            require(report.patch22CorrectNameIndices == normativeNames,
                    "partial-permutation correct ab oracle C++ differt");
            require(report.semanticNameIndices == normativeNames,
                    "output semanticus PATCH 22 ab oracle C++ differt");
            require(!hasRepeat(report.semanticNameIndices),
                    "output semanticus PATCH 22 canonicalIndex repetere non debet");

            const auto diagnostic = manager.executeUnpatchedDiscovery22RepeatedCutletNamesDiagnostic(
                anchor,
                yearFirstDay,
                calculationDay,
                calculationGateIndex,
                cutletCount);
            require(diagnostic.ready && !diagnostic.patch22Applied,
                    "diagnosticum DISCOVERY 22 sine PATCH 22 manere debet");
            require(diagnostic.handler == "Discovery22RepeatedCutletNameHandler",
                    "diagnosticum handler legacy servare debet");
            require(diagnostic.legacyNameIndices == report.legacyNameIndices,
                    "bad legacy inter diagnosticum et patch mutari non debet");
            require(diagnostic.legacyContainsRepeat,
                    "diagnosticum repetitionem historicam servare debet");
            ++repairedWitnesses;
        }

        require(repairedWitnesses == 3,
                "tres witness PATCH 22 reparari debent");

        std::cout << "REGRESSIO_PATCH_22_TRANSIIT\n";
        std::cout << "FORCE_BRUTE_PARTIAL_PERMUTATION_SMALL_SPACES=PASS\n";
        std::cout << "BAD_EQUALS_CORRECT_DETOUR=PASS\n";
        std::cout << "LEGACY_BAD_EXECUTED=YES\n";
        std::cout << "CORRECT_PARTIAL_PERMUTATION_COMPUTED=YES\n";
        std::cout << "REPAIRED_WITNESSES=3\n";
        std::cout << "DISCOVERY_22_DIAGNOSTIC_PRESERVED=YES\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_22_ERROR: " << error.what() << "\n";
        return 1;
    }
}
