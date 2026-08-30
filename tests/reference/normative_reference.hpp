#pragma once

#include <array>
#include <boost/multiprecision/cpp_int.hpp>
#include <cstddef>
#include <map>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

namespace pastafari::reference {

using Big = boost::multiprecision::cpp_int;

inline const Big TABLETS_DAY = Big{-278522};
inline const Big FOUNDATION_DAY = Big{-15055671};
inline const Big M = (Big{1} << 127) - 1;
inline constexpr int GATE_GAP_MIN = 42;
inline constexpr int GATE_GAP_MAX = 963;
inline constexpr int YEAR_MIN_DAYS = 252;
inline constexpr int YEAR_MAX_DAYS = 5778;
inline constexpr int MIN_CUTLETS = 6;
inline constexpr int MAX_CUTLETS = 17;
inline constexpr int MIN_MONTHS = 3;
inline constexpr int MAX_MONTHS = 47;
inline constexpr int MIN_MONTH_DAYS = 4;
inline constexpr int MAX_MONTH_DAYS = 123;

inline constexpr int SEAL_GATE_GAP = 1;
inline constexpr int SEAL_YEAR_5000 = 10;
inline constexpr int SEAL_NEXT_YEAR = 11;
inline constexpr int SEAL_PREVIOUS_YEAR = 12;
inline constexpr int SEAL_CUTLET_COUNT = 20;
inline constexpr int SEAL_CUTLET_PARTITION = 21;
inline constexpr int SEAL_CUTLET_NAMES = 22;
inline constexpr int SEAL_MONTH_COUNT = 30;
inline constexpr int SEAL_MONTH_LENGTHS = 31;
inline constexpr int SEAL_MONTH_WEAVING = 32;
inline constexpr int SEAL_MONTH_NAMES = 33;

Big regularMod(const Big& x, const Big& d);
Big floorDiv(const Big& a, const Big& b);
Big ceilDiv(const Big& a, const Big& b);
Big SAVE(const Big& x);
Big square(const Big& x);
int wrap1(int position, int size);

struct WorkCounts {
    Big action;
    Big target;
    Big distance;
    Big connection;
    int direction;
};

Big dayCount(const Big& day);
WorkCounts workCounts(const Big& calculationDay, const Big& targetDay);

using Stone = std::array<Big, 5>;
using StoneTable = std::array<Stone, 47>;

StoneTable buildStones();
std::array<Big, 7> buildHiddenDrops(const WorkCounts& counts, const StoneTable& stones);
std::array<Big, 47> buildVisibleDrops(const WorkCounts& counts,
                                      const StoneTable& stones,
                                      const std::array<Big, 7>& hidden);

std::vector<int> permutationUnrank1(int rank1, const std::vector<int>& itemsAscending);
std::array<int, 6> bowlOrderFromNumber(int orderNumber);
std::array<int, 6> bowlOrderFromDrop(const Big& dropValue);

struct SauceResult {
    std::array<Big, 6> bowls;
    std::array<int, 6> orderAtDrop46;
};

std::array<Big, 6> initialBowls(const WorkCounts& counts);
std::pair<std::array<Big, 6>, std::array<int, 6>> applyVisibleDropsToBowls(
    std::array<Big, 6> bowls,
    const std::array<Big, 47>& visible,
    const StoneTable& stones);
std::array<Big, 6> postStir12(std::array<Big, 6> bowls);
SauceResult sauce(const Big& calculationDay, const Big& targetDay);
std::array<Big, 6> postStir12RawBowlSum(std::array<Big, 6> bowls);
SauceResult sauceRawBowlSum(const Big& calculationDay, const Big& targetDay);

struct AnswerStream {
    Big first;
    int directionStep;
};

int nextBowlInDrop46Order(const SauceResult& sauceResult, int queriedBowlId);
AnswerStream askBowl(const SauceResult& sauceResult, int queriedBowlId, int seal);
Big answerAt(const AnswerStream& stream, const Big& k);
Big chooseRankShort(const AnswerStream& stream, const Big& N);
Big chooseRankWide(const AnswerStream& stream, const Big& N);
Big chooseRank(const AnswerStream& stream, const Big& N);

Big fallingFactorial(int n, int k);
std::vector<int> unrankDistinctNameIndices(int masterSize, int k, const Big& rank1);

class BoundedCompositionFamily {
public:
    BoundedCompositionFamily(int total, int slots, int lo, int hi);
    Big count();
    std::vector<int> unrank1(const Big& rank1);

private:
    int total_;
    int slots_;
    int lo_;
    int hi_;
    std::map<std::pair<int, int>, Big> memo_;
    Big countSuffix(int rem, int slots);
};

struct Year {
    Big number;
    Big openGateIndex;
    Big closeGateIndex;
    Big openGateDay;
    Big closeGateDay;
};

struct Cutlet {
    int nameIndex;
    Big openGateIndex;
    Big closeGateIndex;
    Big firstDay;
    Big lastDay;
};

struct YearStructure {
    int cutletCount;
    std::vector<int> cutletPartition;
    std::vector<int> cutletNameIndices;
    std::vector<Cutlet> cutlets;
    int monthCount;
    std::vector<int> monthLengths;
    std::vector<int> monthWeaving;
    std::vector<int> monthNameIndices;
};

struct CalendarDate {
    Big yearNumber;
    std::string cutletName;
    Big dayInCutlet;
    std::string monthName;
    Big dayInMonth;
};

class NormativeOracle {
public:
    explicit NormativeOracle(bool rawBowlSumCorrection = false);

    Big positiveGateGap(const Big& n);
    Big negativeGateGap(const Big& n);
    Big ensureGateIndex(const Big& k);
    void ensureGatesCover(const Big& lowDay, const Big& highDay);
    Big gateIndexAtOrBefore(const Big& day);
    Big gateIndexAtOrAfter(const Big& day);
    bool exactGateIndex(const Big& day, Big& indexOut);
    void seedGateAnchorForStage55Audit(const Big& index, const Big& day);

    Year year5000(const Big& calculationDay);
    Year nextYear(const Big& calculationDay, const Year& knownYear);
    Year previousYear(const Big& calculationDay, const Year& knownYear);
    Year findTargetYear(const Big& calculationDay, const Big& targetDay);

    int chooseCutletCount(const SauceResult& structureSauce, const Year& year);
    std::vector<int> chooseCutletPartition(const Big& calculationDay,
                                           const SauceResult& structureSauce,
                                           const Year& year,
                                           int cutletCount);
    std::vector<int> chooseCutletNameIndices(const SauceResult& structureSauce, int cutletCount);
    std::vector<Cutlet> materializeCutlets(const Year& year,
                                           const std::vector<int>& partition,
                                           const std::vector<int>& nameIndices);

    int chooseMonthCount(const SauceResult& structureSauce, const Year& year);
    std::vector<int> chooseMonthLengths(const SauceResult& structureSauce,
                                        const Year& year,
                                        int monthCount);
    std::vector<int> chooseMonthWeaving(const SauceResult& structureSauce,
                                        const std::vector<int>& monthLengths);
    std::vector<int> chooseMonthNameIndices(const SauceResult& structureSauce, int monthCount);
    YearStructure buildYearStructure(const Big& calculationDay, const Year& year);
    CalendarDate calendarDate(const Big& calculationDay, const Big& targetDay);

    Big gateValueForTest(const Big& index) { return ensureGateIndex(index); }

private:
    bool rawBowlSumCorrection_ = false;
    std::map<Big, Big> gate_;
    Big minKnownGateIndex_;
    Big maxKnownGateIndex_;

    Big yearLength(const Big& openIndex, const Big& closeIndex);
    bool validYearPair(const Big& openIndex, const Big& closeIndex);
    int gapCountAsInt(const Year& year) const;
    SauceResult sauceForOracle(const Big& calculationDay, const Big& targetDay) const;

    struct CutletPartitionCounter {
        int G;
        int K;
        int required;
        bool hasRequired;
        std::map<std::tuple<int, int, int, bool>, Big> memo;
        Big countState(int rem, int slots, int cumulative, bool hitBoundary);
        Big countAll();
        std::vector<int> unrank1(const Big& rank1);
    };

    struct WeaveKey {
        std::vector<int> remaining;
        int openedUpTo;
        int closedUpTo;
        bool operator<(const WeaveKey& other) const;
    };

    struct WeaveCounter {
        std::vector<int> lengths;
        std::map<WeaveKey, Big> memo;
        bool legalMove(const WeaveKey& state, int j) const;
        WeaveKey applyMove(const WeaveKey& state, int j) const;
        Big count(const WeaveKey& state);
        std::vector<int> unrank1(const Big& rank1);
    };
};

std::string toDecimal(const Big& x);

} // namespace pastafari::reference
