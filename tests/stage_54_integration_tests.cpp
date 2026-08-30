#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"

#include <algorithm>
#include <array>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <tuple>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::DPUnrankLegalWeaving;
using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using pastafari::Stage54IntegrationReport;
using pastafari::exactLegalMonthWeavingCount;
using pastafari::reference::Big;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;
using pastafari::reference::YearStructure;

namespace {

void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

bool sameYear(const pastafari::Patch18YearRecord& actual, const Year& expected) {
    return actual.number == expected.number &&
           actual.openGateIndex == expected.openGateIndex &&
           actual.closeGateIndex == expected.closeGateIndex &&
           actual.openGateDay == expected.openGateDay &&
           actual.closeGateDay == expected.closeGateDay;
}

struct NaiveWeaveKey {
    std::vector<int> remaining{};
    int opened = 0;
    int closed = 0;
    bool operator<(const NaiveWeaveKey& other) const {
        if (opened != other.opened) return opened < other.opened;
        if (closed != other.closed) return closed < other.closed;
        return remaining < other.remaining;
    }
};

class NaiveWeaveOracle {
public:
    explicit NaiveWeaveOracle(std::vector<int> lengths)
        : lengths_(std::move(lengths)) {}

    Integer countAll() {
        return count(NaiveWeaveKey{lengths_, 0, 0});
    }

    std::vector<int> unrank1(Integer rank) {
        NaiveWeaveKey state{lengths_, 0, 0};
        const Integer total = count(state);
        if (rank < 1 || rank > total) {
            throw std::runtime_error("gradus textus naive extra fines est");
        }
        std::vector<int> out;
        const int totalLength = std::accumulate(lengths_.begin(), lengths_.end(), 0);
        out.reserve(static_cast<std::size_t>(totalLength));
        while (static_cast<int>(out.size()) < totalLength) {
            bool chosen = false;
            for (int monthId = 1; monthId <= static_cast<int>(lengths_.size()); ++monthId) {
                if (!legal(state, monthId)) continue;
                const NaiveWeaveKey next = apply(state, monthId);
                const Integer block = count(next);
                if (rank > block) {
                    rank -= block;
                    continue;
                }
                out.push_back(monthId);
                state = next;
                chosen = true;
                break;
            }
            if (!chosen) throw std::runtime_error("textus naive rank aperire non potuit");
        }
        return out;
    }

private:
    std::vector<int> lengths_{};
    std::map<NaiveWeaveKey, Integer> memo_{};

    bool legal(const NaiveWeaveKey& state, int monthId) const {
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        if (state.remaining[index] == 0) return false;
        const bool openedAlready = state.remaining[index] < lengths_[index];
        if (!openedAlready && monthId != state.opened + 1) return false;
        const bool closesNow = state.remaining[index] == 1;
        return !closesNow || monthId == state.closed + 1;
    }

    NaiveWeaveKey apply(const NaiveWeaveKey& state, int monthId) const {
        NaiveWeaveKey next = state;
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        if (next.remaining[index] == lengths_[index]) next.opened = monthId;
        --next.remaining[index];
        if (next.remaining[index] == 0) next.closed = monthId;
        return next;
    }

    Integer count(const NaiveWeaveKey& state) {
        bool empty = true;
        for (const int remaining : state.remaining) {
            if (remaining != 0) {
                empty = false;
                break;
            }
        }
        if (empty) return Integer{1};
        const auto found = memo_.find(state);
        if (found != memo_.end()) return found->second;
        Integer total = 0;
        for (int monthId = 1; monthId <= static_cast<int>(lengths_.size()); ++monthId) {
            if (legal(state, monthId)) total += count(apply(state, monthId));
        }
        memo_.emplace(state, total);
        return total;
    }
};

void requireFastWeaveEqualsNaive(const std::vector<int>& lengths) {
    NaiveWeaveOracle naive(lengths);
    const Integer expectedCount = naive.countAll();
    const Integer actualCount = exactLegalMonthWeavingCount(lengths);
    require(actualCount == expectedCount,
            "DP celer numerum texturae contra oracle naive medium discrepat");
    const std::array<Integer,3> ranks{
        Integer{1},
        (expectedCount + 1) / 2,
        expectedCount
    };
    for (const Integer& rank : ranks) {
        require(DPUnrankLegalWeaving(lengths, rank) == naive.unrank1(rank),
                "DP celer unrank lexicographicum contra oracle naive medium discrepat");
    }
}

struct ExpectedStructure {
    Year year{};
    int cutletCount = 0;
    std::vector<int> cutletPartition{};
    std::vector<int> cutletNameIndices{};
    std::vector<pastafari::reference::Cutlet> cutlets{};
    int monthCount = 0;
    std::vector<int> monthLengths{};
    std::vector<int> monthWeaving{};
    std::vector<int> monthNameIndices{};
};

struct ExpectedDate {
    SpaghettiDateFive result{};
    ExpectedStructure structure{};
};

ExpectedDate expectedDate(NormativeOracle& oracle,
                          const Integer& calculationDay,
                          const Integer& targetDay) {
    ExpectedDate out;
    out.structure.year = oracle.findTargetYear(calculationDay, targetDay);
    const auto sauce = pastafari::reference::sauce(
        calculationDay,
        out.structure.year.openGateDay + 1);
    out.structure.cutletCount = oracle.chooseCutletCount(
        sauce,
        out.structure.year);
    out.structure.cutletPartition = oracle.chooseCutletPartition(
        calculationDay,
        sauce,
        out.structure.year,
        out.structure.cutletCount);
    out.structure.cutletNameIndices = oracle.chooseCutletNameIndices(
        sauce,
        out.structure.cutletCount);
    out.structure.cutlets = oracle.materializeCutlets(
        out.structure.year,
        out.structure.cutletPartition,
        out.structure.cutletNameIndices);
    out.structure.monthCount = oracle.chooseMonthCount(
        sauce,
        out.structure.year);
    out.structure.monthLengths = oracle.chooseMonthLengths(
        sauce,
        out.structure.year,
        out.structure.monthCount);
    out.structure.monthNameIndices = oracle.chooseMonthNameIndices(
        sauce,
        out.structure.monthCount);

    const Integer weavingCount = exactLegalMonthWeavingCount(
        out.structure.monthLengths);
    const Integer weavingRank = pastafari::reference::chooseRank(
        pastafari::reference::askBowl(sauce, 4, 32),
        weavingCount);
    out.structure.monthWeaving = DPUnrankLegalWeaving(
        out.structure.monthLengths,
        weavingRank);

    int cutletNameIndex = 0;
    Integer dayInCutlet = 0;
    for (const auto& cutlet : out.structure.cutlets) {
        if (cutlet.firstDay <= targetDay && targetDay <= cutlet.lastDay) {
            cutletNameIndex = cutlet.nameIndex;
            dayInCutlet = targetDay - cutlet.firstDay + 1;
            break;
        }
    }
    require(cutletNameIndex != 0,
            "oracle integrationis segmentum target invenire debet");

    const Integer positionInteger = targetDay - out.structure.year.openGateDay;
    require(positionInteger >= 1 &&
                positionInteger <= Integer{out.structure.monthWeaving.size()},
            "oracle integrationis positionem target in textura requirit");
    const std::size_t position1 = positionInteger.convert_to<std::size_t>();
    const int monthId = out.structure.monthWeaving.at(position1 - 1);
    int dayInMonth = 0;
    for (std::size_t i = 0; i < position1; ++i) {
        if (out.structure.monthWeaving[i] == monthId) ++dayInMonth;
    }
    const int monthNameIndex = out.structure.monthNameIndices.at(
        static_cast<std::size_t>(monthId - 1));

    out.result = SpaghettiDateFive{
        out.structure.year.number,
        std::string(pastafari::cutletSourceName(
            static_cast<std::size_t>(cutletNameIndex))),
        dayInCutlet,
        std::string(pastafari::monthSourceName(
            static_cast<std::size_t>(monthNameIndex))),
        Integer{dayInMonth}
    };
    return out;
}

void requireDateEqual(const SpaghettiDateFive& actual,
                      const SpaghettiDateFive& expected,
                      const std::string& label) {
    require(actual.yearNumber == expected.yearNumber, label + ": annus discrepat");
    require(actual.cutletName == expected.cutletName, label + ": nomen segmenti discrepat");
    require(actual.dayInCutlet == expected.dayInCutlet, label + ": dies segmenti discrepat");
    require(actual.monthName == expected.monthName, label + ": nomen mensis discrepat");
    require(actual.dayInMonth == expected.dayInMonth, label + ": dies mensis discrepat");
}

void requireStructureEqual(const Stage54IntegrationReport& actual,
                           const ExpectedStructure& expected,
                           const std::string& label) {
    require(sameYear(actual.targetYear, expected.year), label + ": annus structurae discrepat");
    require(actual.structure.cutletCount == expected.cutletCount,
            label + ": numerus segmentorum discrepat");
    require(actual.structure.cutletPartition == expected.cutletPartition,
            label + ": partitio segmentorum discrepat");
    require(actual.structure.cutletNameIndices == expected.cutletNameIndices,
            label + ": indices nominum segmentorum discrepant");
    require(actual.structure.monthCount == expected.monthCount,
            label + ": numerus mensium discrepat");
    require(actual.structure.monthLengths == expected.monthLengths,
            label + ": longitudines mensium discrepant");
    require(actual.structure.monthWeaving == expected.monthWeaving,
            label + ": textura mensium discrepat");
    require(actual.structure.monthNameIndices == expected.monthNameIndices,
            label + ": indices nominum mensium discrepant");
}

} // namespace

int main() {
    try {
        requireFastWeaveEqualsNaive({15,14,13});
        requireFastWeaveEqualsNaive({9,8,9,8,9});

        const auto sauceScar = pastafari::sauceWithScars(
            pastafari::FOUNDATION_DAY_OLD,
            pastafari::FOUNDATION_DAY_OLD);
        const auto sauceEarlier = pastafari::sauceWithOrderAt46Latch(
            pastafari::FOUNDATION_DAY_OLD,
            pastafari::FOUNDATION_DAY_OLD);
        require(sauceScar.finalBowls == sauceEarlier.finalBowls &&
                    sauceScar.orderAt46Latch == sauceEarlier.orderAt46Latch,
                "sauceWithScars exitum PATCH 11 exactum servare debet");
        require(sauceScar.legacyOrderWriteCount == 58 &&
                    sauceScar.latchWriteCount == 1,
                "sauceWithScars memoriam legacy et latch unicum exercere debet");

        BaseMonsterManager manager;
        NormativeOracle oracle;
        int integrationCases = 0;

        const Integer c0 = pastafari::FOUNDATION_DAY_OLD;
        const Integer t0 = pastafari::FOUNDATION_DAY_OLD;
        const ExpectedDate e0 = expectedDate(oracle, c0, t0);
        const Stage54IntegrationReport a0 = manager.executeFinalIntegration(c0, t0);
        requireDateEqual(a0.result, e0.result, "Foundation");
        requireStructureEqual(a0, e0.structure, "Foundation");
        require(a0.ready && a0.status == "GREEN" &&
                    a0.handler == "FinalIntegrationHandler",
                "integratio Foundation GREEN per handler finalem esse debet");
        require(a0.legacyStructureSauceGhostExecuted &&
                    a0.legacyCutletPartitionExecuted &&
                    a0.legacyCutletNamesExecuted &&
                    a0.legacyMonthLengthListContractExecuted &&
                    a0.legacyMonthWeavingExecuted &&
                    a0.legacyMonthNamesExecuted &&
                    a0.legacyContiguousMonthDayExecuted,
                "prima structura integrationis omnes cicatrices structurales vere exercere debet");
        ++integrationCases;

        const Integer sameYearClose = a0.targetYear.closeGateDay;
        const Stage54IntegrationReport a1 = manager.executeFinalIntegration(c0, sameYearClose);
        require(a1.targetYear.number == a0.targetYear.number &&
                    a1.targetYear.openGateDay == a0.targetYear.openGateDay &&
                    a1.targetYear.closeGateDay == a0.targetYear.closeGateDay,
                "closing gate eiusdem anni structuram eandem servare debet");
        require(a1.structure.monthWeaving == a0.structure.monthWeaving &&
                    a1.structure.cutletPartition == a0.structure.cutletPartition,
                "cache hit structuram anni iam verificatam servare debet");
        require(a1.guardedCacheHit,
                "secunda vocatio eiusdem anni eodem calculationDay cache guardatum ferire debet");
        ++integrationCases;

        const Integer openingGate = a0.targetYear.openGateDay;
        const Stage54IntegrationReport a2 = manager.executeFinalIntegration(c0, openingGate);
        const Year y2 = oracle.findTargetYear(c0, openingGate);
        require(sameYear(a2.targetYear, y2),
                "opening gate annum oracle C++ eundem reddere debet");
        require(a2.targetYear.number == a0.targetYear.number - 1,
                "opening gate PATCH 26 anno priori attribui debet");
        ++integrationCases;

        const Integer nextYearFirstDay = a0.targetYear.closeGateDay + 1;
        const Stage54IntegrationReport a3 = manager.executeFinalIntegration(c0, nextYearFirstDay);
        const Year y3 = oracle.findTargetYear(c0, nextYearFirstDay);
        require(sameYear(a3.targetYear, y3),
                "primus dies anni sequentis cum oracle C++ congruere debet");
        require(a3.targetYear.number == a0.targetYear.number + 1,
                "primus dies post closing gate annum sequentem requirit");
        ++integrationCases;

        const Integer c1 = pastafari::FOUNDATION_DAY_OLD + 1;
        const ExpectedDate e4 = expectedDate(oracle, c1, c1);
        const Stage54IntegrationReport a4 = manager.executeFinalIntegration(c1, c1);
        requireDateEqual(a4.result, e4.result, "calculationDay mutatus");
        requireStructureEqual(a4, e4.structure, "calculationDay mutatus");
        require(a4.guardedCacheRejected,
                "cache year-number-only cum calculationDay alio guard recusari debet");
        ++integrationCases;

        const Stage54IntegrationReport a5 = manager.executeFinalIntegration(c1, c1);
        requireDateEqual(a5.result, e4.result, "calculationDay mutatus cache warm");
        require(a5.guardedCacheHit,
                "cache guardatus post recomputationem eodem calculationDay ferire debet");
        ++integrationCases;

        const SpaghettiDateFive publicResult = pastafari::calendarDateSpaghetti(c0, t0);
        requireDateEqual(publicResult, e0.result, "API calendarDateSpaghetti");
        ++integrationCases;

        require(integrationCases == 7,
                "Gradus 54 septem casus integrationis exercere debet");
        std::cout
            << "INTEGRATIO_GRADUS_54_TRANSIIT: sauceWithScars, septem casus end-to-end, "
               "cache guardatum, fines (open,close], DP celer exactus et quinque campi probati sunt\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "INTEGRATIO_GRADUS_54_ERROR: " << error.what() << "\n";
        return 1;
    }
}
