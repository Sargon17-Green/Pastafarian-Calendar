#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyAnswerRing;
using pastafari::LegacyBiasedSelectionAdapter;
using pastafari::LegacyYearAnchor;
using pastafari::M_OLD;
using pastafari::MonthWeavingPatchWrapper;
using pastafari::Patch13RejectionWrapper;
using pastafari::Patch14WideDetourWrapper;
using pastafari::compatibleMonthWeavingRank;
using pastafari::DPUnrankLegalWeaving;
using pastafari::exactLegalMonthWeavingCount;
using pastafari::legacyChooseEachDaySeparately;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

struct BruteState {
    std::vector<int> remaining{};
    int openedUpTo = 0;
    int closedUpTo = 0;
};

static bool bruteLegalMove(const std::vector<int>& lengths,
                           const BruteState& state,
                           int monthId) {
    const std::size_t index = static_cast<std::size_t>(monthId - 1);
    if (state.remaining[index] == 0) return false;
    const bool alreadyOpened = state.remaining[index] < lengths[index];
    if (!alreadyOpened && monthId != state.openedUpTo + 1) return false;
    const bool willClose = state.remaining[index] == 1;
    if (willClose && monthId != state.closedUpTo + 1) return false;
    return true;
}

static BruteState bruteApply(const std::vector<int>& lengths,
                             const BruteState& state,
                             int monthId) {
    BruteState next = state;
    const std::size_t index = static_cast<std::size_t>(monthId - 1);
    if (next.remaining[index] == lengths[index]) next.openedUpTo = monthId;
    --next.remaining[index];
    if (next.remaining[index] == 0) next.closedUpTo = monthId;
    return next;
}

static void bruteEnumerate(const std::vector<int>& lengths,
                           const BruteState& state,
                           std::vector<int>& prefix,
                           std::vector<std::vector<int>>& out) {
    bool empty = true;
    for (const int remaining : state.remaining) {
        if (remaining != 0) {
            empty = false;
            break;
        }
    }
    if (empty) {
        out.push_back(prefix);
        return;
    }
    for (int monthId = 1;
         monthId <= static_cast<int>(lengths.size());
         ++monthId) {
        if (!bruteLegalMove(lengths, state, monthId)) continue;
        prefix.push_back(monthId);
        bruteEnumerate(
            lengths,
            bruteApply(lengths, state, monthId),
            prefix,
            out);
        prefix.pop_back();
    }
}

static std::vector<std::vector<int>> bruteFamily(const std::vector<int>& lengths) {
    std::vector<std::vector<int>> out;
    std::vector<int> prefix;
    bruteEnumerate(lengths, BruteState{lengths, 0, 0}, prefix, out);
    return out;
}

int main() {
    try {
        const std::array<std::vector<int>, 7> smallFamilies{
            std::vector<int>{1, 1, 1},
            std::vector<int>{2, 1, 1},
            std::vector<int>{2, 2, 1},
            std::vector<int>{2, 2, 2},
            std::vector<int>{3, 2, 1},
            std::vector<int>{3, 2, 2},
            std::vector<int>{3, 3, 2}
        };
        std::size_t smallItemsChecked = 0;
        for (const auto& lengths : smallFamilies) {
            const auto brute = bruteFamily(lengths);
            require(exactLegalMonthWeavingCount(lengths) == Integer{brute.size()},
                    "PATCH 24 DP count cum enumeratione C++ parva congruere debet");
            for (std::size_t i = 0; i < brute.size(); ++i) {
                const Integer rank = Integer{i + 1};
                require(DPUnrankLegalWeaving(lengths, rank) == brute[i],
                        "PATCH 24 DP unrank ordinem lexicographicum exactum servare debet");
                ++smallItemsChecked;
            }
        }

        const LegacyAnswerRing shortRing{Integer{123456789}, -1};
        const Integer shortN{37};
        const LegacyBiasedSelectionAdapter selectionAdapter;
        const Patch13RejectionWrapper rejectionWrapper;
        require(compatibleMonthWeavingRank(shortRing, shortN) ==
                    rejectionWrapper.repair(shortRing, shortN, selectionAdapter).outputRank,
                "PATCH 24 rank brevis semanticas PATCH 13 servare debet");

        const LegacyAnswerRing wideRing{M_OLD, 1};
        const Integer wideN = M_OLD + 17;
        const Patch14WideDetourWrapper wideWrapper;
        require(compatibleMonthWeavingRank(wideRing, wideN) ==
                    wideWrapper.repair(wideRing, wideN, selectionAdapter).outputRank,
                "PATCH 24 rank latus semanticas PATCH 14 servare debet");

        const std::vector<int> identityLengths{1, 1, 1};
        const LegacyAnswerRing identityRing{Integer{1}, 1};
        const std::vector<int> identityGhost = legacyChooseEachDaySeparately(
            identityLengths,
            identityRing);
        const MonthWeavingPatchWrapper patchWrapper;
        const auto identityDecision = patchWrapper.repair(
            identityLengths,
            identityRing,
            identityGhost);
        require(identityDecision.ghostEqualsCorrect,
                "PATCH 24 ramum ghost==correct probare debet");
        require(identityDecision.legacyReturned &&
                    identityDecision.outputWeaving == identityGhost,
                "PATCH 24 ghost rectum sine substitutione servare debet");

        NormativeOracle oracle;
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();
        const std::vector<int> lengths{4, 4, 4};
        const std::array<Integer, 3> calculationGateIndices{
            Integer{0}, Integer{2}, Integer{3}
        };
        int repairedWitnesses = 0;

        for (const Integer& calculationGateIndex : calculationGateIndices) {
            const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
            const Integer yearFirstDay = year5000.openGateDay + 1;
            const LegacyYearAnchor anchor{
                year5000.number,
                yearFirstDay,
                year5000.closeGateDay
            };

            const auto raw = manager.executeUnpatchedDiscovery24MonthWeavingDiagnostic(
                anchor,
                yearFirstDay,
                calculationDay,
                lengths);
            const auto patched = manager.executeDiscovery24MonthWeaving(
                anchor,
                yearFirstDay,
                calculationDay,
                lengths);
            require(raw.ready && raw.handler == "Discovery24MonthWeavingHandler",
                    "diagnosticum DISCOVERY 24 cicatricem raw servare debet");
            require(raw.semanticWeaving == raw.legacyGhost,
                    "diagnosticum raw ghost ipsum adhuc reddere debet");
            require(patched.ready && patched.handler == "Patch24MonthWeavingHandler",
                    "PATCH 24 handler activus esse debet");
            require(patched.patch24Applied && patched.patch24LegacyExecuted &&
                        patched.patch24CorrectComputed,
                    "PATCH 24 ghost ante correct realiter exsequi debet");
            require(patched.legacyGhost == raw.legacyGhost,
                    "PATCH 24 cicatricem day-by-day non mutare debet");
            require(patched.answerRing.first == raw.answerRing.first &&
                        patched.answerRing.directionStep == raw.answerRing.directionStep,
                    "PATCH 24 eundem annulum DISCOVERY 24 servare debet");

            const SauceResult structureSauce = pastafari::reference::sauce(
                calculationDay,
                yearFirstDay);
            const std::vector<int> expected = oracle.chooseMonthWeaving(
                structureSauce,
                lengths);
            require(patched.patch24CorrectWeaving == expected,
                    "PATCH 24 correct cum oracle C++ normativo congruere debet");
            require(patched.semanticWeaving == expected,
                    "PATCH 24 output semanticus cum oracle C++ normativo congruere debet");
            require(!patched.patch24GhostEqualsCorrect && !patched.patch24LegacyReturned,
                    "tres witness PATCH 24 correct loco ghost eligere debent");
            require(patched.patch24SemanticWholeWeavingOrderLegal,
                    "PATCH 24 textura semantica ordines integros servare debet");
            ++repairedWitnesses;
        }

        require(repairedWitnesses == 3,
                "PATCH 24 tres witness DISCOVERY 24 reparare debet");
        std::cout
            << "REGRESSIO_PATCH_24_TRANSIIT: DP count/unrank exactus, rank brevis/latus, "
               "ghost==correct et tres detours ghost!=correct probati sunt; SMALL_ITEMS="
            << smallItemsChecked << "\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_24_ERROR: " << error.what() << "\n";
        return 1;
    }
}
