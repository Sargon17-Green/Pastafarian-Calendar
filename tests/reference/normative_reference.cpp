#include "tests/reference/normative_reference.hpp"
#include "pastafari/source_language_catalog.hpp"

#include <algorithm>
#include <numeric>
#include <sstream>
#include <stdexcept>

namespace pastafari::reference {

namespace {

constexpr int WHEAT = 0;
constexpr int BARLEY = 1;
constexpr int SALT = 2;
constexpr int BITTER = 3;
constexpr int RED = 4;

struct GrindRow {
    int a;
    int b;
    int c;
    int d;
    int kind;
};

constexpr std::array<GrindRow, 11> VISIBLE_GRINDS{{
    {3, 5, 7, 11, WHEAT},
    {5, 7, 11, 13, BARLEY},
    {7, 11, 13, 17, SALT},
    {11, 13, 17, 19, BITTER},
    {13, 17, 19, 23, RED},
    {17, 19, 23, 29, WHEAT},
    {19, 23, 29, 31, BARLEY},
    {23, 29, 31, 37, SALT},
    {29, 31, 37, 41, BITTER},
    {31, 37, 41, 43, RED},
    {37, 41, 43, 47, WHEAT}
}};

constexpr std::array<std::array<int, 4>, 7> HIDDEN_COEFF{{
    std::array<int, 4>{3, 4, 6, 8},
    std::array<int, 4>{5, 7, 10, 12},
    std::array<int, 4>{7, 10, 14, 16},
    std::array<int, 4>{9, 13, 18, 20},
    std::array<int, 4>{11, 16, 22, 24},
    std::array<int, 4>{13, 19, 26, 28},
    std::array<int, 4>{15, 22, 30, 32}
}};

constexpr std::array<int, 7> HIDDEN_GRIND_STONE{{
    WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY
}};

constexpr std::array<int, 6> BOWL_PRIME{{17, 19, 23, 29, 31, 37}};
constexpr std::array<int, 6> BOWL_STIR_STONE_BY_POSITION{{
    WHEAT, BARLEY, SALT, BITTER, RED, WHEAT
}};

int bigToInt(const Big& x, const char* message) {
    if (x < 0 || x > std::numeric_limits<int>::max()) {
        throw std::runtime_error(message);
    }
    return x.convert_to<int>();
}

Big absBig(const Big& x) {
    return x < 0 ? -x : x;
}


} // namespace

Big regularMod(const Big& x, const Big& d) {
    if (d < 1) {
        throw std::invalid_argument("divisor positivus requiritur");
    }
    Big r = x % d;
    if (r < 0) {
        r += d;
    }
    return r;
}

Big floorDiv(const Big& a, const Big& b) {
    if (b <= 0) {
        throw std::invalid_argument("divisor positivus requiritur");
    }
    Big q = a / b;
    Big r = a % b;
    if (r != 0 && a < 0) {
        --q;
    }
    return q;
}

Big ceilDiv(const Big& a, const Big& b) {
    if (a < 0 || b < 1) {
        throw std::invalid_argument("argumenta divisionis superioris invalida sunt");
    }
    return floorDiv(a + b - 1, b);
}

Big SAVE(const Big& x) {
    return 1 + regularMod(x - 1, M);
}

Big square(const Big& x) {
    return x * x;
}

int wrap1(int position, int size) {
    if (size < 1) {
        throw std::invalid_argument("magnitudo positiva requiritur");
    }
    int r = (position - 1) % size;
    if (r < 0) {
        r += size;
    }
    return r + 1;
}

Big dayCount(const Big& day) {
    if (day == FOUNDATION_DAY) {
        return 1;
    }
    if (day > FOUNDATION_DAY) {
        return 2 * (day - FOUNDATION_DAY) + 1;
    }
    return 2 * (FOUNDATION_DAY - day);
}

WorkCounts workCounts(const Big& calculationDay, const Big& targetDay) {
    WorkCounts out;
    out.action = dayCount(calculationDay);
    out.target = dayCount(targetDay);
    out.distance = absBig(targetDay - calculationDay) + 1;
    out.connection = out.action + out.target;
    if (targetDay < calculationDay) {
        out.direction = 1;
    } else if (targetDay == calculationDay) {
        out.direction = 2;
    } else {
        out.direction = 3;
    }
    return out;
}

StoneTable buildStones() {
    StoneTable table{};
    table[1] = Stone{Big{17}, Big{29}, Big{43}, Big{71}, Big{101}};
    for (int i = 2; i <= 46; ++i) {
        const Stone old = table[i - 1];
        Stone next;
        next[WHEAT] = SAVE(square(old[WHEAT]) + 3 * old[BARLEY] + i);
        next[BARLEY] = SAVE(square(old[BARLEY]) + 5 * old[SALT] + old[WHEAT]);
        next[SALT] = SAVE(square(old[SALT]) + 7 * old[BITTER] + old[BARLEY]);
        next[BITTER] = SAVE(square(old[BITTER]) + 11 * old[RED] + old[SALT]);
        next[RED] = SAVE(square(old[RED]) + 13 * old[WHEAT] + old[BITTER]);
        table[i] = std::move(next);
    }
    return table;
}

std::array<Big, 7> buildHiddenDrops(const WorkCounts& counts, const StoneTable& stones) {
    std::array<Big, 7> hidden{};
    for (int k = 1; k <= 7; ++k) {
        const auto coeff = HIDDEN_COEFF[k - 1];
        Big x = counts.action
              + coeff[0] * counts.target
              + coeff[1] * counts.distance
              + coeff[2] * counts.connection
              + coeff[3] * counts.direction
              + stones[k][WHEAT]
              + stones[k][BARLEY]
              + stones[k][SALT]
              + stones[k][BITTER]
              + stones[k][RED];
        x = SAVE(x);
        for (int grind = 1; grind <= 7; ++grind) {
            const Big oldX = x;
            x = SAVE(square(oldX)
                     + 3 * oldX
                     + stones[k][HIDDEN_GRIND_STONE[grind - 1]]
                     + grind);
        }
        hidden[k - 1] = x;
    }
    return hidden;
}

std::array<Big, 47> buildVisibleDrops(const WorkCounts& counts,
                                      const StoneTable& stones,
                                      const std::array<Big, 7>& hidden) {
    std::array<Big, 47> visible{};
    auto prior = [&](int i, int back) -> Big {
        const int slot = i - back;
        if (slot >= 1) {
            return visible[slot];
        }
        const int k = 1 - slot;
        return hidden[k - 1];
    };

    for (int i = 1; i <= 46; ++i) {
        const Big p1 = prior(i, 1);
        const Big p3 = prior(i, 3);
        const Big p7 = prior(i, 7);
        Big x = SAVE(stones[i][WHEAT] * counts.action
                   + stones[i][BARLEY] * counts.target
                   + stones[i][SALT] * counts.distance
                   + stones[i][BITTER] * counts.connection
                   + stones[i][RED] * counts.direction
                   + p1 + 3 * p3 + 5 * p7 + i);
        for (const auto& row : VISIBLE_GRINDS) {
            const Big oldX = x;
            x = SAVE(square(oldX)
                     + row.a * oldX
                     + row.b * p1
                     + row.c * p3
                     + row.d * p7
                     + stones[i][row.kind]);
        }
        visible[i] = x;
    }
    return visible;
}

std::vector<int> permutationUnrank1(int rank1, const std::vector<int>& itemsAscending) {
    const int n = static_cast<int>(itemsAscending.size());
    int factorial = 1;
    for (int i = 2; i <= n; ++i) {
        factorial *= i;
    }
    if (rank1 < 1 || rank1 > factorial) {
        throw std::out_of_range("gradus permutationis extra fines est");
    }

    int rank0 = rank1 - 1;
    std::vector<int> remaining = itemsAscending;
    std::vector<int> result;
    result.reserve(remaining.size());
    for (int slotsLeft = n; slotsLeft >= 1; --slotsLeft) {
        int block = 1;
        for (int i = 2; i <= slotsLeft - 1; ++i) {
            block *= i;
        }
        const int q = rank0 / block;
        rank0 %= block;
        result.push_back(remaining.at(static_cast<std::size_t>(q)));
        remaining.erase(remaining.begin() + q);
    }
    return result;
}

std::array<int, 6> bowlOrderFromNumber(int orderNumber) {
    const auto v = permutationUnrank1(orderNumber, {1, 2, 3, 4, 5, 6});
    std::array<int, 6> out{};
    std::copy(v.begin(), v.end(), out.begin());
    return out;
}

std::array<int, 6> bowlOrderFromDrop(const Big& dropValue) {
    const int orderNumber = (regularMod(dropValue - 1, 720) + 1).convert_to<int>();
    return bowlOrderFromNumber(orderNumber);
}

std::array<Big, 6> initialBowls(const WorkCounts& counts) {
    std::array<Big, 6> bowls{};
    for (int bowlId = 1; bowlId <= 6; ++bowlId) {
        const Big s = counts.action
                    + counts.target * bowlId
                    + counts.distance
                    + counts.connection
                    + counts.direction
                    + Big{BOWL_PRIME[bowlId - 1]} * BOWL_PRIME[bowlId - 1];
        bowls[bowlId - 1] = SAVE(square(s) + bowlId);
    }
    return bowls;
}

std::pair<std::array<Big, 6>, std::array<int, 6>> applyVisibleDropsToBowls(
    std::array<Big, 6> bowls,
    const std::array<Big, 47>& visible,
    const StoneTable& stones) {
    std::array<int, 6> orderAtDrop46{};
    for (int i = 1; i <= 46; ++i) {
        const Big& drop = visible[i];
        const auto order = bowlOrderFromDrop(drop);
        const auto old = bowls;
        std::array<Big, 6> pour{};
        pour[0] = SAVE(square(drop) + stones[i][WHEAT] * old[order[0] - 1] + 3 * i);
        pour[1] = SAVE(square(drop) + stones[i][BARLEY] * old[order[1] - 1] + 5 * i);
        pour[2] = SAVE(square(drop) + stones[i][SALT] * old[order[2] - 1] + 7 * i);

        std::array<Big, 6> nextBowls{};
        for (int position = 1; position <= 6; ++position) {
            const int bowlId = order[position - 1];
            const int prevId = order[wrap1(position - 1, 6) - 1];
            const int nextId = order[wrap1(position + 1, 6) - 1];
            const int stoneKind = BOWL_STIR_STONE_BY_POSITION[position - 1];
            const Big s = old[bowlId - 1]
                        + 2 * old[prevId - 1]
                        + 3 * old[nextId - 1]
                        + pour[position - 1]
                        + drop
                        + stones[i][stoneKind];
            nextBowls[bowlId - 1] = SAVE(
                square(s)
                + 5 * old[prevId - 1] * old[nextId - 1]
                + i * position);
        }
        bowls = std::move(nextBowls);
        if (i == 46) {
            orderAtDrop46 = order;
        }
    }
    return {bowls, orderAtDrop46};
}

std::array<Big, 6> postStir12(std::array<Big, 6> bowls) {
    for (int stir = 1; stir <= 12; ++stir) {
        const auto old = bowls;
        Big savedBowlSum = 0;
        for (const auto& b : old) {
            savedBowlSum += b;
        }
        savedBowlSum = SAVE(savedBowlSum + 149 * stir);
        const int orderNumber = (regularMod(savedBowlSum - 1, 720) + 1).convert_to<int>();
        const auto order = bowlOrderFromNumber(orderNumber);
        std::array<Big, 6> nextBowls{};
        for (int position = 1; position <= 6; ++position) {
            const int bowlId = order[position - 1];
            const int prevId = order[wrap1(position - 1, 6) - 1];
            const int nextId = order[wrap1(position + 1, 6) - 1];
            const Big s = old[bowlId - 1]
                        + 3 * old[prevId - 1]
                        + 5 * old[nextId - 1]
                        + savedBowlSum
                        + stir
                        + position * position;
            nextBowls[bowlId - 1] = SAVE(
                square(s)
                + 7 * old[prevId - 1] * old[nextId - 1]);
        }
        bowls = std::move(nextBowls);
    }
    return bowls;
}

std::array<Big, 6> postStir12RawBowlSum(std::array<Big, 6> bowls) {
    for (int stir = 1; stir <= 12; ++stir) {
        const auto old = bowls;
        Big rawBowlSum = 0;
        for (const auto& b : old) {
            rawBowlSum += b;
        }
        const Big orderNumberSaved = SAVE(rawBowlSum + 149 * stir);
        const int orderNumber =
            (regularMod(orderNumberSaved - 1, 720) + 1).convert_to<int>();
        const auto order = bowlOrderFromNumber(orderNumber);
        std::array<Big, 6> nextBowls{};
        for (int position = 1; position <= 6; ++position) {
            const int bowlId = order[position - 1];
            const int prevId = order[wrap1(position - 1, 6) - 1];
            const int nextId = order[wrap1(position + 1, 6) - 1];
            const Big u = old[bowlId - 1]
                        + 3 * old[prevId - 1]
                        + 5 * old[nextId - 1]
                        + rawBowlSum
                        + stir
                        + position * position;
            nextBowls[bowlId - 1] = SAVE(
                square(u)
                + 7 * old[prevId - 1] * old[nextId - 1]);
        }
        bowls = std::move(nextBowls);
    }
    return bowls;
}

SauceResult sauce(const Big& calculationDay, const Big& targetDay) {
    const auto counts = workCounts(calculationDay, targetDay);
    const auto stones = buildStones();
    const auto hidden = buildHiddenDrops(counts, stones);
    const auto visible = buildVisibleDrops(counts, stones, hidden);
    auto bowls = initialBowls(counts);
    auto afterDrops = applyVisibleDropsToBowls(std::move(bowls), visible, stones);
    return SauceResult{postStir12(std::move(afterDrops.first)), afterDrops.second};
}

SauceResult sauceRawBowlSum(const Big& calculationDay, const Big& targetDay) {
    const auto counts = workCounts(calculationDay, targetDay);
    const auto stones = buildStones();
    const auto hidden = buildHiddenDrops(counts, stones);
    const auto visible = buildVisibleDrops(counts, stones, hidden);
    auto bowls = initialBowls(counts);
    auto afterDrops = applyVisibleDropsToBowls(std::move(bowls), visible, stones);
    return SauceResult{
        postStir12RawBowlSum(std::move(afterDrops.first)),
        afterDrops.second
    };
}

int nextBowlInDrop46Order(const SauceResult& sauceResult, int queriedBowlId) {
    auto it = std::find(sauceResult.orderAtDrop46.begin(), sauceResult.orderAtDrop46.end(), queriedBowlId);
    if (it == sauceResult.orderAtDrop46.end()) {
        throw std::invalid_argument("identitas catini ignota est");
    }
    const std::size_t p = static_cast<std::size_t>(std::distance(sauceResult.orderAtDrop46.begin(), it));
    return sauceResult.orderAtDrop46[(p + 1) % 6];
}

AnswerStream askBowl(const SauceResult& sauceResult, int queriedBowlId, int seal) {
    const int nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId);
    const Big first = SAVE(
        square(sauceResult.bowls[queriedBowlId - 1] + seal + 181)
        + 179 * sauceResult.bowls[nextId - 1]
        + seal);
    const Big directionNumber = SAVE(
        square(first + seal + 1 + 193)
        + 193 * first
        + 197 * sauceResult.bowls[5]);
    const int step = regularMod(directionNumber, 2) == 1 ? 1 : -1;
    return AnswerStream{first, step};
}

Big answerAt(const AnswerStream& stream, const Big& k) {
    return 1 + regularMod(stream.first - 1 + stream.directionStep * k, M);
}

Big chooseRankShort(const AnswerStream& stream, const Big& N) {
    if (N < 1 || N > M) {
        throw std::invalid_argument("magnitudo electionis brevis invalida est");
    }
    const Big acceptanceLimit = floorDiv(M, N) * N;
    Big k = 0;
    for (;;) {
        const Big x = answerAt(stream, k);
        if (x <= acceptanceLimit) {
            return regularMod(x - 1, N) + 1;
        }
        ++k;
    }
}

Big chooseRankWide(const AnswerStream& stream, const Big& N) {
    if (N <= M) {
        throw std::invalid_argument("magnitudo electionis lata invalida est");
    }
    int k = 1;
    Big space = M;
    while (space < N) {
        ++k;
        space *= M;
    }
    Big wide = 1;
    Big weight = 1;
    for (int j = 0; j < k; ++j) {
        wide += (answerAt(stream, j) - 1) * weight;
        weight *= M;
    }
    const Big acceptanceLimit = floorDiv(space, N) * N;
    while (wide > acceptanceLimit) {
        wide = 1 + regularMod(wide - 1 + stream.directionStep, space);
    }
    return regularMod(wide - 1, N) + 1;
}

Big chooseRank(const AnswerStream& stream, const Big& N) {
    if (N < 1) {
        throw std::invalid_argument("familia vacua eligi non potest");
    }
    return N <= M ? chooseRankShort(stream, N) : chooseRankWide(stream, N);
}

Big fallingFactorial(int n, int k) {
    if (k < 0 || k > n) {
        return 0;
    }
    Big r = 1;
    for (int j = 0; j < k; ++j) {
        r *= (n - j);
    }
    return r;
}

std::vector<int> unrankDistinctNameIndices(int masterSize, int k, const Big& rank1) {
    const Big total = fallingFactorial(masterSize, k);
    if (rank1 < 1 || rank1 > total) {
        throw std::out_of_range("gradus nominum extra fines est");
    }
    std::vector<int> remaining;
    remaining.reserve(masterSize);
    for (int i = 1; i <= masterSize; ++i) {
        remaining.push_back(i);
    }
    std::vector<int> out;
    out.reserve(k);
    Big r = rank1;
    for (int position = 1; position <= k; ++position) {
        const int suffixLength = k - position;
        const Big block = fallingFactorial(static_cast<int>(remaining.size()) - 1, suffixLength);
        for (std::size_t ci = 0; ci < remaining.size(); ++ci) {
            if (r > block) {
                r -= block;
            } else {
                out.push_back(remaining[ci]);
                remaining.erase(remaining.begin() + static_cast<std::ptrdiff_t>(ci));
                break;
            }
        }
    }
    return out;
}

BoundedCompositionFamily::BoundedCompositionFamily(int total, int slots, int lo, int hi)
    : total_(total), slots_(slots), lo_(lo), hi_(hi) {}

Big BoundedCompositionFamily::countSuffix(int rem, int slots) {
    if (slots == 0) {
        return rem == 0 ? Big{1} : Big{0};
    }
    if (rem < slots * lo_ || rem > slots * hi_) {
        return 0;
    }
    const auto key = std::make_pair(rem, slots);
    auto it = memo_.find(key);
    if (it != memo_.end()) {
        return it->second;
    }
    Big s = 0;
    for (int x = lo_; x <= hi_; ++x) {
        s += countSuffix(rem - x, slots - 1);
    }
    memo_[key] = s;
    return s;
}

Big BoundedCompositionFamily::count() {
    return countSuffix(total_, slots_);
}

std::vector<int> BoundedCompositionFamily::unrank1(const Big& rank1) {
    const Big total = count();
    if (rank1 < 1 || rank1 > total) {
        throw std::out_of_range("gradus compositionis extra fines est");
    }
    Big r = rank1;
    int rem = total_;
    std::vector<int> out;
    out.reserve(slots_);
    for (int position = 1; position <= slots_; ++position) {
        for (int x = lo_; x <= hi_; ++x) {
            const Big block = countSuffix(rem - x, slots_ - position);
            if (r > block) {
                r -= block;
            } else {
                out.push_back(x);
                rem -= x;
                break;
            }
        }
    }
    return out;
}

NormativeOracle::NormativeOracle(bool rawBowlSumCorrection)
    : rawBowlSumCorrection_(rawBowlSumCorrection),
      gate_{{Big{0}, FOUNDATION_DAY}},
      minKnownGateIndex_(0),
      maxKnownGateIndex_(0) {}

SauceResult NormativeOracle::sauceForOracle(
    const Big& calculationDay,
    const Big& targetDay) const {
    return rawBowlSumCorrection_
        ? sauceRawBowlSum(calculationDay, targetDay)
        : sauce(calculationDay, targetDay);
}

Big NormativeOracle::positiveGateGap(const Big& n) {
    if (n < 1) {
        throw std::invalid_argument("index portae positivus requiritur");
    }
    const auto r = sauceForOracle(FOUNDATION_DAY, FOUNDATION_DAY + n);
    const auto stream = askBowl(r, 1, SEAL_GATE_GAP);
    return 41 + chooseRank(stream, 922);
}

Big NormativeOracle::negativeGateGap(const Big& n) {
    if (n < 1) {
        throw std::invalid_argument("magnitudo portae negativa positiva requiritur");
    }
    const auto r = sauceForOracle(FOUNDATION_DAY, FOUNDATION_DAY - n);
    const auto stream = askBowl(r, 1, SEAL_GATE_GAP);
    return 41 + chooseRank(stream, 922);
}

Big NormativeOracle::ensureGateIndex(const Big& k) {
    if (k > maxKnownGateIndex_) {
        Big n = maxKnownGateIndex_ + 1;
        while (n <= k) {
            gate_[n] = gate_.at(n - 1) + positiveGateGap(n);
            ++n;
        }
        maxKnownGateIndex_ = k;
    }
    if (k < minKnownGateIndex_) {
        Big n = minKnownGateIndex_ - 1;
        while (n >= k) {
            gate_[n] = gate_.at(n + 1) - negativeGateGap(absBig(n));
            --n;
        }
        minKnownGateIndex_ = k;
    }
    return gate_.at(k);
}

void NormativeOracle::ensureGatesCover(const Big& lowDay, const Big& highDay) {
    if (lowDay > highDay) {
        throw std::invalid_argument("ordo dierum invalidus est");
    }
    while (gate_.at(minKnownGateIndex_) > lowDay) {
        ensureGateIndex(minKnownGateIndex_ - 1);
    }
    while (gate_.at(maxKnownGateIndex_) < highDay) {
        ensureGateIndex(maxKnownGateIndex_ + 1);
    }
}

Big NormativeOracle::gateIndexAtOrBefore(const Big& day) {
    ensureGatesCover(day, day);
    Big lo = minKnownGateIndex_;
    Big hi = maxKnownGateIndex_;
    while (lo < hi) {
        const Big mid = lo + floorDiv(hi - lo + 1, 2);
        if (gate_.at(mid) <= day) {
            lo = mid;
        } else {
            hi = mid - 1;
        }
    }
    return lo;
}

Big NormativeOracle::gateIndexAtOrAfter(const Big& day) {
    const Big i = gateIndexAtOrBefore(day);
    if (gate_.at(i) == day) {
        return i;
    }
    ensureGateIndex(i + 1);
    return i + 1;
}

bool NormativeOracle::exactGateIndex(const Big& day, Big& indexOut) {
    const Big i = gateIndexAtOrBefore(day);
    if (gate_.at(i) == day) {
        indexOut = i;
        return true;
    }
    return false;
}

void NormativeOracle::seedGateAnchorForStage55Audit(const Big& index, const Big& day) {
    gate_.clear();
    gate_[index] = day;
    minKnownGateIndex_ = index;
    maxKnownGateIndex_ = index;
}

Big NormativeOracle::yearLength(const Big& openIndex, const Big& closeIndex) {
    ensureGateIndex(openIndex);
    ensureGateIndex(closeIndex);
    return gate_.at(closeIndex) - gate_.at(openIndex);
}

bool NormativeOracle::validYearPair(const Big& openIndex, const Big& closeIndex) {
    if (closeIndex - openIndex < 6) {
        return false;
    }
    const Big length = yearLength(openIndex, closeIndex);
    return length >= YEAR_MIN_DAYS && length <= YEAR_MAX_DAYS;
}

Year NormativeOracle::year5000(const Big& calculationDay) {
    ensureGatesCover(calculationDay - YEAR_MAX_DAYS, calculationDay + YEAR_MAX_DAYS);
    struct Candidate {
        Big i;
        Big j;
        Big length;
        Big openDay;
    };
    std::vector<Candidate> candidates;
    Big i = minKnownGateIndex_;
    while (i < maxKnownGateIndex_) {
        Big j = i + 1;
        while (j <= maxKnownGateIndex_) {
            if (validYearPair(i, j)
                && gate_.at(i) < calculationDay
                && calculationDay <= gate_.at(j)) {
                candidates.push_back(Candidate{i, j, gate_.at(j) - gate_.at(i), gate_.at(i)});
            }
            ++j;
        }
        ++i;
    }
    std::sort(candidates.begin(), candidates.end(), [](const Candidate& a, const Candidate& b) {
        if (a.length != b.length) {
            return a.length < b.length;
        }
        return a.openDay < b.openDay;
    });
    if (candidates.empty()) {
        throw std::runtime_error("annus quinque milium inveniri non potuit");
    }
    const auto r = sauceForOracle(calculationDay, calculationDay);
    const auto stream = askBowl(r, 1, SEAL_YEAR_5000);
    const Big rank = chooseRank(stream, Big{candidates.size()});
    const auto& chosen = candidates.at(static_cast<std::size_t>((rank - 1).convert_to<unsigned long long>()));
    return Year{Big{5000}, chosen.i, chosen.j, gate_.at(chosen.i), gate_.at(chosen.j)};
}

Year NormativeOracle::nextYear(const Big& calculationDay, const Year& knownYear) {
    const Big openIndex = knownYear.closeGateIndex;
    std::vector<Big> candidates;
    Big closeIndex = openIndex + 1;
    for (;;) {
        ensureGateIndex(closeIndex);
        if (gate_.at(closeIndex) - gate_.at(openIndex) > YEAR_MAX_DAYS) {
            break;
        }
        if (validYearPair(openIndex, closeIndex)) {
            candidates.push_back(closeIndex);
        }
        ++closeIndex;
    }
    std::stable_sort(candidates.begin(), candidates.end(), [&](const Big& a, const Big& b) {
        return gate_.at(a) - gate_.at(openIndex) < gate_.at(b) - gate_.at(openIndex);
    });
    if (candidates.empty()) {
        throw std::runtime_error("annus sequens inveniri non potuit");
    }
    const auto r = sauceForOracle(calculationDay, gate_.at(openIndex));
    const auto stream = askBowl(r, 1, SEAL_NEXT_YEAR);
    const Big rank = chooseRank(stream, Big{candidates.size()});
    const Big chosenClose = candidates.at(static_cast<std::size_t>((rank - 1).convert_to<unsigned long long>()));
    return Year{knownYear.number + 1, openIndex, chosenClose, gate_.at(openIndex), gate_.at(chosenClose)};
}

Year NormativeOracle::previousYear(const Big& calculationDay, const Year& knownYear) {
    const Big closeIndex = knownYear.openGateIndex;
    std::vector<Big> candidates;
    Big openIndex = closeIndex - 1;
    for (;;) {
        ensureGateIndex(openIndex);
        if (gate_.at(closeIndex) - gate_.at(openIndex) > YEAR_MAX_DAYS) {
            break;
        }
        if (validYearPair(openIndex, closeIndex)) {
            candidates.push_back(openIndex);
        }
        --openIndex;
    }
    std::stable_sort(candidates.begin(), candidates.end(), [&](const Big& a, const Big& b) {
        return gate_.at(closeIndex) - gate_.at(a) < gate_.at(closeIndex) - gate_.at(b);
    });
    if (candidates.empty()) {
        throw std::runtime_error("annus prior inveniri non potuit");
    }
    const auto r = sauceForOracle(calculationDay, gate_.at(closeIndex));
    const auto stream = askBowl(r, 1, SEAL_PREVIOUS_YEAR);
    const Big rank = chooseRank(stream, Big{candidates.size()});
    const Big chosenOpen = candidates.at(static_cast<std::size_t>((rank - 1).convert_to<unsigned long long>()));
    return Year{knownYear.number - 1, chosenOpen, closeIndex, gate_.at(chosenOpen), gate_.at(closeIndex)};
}

Year NormativeOracle::findTargetYear(const Big& calculationDay, const Big& targetDay) {
    Year y = year5000(calculationDay);
    while (targetDay > y.closeGateDay) {
        y = nextYear(calculationDay, y);
    }
    while (targetDay <= y.openGateDay) {
        y = previousYear(calculationDay, y);
    }
    if (!(y.openGateDay < targetDay && targetDay <= y.closeGateDay)) {
        throw std::runtime_error("dies extra annum inventum est");
    }
    return y;
}

int NormativeOracle::gapCountAsInt(const Year& year) const {
    const Big gaps = year.closeGateIndex - year.openGateIndex;
    if (gaps < 0 || gaps > 1000000) {
        throw std::runtime_error("numerus intervallorum portarum inopinus est");
    }
    return gaps.convert_to<int>();
}

int NormativeOracle::chooseCutletCount(const SauceResult& structureSauce, const Year& year) {
    const int gateGaps = gapCountAsInt(year);
    std::vector<int> candidates;
    for (int k = MIN_CUTLETS; k <= MAX_CUTLETS; ++k) {
        if (k <= gateGaps) {
            candidates.push_back(k);
        }
    }
    const auto stream = askBowl(structureSauce, 2, SEAL_CUTLET_COUNT);
    const Big rank = chooseRank(stream, Big{candidates.size()});
    return candidates.at(static_cast<std::size_t>((rank - 1).convert_to<unsigned long long>()));
}

Big NormativeOracle::CutletPartitionCounter::countState(int rem,
                                                        int slots,
                                                        int cumulative,
                                                        bool hitBoundary) {
    if (slots == 0) {
        if (rem != 0) {
            return 0;
        }
        if (!hasRequired) {
            return 1;
        }
        return hitBoundary ? Big{1} : Big{0};
    }
    if (rem < slots) {
        return 0;
    }
    const auto key = std::make_tuple(rem, slots, cumulative, hitBoundary);
    auto it = memo.find(key);
    if (it != memo.end()) {
        return it->second;
    }
    Big total = 0;
    const int maxX = rem - (slots - 1);
    for (int x = 1; x <= maxX; ++x) {
        const int nextCumulative = cumulative + x;
        bool nextHit = hitBoundary;
        if (hasRequired && !hitBoundary) {
            if (nextCumulative == required) {
                nextHit = true;
            } else if (nextCumulative > required) {
                continue;
            }
        }
        total += countState(rem - x, slots - 1, nextCumulative, nextHit);
    }
    memo[key] = total;
    return total;
}

Big NormativeOracle::CutletPartitionCounter::countAll() {
    return countState(G, K, 0, false);
}

std::vector<int> NormativeOracle::CutletPartitionCounter::unrank1(const Big& rank1) {
    const Big total = countAll();
    if (rank1 < 1 || rank1 > total) {
        throw std::out_of_range("gradus partitionis extra fines est");
    }
    Big r = rank1;
    int rem = G;
    int slots = K;
    int cumulative = 0;
    bool hit = false;
    std::vector<int> out;
    out.reserve(K);
    while (slots > 0) {
        const int maxX = rem - (slots - 1);
        bool chosen = false;
        for (int x = 1; x <= maxX; ++x) {
            const int nextCumulative = cumulative + x;
            bool nextHit = hit;
            if (hasRequired && !hit) {
                if (nextCumulative == required) {
                    nextHit = true;
                } else if (nextCumulative > required) {
                    continue;
                }
            }
            const Big block = countState(rem - x, slots - 1, nextCumulative, nextHit);
            if (r > block) {
                r -= block;
            } else {
                out.push_back(x);
                rem -= x;
                --slots;
                cumulative = nextCumulative;
                hit = nextHit;
                chosen = true;
                break;
            }
        }
        if (!chosen) {
            throw std::runtime_error("partitio aperiri non potuit");
        }
    }
    return out;
}

std::vector<int> NormativeOracle::chooseCutletPartition(const Big& calculationDay,
                                                         const SauceResult& structureSauce,
                                                         const Year& year,
                                                         int cutletCount) {
    const int G = gapCountAsInt(year);
    Big gateIndex;
    bool hasRequired = exactGateIndex(calculationDay, gateIndex)
                    && year.openGateIndex < gateIndex
                    && gateIndex < year.closeGateIndex;
    int required = 0;
    if (hasRequired) {
        required = bigToInt(gateIndex - year.openGateIndex, "limes partitionis nimis magnus est");
    }
    CutletPartitionCounter family{G, cutletCount, required, hasRequired, {}};
    const Big count = family.countAll();
    const auto stream = askBowl(structureSauce, 2, SEAL_CUTLET_PARTITION);
    const Big rank = chooseRank(stream, count);
    return family.unrank1(rank);
}

std::vector<int> NormativeOracle::chooseCutletNameIndices(const SauceResult& structureSauce, int cutletCount) {
    const Big N = fallingFactorial(17, cutletCount);
    const auto stream = askBowl(structureSauce, 5, SEAL_CUTLET_NAMES);
    const Big rank = chooseRank(stream, N);
    return unrankDistinctNameIndices(17, cutletCount, rank);
}

std::vector<Cutlet> NormativeOracle::materializeCutlets(const Year& year,
                                                         const std::vector<int>& partition,
                                                         const std::vector<int>& nameIndices) {
    if (partition.size() != nameIndices.size()) {
        throw std::invalid_argument("partitiones et nomina numero discrepant");
    }
    std::vector<Cutlet> out;
    out.reserve(partition.size());
    Big cursorGate = year.openGateIndex;
    for (std::size_t k = 0; k < partition.size(); ++k) {
        const Big openGateIndex = cursorGate;
        const Big closeGateIndex = cursorGate + partition[k];
        const Big openDay = ensureGateIndex(openGateIndex);
        const Big closeDay = ensureGateIndex(closeGateIndex);
        out.push_back(Cutlet{nameIndices[k], openGateIndex, closeGateIndex, openDay + 1, closeDay});
        cursorGate = closeGateIndex;
    }
    return out;
}

int NormativeOracle::chooseMonthCount(const SauceResult& structureSauce, const Year& year) {
    const int L = bigToInt(year.closeGateDay - year.openGateDay, "longitudo anni nimis magna est");
    const int minMonths = (L + MAX_MONTH_DAYS - 1) / MAX_MONTH_DAYS;
    const int maxMonths = std::min(MAX_MONTHS, L / MIN_MONTH_DAYS);
    if (minMonths < MIN_MONTHS || minMonths > maxMonths || maxMonths > MAX_MONTHS) {
        throw std::runtime_error("fines mensium invalidi sunt");
    }
    const auto stream = askBowl(structureSauce, 3, SEAL_MONTH_COUNT);
    const Big rank = chooseRank(stream, Big{maxMonths - minMonths + 1});
    return minMonths + (rank - 1).convert_to<int>();
}

std::vector<int> NormativeOracle::chooseMonthLengths(const SauceResult& structureSauce,
                                                      const Year& year,
                                                      int monthCount) {
    const int L = bigToInt(year.closeGateDay - year.openGateDay, "longitudo anni nimis magna est");
    BoundedCompositionFamily family(L, monthCount, MIN_MONTH_DAYS, MAX_MONTH_DAYS);
    const Big count = family.count();
    const auto stream = askBowl(structureSauce, 3, SEAL_MONTH_LENGTHS);
    const Big rank = chooseRank(stream, count);
    return family.unrank1(rank);
}

bool NormativeOracle::WeaveKey::operator<(const WeaveKey& other) const {
    if (remaining != other.remaining) {
        return remaining < other.remaining;
    }
    if (openedUpTo != other.openedUpTo) {
        return openedUpTo < other.openedUpTo;
    }
    return closedUpTo < other.closedUpTo;
}

bool NormativeOracle::WeaveCounter::legalMove(const WeaveKey& state, int j) const {
    const int i = j - 1;
    if (state.remaining[i] == 0) {
        return false;
    }
    const bool alreadyOpened = state.remaining[i] < lengths[i];
    if (!alreadyOpened && j != state.openedUpTo + 1) {
        return false;
    }
    const bool willClose = state.remaining[i] == 1;
    if (willClose && j != state.closedUpTo + 1) {
        return false;
    }
    return true;
}

NormativeOracle::WeaveKey NormativeOracle::WeaveCounter::applyMove(const WeaveKey& state, int j) const {
    WeaveKey next = state;
    const int i = j - 1;
    if (next.remaining[i] == lengths[i]) {
        next.openedUpTo = j;
    }
    --next.remaining[i];
    if (next.remaining[i] == 0) {
        next.closedUpTo = j;
    }
    return next;
}

Big NormativeOracle::WeaveCounter::count(const WeaveKey& state) {
    bool empty = true;
    for (int x : state.remaining) {
        if (x != 0) {
            empty = false;
            break;
        }
    }
    if (empty) {
        return 1;
    }
    auto it = memo.find(state);
    if (it != memo.end()) {
        return it->second;
    }
    Big total = 0;
    for (int j = 1; j <= static_cast<int>(lengths.size()); ++j) {
        if (legalMove(state, j)) {
            total += count(applyMove(state, j));
        }
    }
    memo[state] = total;
    return total;
}

std::vector<int> NormativeOracle::WeaveCounter::unrank1(const Big& rank1) {
    WeaveKey state{lengths, 0, 0};
    const Big total = count(state);
    if (rank1 < 1 || rank1 > total) {
        throw std::out_of_range("gradus texturae extra fines est");
    }
    Big r = rank1;
    const int totalLength = std::accumulate(lengths.begin(), lengths.end(), 0);
    std::vector<int> out;
    out.reserve(totalLength);
    while (static_cast<int>(out.size()) < totalLength) {
        bool chosen = false;
        for (int j = 1; j <= static_cast<int>(lengths.size()); ++j) {
            if (!legalMove(state, j)) {
                continue;
            }
            WeaveKey next = applyMove(state, j);
            const Big block = count(next);
            if (r > block) {
                r -= block;
            } else {
                out.push_back(j);
                state = std::move(next);
                chosen = true;
                break;
            }
        }
        if (!chosen) {
            throw std::runtime_error("textura aperiri non potuit");
        }
    }
    return out;
}

std::vector<int> NormativeOracle::chooseMonthWeaving(const SauceResult& structureSauce,
                                                      const std::vector<int>& monthLengths) {
    WeaveCounter family{monthLengths, {}};
    WeaveKey initial{monthLengths, 0, 0};
    const Big count = family.count(initial);
    const auto stream = askBowl(structureSauce, 4, SEAL_MONTH_WEAVING);
    const Big rank = chooseRank(stream, count);
    return family.unrank1(rank);
}

std::vector<int> NormativeOracle::chooseMonthNameIndices(const SauceResult& structureSauce, int monthCount) {
    const Big N = fallingFactorial(47, monthCount);
    const auto stream = askBowl(structureSauce, 5, SEAL_MONTH_NAMES);
    const Big rank = chooseRank(stream, N);
    return unrankDistinctNameIndices(47, monthCount, rank);
}

YearStructure NormativeOracle::buildYearStructure(const Big& calculationDay, const Year& year) {
    const Big firstDay = year.openGateDay + 1;
    const SauceResult r = sauceForOracle(calculationDay, firstDay);
    const int cutletCount = chooseCutletCount(r, year);
    const auto cutletPartition = chooseCutletPartition(calculationDay, r, year, cutletCount);
    const auto cutletNames = chooseCutletNameIndices(r, cutletCount);
    const auto cutlets = materializeCutlets(year, cutletPartition, cutletNames);
    const int monthCount = chooseMonthCount(r, year);
    const auto monthLengths = chooseMonthLengths(r, year, monthCount);
    const auto monthWeaving = chooseMonthWeaving(r, monthLengths);
    const auto monthNames = chooseMonthNameIndices(r, monthCount);
    return YearStructure{
        cutletCount,
        cutletPartition,
        cutletNames,
        cutlets,
        monthCount,
        monthLengths,
        monthWeaving,
        monthNames
    };
}

CalendarDate NormativeOracle::calendarDate(const Big& calculationDay, const Big& targetDay) {
    const Year year = findTargetYear(calculationDay, targetDay);
    const YearStructure structure = buildYearStructure(calculationDay, year);

    int cutletId = -1;
    for (std::size_t i = 0; i < structure.cutlets.size(); ++i) {
        if (structure.cutlets[i].firstDay <= targetDay && targetDay <= structure.cutlets[i].lastDay) {
            cutletId = static_cast<int>(i);
            break;
        }
    }
    if (cutletId < 0) {
        throw std::runtime_error("segmentum diei inveniri non potuit");
    }
    const Big dayInCutlet = targetDay - structure.cutlets[cutletId].firstDay + 1;
    const Big offsetBig = targetDay - (year.openGateDay + 1);
    const int offset = bigToInt(offsetBig, "positio diei in anno nimis magna est");
    if (offset < 0 || offset >= static_cast<int>(structure.monthWeaving.size())) {
        throw std::runtime_error("positio diei in textura mensium invalida est");
    }
    const int monthId = structure.monthWeaving[offset];
    Big dayInMonth = 0;
    for (int p = 0; p <= offset; ++p) {
        if (structure.monthWeaving[p] == monthId) {
            ++dayInMonth;
        }
    }

    return CalendarDate{
        year.number,
        std::string(pastafari::cutletSourceName(static_cast<std::size_t>(structure.cutletNameIndices[cutletId]))),
        dayInCutlet,
        std::string(pastafari::monthSourceName(static_cast<std::size_t>(structure.monthNameIndices[monthId - 1]))),
        dayInMonth
    };
}

std::string toDecimal(const Big& x) {
    return x.convert_to<std::string>();
}

} // namespace pastafari::reference
