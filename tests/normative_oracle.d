module normative_oracle;

import std.bigint : BigInt;
import std.conv : to;
import std.exception : enforce;

alias BI = BigInt;

enum long TABLETS_DAY = -278522;
enum long FOUNDATION_DAY = -15055671;
enum int GATE_GAP_MIN = 42;
enum int GATE_GAP_MAX = 963;
enum int YEAR_MIN_DAYS = 252;
enum int YEAR_MAX_DAYS = 5778;
enum int MIN_CUTLETS = 6;
enum int MAX_CUTLETS = 17;
enum int MIN_MONTHS = 3;
enum int MAX_MONTHS = 47;
enum int MIN_MONTH_DAYS = 4;
enum int MAX_MONTH_DAYS = 123;

enum int SEAL_GATE_GAP = 1;
enum int SEAL_YEAR_5000 = 10;
enum int SEAL_NEXT_YEAR = 11;
enum int SEAL_PREVIOUS_YEAR = 12;
enum int SEAL_CUTLET_COUNT = 20;
enum int SEAL_CUTLET_PARTITION = 21;
enum int SEAL_CUTLET_NAMES = 22;
enum int SEAL_MONTH_COUNT = 30;
enum int SEAL_MONTH_LENGTHS = 31;
enum int SEAL_MONTH_WEAVING = 32;
enum int SEAL_MONTH_NAMES = 33;

BI M()
{
    return BI("170141183460469231731687303715884105727");
}

BI regularMod(BI x, BI d)
{
    enforce(d >= 1, "E_MOD_DIVISOR");
    auto r = x % d;
    if (r < 0)
        r += d;
    return r;
}

long regularModLong(long x, long d)
{
    enforce(d >= 1, "E_MOD_DIVISOR_LONG");
    auto r = x % d;
    if (r < 0)
        r += d;
    return r;
}

BI save(BI x)
{
    return BI(1) + regularMod(x - 1, M());
}

long absLong(long x)
{
    return x < 0 ? -x : x;
}

int wrap1(int position, int size)
{
    return cast(int)(regularModLong(position - 1, size) + 1);
}

long ceilDivLong(long a, long b)
{
    enforce(a >= 0 && b >= 1, "E_CEIL_DIV");
    return (a + b - 1) / b;
}

struct WorkCounts
{
    BI action;
    BI target;
    BI distance;
    BI connection;
    int direction;
}

BI dayCount(long day)
{
    if (day == FOUNDATION_DAY)
        return BI(1);
    if (day > FOUNDATION_DAY)
        return BI(2) * (day - FOUNDATION_DAY) + 1;
    return BI(2) * (FOUNDATION_DAY - day);
}

WorkCounts workCounts(long calculationDay, long targetDay)
{
    WorkCounts c;
    c.action = dayCount(calculationDay);
    c.target = dayCount(targetDay);
    c.distance = BI(absLong(targetDay - calculationDay) + 1);
    c.connection = c.action + c.target;
    c.direction = targetDay < calculationDay ? 1 : (targetDay == calculationDay ? 2 : 3);
    return c;
}

BI[][] buildStones()
{
    BI[][] stone;
    stone.length = 47;
    stone[1] = [BI(17), BI(29), BI(43), BI(71), BI(101)];
    foreach (i; 2 .. 47)
    {
        auto old = stone[i - 1];
        BI[] next;
        next.length = 5;
        next[0] = save(old[0] * old[0] + 3 * old[1] + i);
        next[1] = save(old[1] * old[1] + 5 * old[2] + old[0]);
        next[2] = save(old[2] * old[2] + 7 * old[3] + old[1]);
        next[3] = save(old[3] * old[3] + 11 * old[4] + old[2]);
        next[4] = save(old[4] * old[4] + 13 * old[0] + old[3]);
        stone[i] = next;
    }
    return stone;
}

int[][] hiddenCoeff()
{
    return [
        [3,4,6,8], [5,7,10,12], [7,10,14,16], [9,13,18,20],
        [11,16,22,24], [13,19,26,28], [15,22,30,32]
    ];
}

int[] hiddenGrindKinds()
{
    return [0,1,2,3,4,0,1];
}

BI[] buildHiddenDrops(WorkCounts counts, BI[][] stones)
{
    BI[] hidden;
    hidden.length = 7;
    auto coeff = hiddenCoeff();
    auto kinds = hiddenGrindKinds();
    foreach (k0; 0 .. 7)
    {
        auto c = coeff[k0];
        auto k = k0 + 1;
        BI x = counts.action
            + c[0] * counts.target
            + c[1] * counts.distance
            + c[2] * counts.connection
            + c[3] * counts.direction;
        foreach (kind; 0 .. 5)
            x += stones[k][kind];
        x = save(x);
        foreach (g0; 0 .. 7)
        {
            auto oldX = x;
            x = save(oldX * oldX + 3 * oldX + stones[k][kinds[g0]] + (g0 + 1));
        }
        hidden[k0] = x;
    }
    return hidden;
}

struct GrindRow
{
    int a;
    int b;
    int c;
    int d;
    int kind;
}

GrindRow[] visibleGrinds()
{
    return [
        GrindRow(3,5,7,11,0), GrindRow(5,7,11,13,1), GrindRow(7,11,13,17,2),
        GrindRow(11,13,17,19,3), GrindRow(13,17,19,23,4), GrindRow(17,19,23,29,0),
        GrindRow(19,23,29,31,1), GrindRow(23,29,31,37,2), GrindRow(29,31,37,41,3),
        GrindRow(31,37,41,43,4), GrindRow(37,41,43,47,0)
    ];
}

BI priorValue(BI[] visible, BI[] hidden, int i, int back)
{
    auto slot = i - back;
    if (slot >= 1)
        return visible[slot];
    auto k = 1 - slot;
    enforce(k >= 1 && k <= 7, "E_PRIOR_HIDDEN");
    return hidden[k - 1];
}

BI[] buildVisibleDrops(WorkCounts counts, BI[][] stones, BI[] hidden)
{
    BI[] visible;
    visible.length = 47;
    auto grinds = visibleGrinds();
    foreach (i; 1 .. 47)
    {
        auto p1 = priorValue(visible, hidden, i, 1);
        auto p3 = priorValue(visible, hidden, i, 3);
        auto p7 = priorValue(visible, hidden, i, 7);
        BI x = save(
            stones[i][0] * counts.action
            + stones[i][1] * counts.target
            + stones[i][2] * counts.distance
            + stones[i][3] * counts.connection
            + stones[i][4] * counts.direction
            + p1 + 3 * p3 + 5 * p7 + i
        );
        foreach (row; grinds)
        {
            auto oldX = x;
            x = save(oldX * oldX + row.a * oldX + row.b * p1 + row.c * p3 + row.d * p7 + stones[i][row.kind]);
        }
        visible[i] = x;
    }
    return visible;
}

long factorialLong(int n)
{
    long r = 1;
    foreach (i; 2 .. n + 1)
        r *= i;
    return r;
}

int[] permutationUnrank1(long rank1)
{
    enforce(rank1 >= 1 && rank1 <= 720, "E_PERM_RANK");
    long rank0 = rank1 - 1;
    int[] remaining = [1,2,3,4,5,6];
    int[] result;
    while (remaining.length > 0)
    {
        auto block = factorialLong(cast(int)remaining.length - 1);
        auto q = cast(size_t)(rank0 / block);
        rank0 %= block;
        result ~= remaining[q];
        remaining = remaining[0 .. q] ~ remaining[q + 1 .. $];
    }
    return result;
}

int[] bowlOrderFromDrop(BI drop)
{
    auto orderNumber = cast(long)((drop - 1) % 720) + 1;
    return permutationUnrank1(orderNumber);
}

BI[] initialBowls(WorkCounts counts)
{
    int[] primes = [17,19,23,29,31,37];
    BI[] bowls;
    bowls.length = 7;
    foreach (id; 1 .. 7)
    {
        BI s = counts.action + counts.target * id + counts.distance + counts.connection + counts.direction + primes[id - 1] * primes[id - 1];
        bowls[id] = save(s * s + id);
    }
    return bowls;
}

struct DropBowlResult
{
    BI[] bowls;
    int[] orderAt46;
}

DropBowlResult applyVisibleDropsToBowls(BI[] bowlsInput, BI[] visible, BI[][] stones)
{
    auto bowls = bowlsInput.dup;
    int[] orderAt46;
    int[] stoneByPosition = [0,1,2,3,4,0];
    foreach (i; 1 .. 47)
    {
        auto drop = visible[i];
        auto order = bowlOrderFromDrop(drop);
        auto old = bowls.dup;
        BI[] pour;
        pour.length = 7;
        auto first = order[0];
        auto second = order[1];
        auto third = order[2];
        pour[1] = save(drop * drop + stones[i][0] * old[first] + 3 * i);
        pour[2] = save(drop * drop + stones[i][1] * old[second] + 5 * i);
        pour[3] = save(drop * drop + stones[i][2] * old[third] + 7 * i);
        BI[] nextBowls;
        nextBowls.length = 7;
        foreach (pos0; 0 .. 6)
        {
            auto position = cast(int)pos0 + 1;
            auto id = order[pos0];
            auto prev = order[wrap1(position - 1, 6) - 1];
            auto next = order[wrap1(position + 1, 6) - 1];
            BI s = old[id] + 2 * old[prev] + 3 * old[next] + pour[position] + drop + stones[i][stoneByPosition[pos0]];
            nextBowls[id] = save(s * s + 5 * old[prev] * old[next] + i * position);
        }
        bowls = nextBowls;
        if (i == 46)
            orderAt46 = order.dup;
    }
    return DropBowlResult(bowls, orderAt46);
}

BI[] postStir12(BI[] bowlsInput)
{
    auto bowls = bowlsInput.dup;
    foreach (stir; 1 .. 13)
    {
        auto old = bowls.dup;
        BI savedBowlSum = save(old[1] + old[2] + old[3] + old[4] + old[5] + old[6] + 149 * stir);
        auto orderNumber = cast(long)((savedBowlSum - 1) % 720) + 1;
        auto order = permutationUnrank1(orderNumber);
        BI[] nextBowls;
        nextBowls.length = 7;
        foreach (pos0; 0 .. 6)
        {
            auto position = cast(int)pos0 + 1;
            auto id = order[pos0];
            auto prev = order[wrap1(position - 1, 6) - 1];
            auto next = order[wrap1(position + 1, 6) - 1];
            BI s = old[id] + 3 * old[prev] + 5 * old[next] + savedBowlSum + stir + position * position;
            nextBowls[id] = save(s * s + 7 * old[prev] * old[next]);
        }
        bowls = nextBowls;
    }
    return bowls;
}

struct SauceResult
{
    BI[] bowls;
    int[] orderAt46;
}

SauceResult sauce(long calculationDay, long targetDay)
{
    auto counts = workCounts(calculationDay, targetDay);
    auto stones = buildStones();
    auto hidden = buildHiddenDrops(counts, stones);
    auto visible = buildVisibleDrops(counts, stones, hidden);
    auto bowls = initialBowls(counts);
    auto afterDrops = applyVisibleDropsToBowls(bowls, visible, stones);
    auto finalBowls = postStir12(afterDrops.bowls);
    return SauceResult(finalBowls, afterDrops.orderAt46);
}

struct AnswerStream
{
    BI first;
    int step;
}

int nextBowlInDrop46Order(SauceResult result, int queriedBowlId)
{
    int pos = -1;
    foreach (i, id; result.orderAt46)
        if (id == queriedBowlId)
            pos = cast(int)i;
    enforce(pos >= 0, "E_QUERY_BOWL");
    return result.orderAt46[(pos + 1) % 6];
}

AnswerStream askBowl(SauceResult result, int queriedBowlId, int seal)
{
    auto nextId = nextBowlInDrop46Order(result, queriedBowlId);
    auto first = save((result.bowls[queriedBowlId] + seal + 181) * (result.bowls[queriedBowlId] + seal + 181)
        + 179 * result.bowls[nextId] + seal);
    auto directionNumber = save((first + seal + 1 + 193) * (first + seal + 1 + 193)
        + 193 * first + 197 * result.bowls[6]);
    auto step = (directionNumber % 2) == 1 ? 1 : -1;
    return AnswerStream(first, step);
}

BI answerAt(AnswerStream stream, long k)
{
    return BI(1) + regularMod(stream.first - 1 + BI(stream.step) * k, M());
}

BI chooseRankShort(AnswerStream stream, BI N)
{
    enforce(N >= 1 && N <= M(), "E_SHORT_N");
    auto limit = (M() / N) * N;
    long k = 0;
    while (true)
    {
        auto x = answerAt(stream, k);
        if (x <= limit)
            return regularMod(x - 1, N) + 1;
        ++k;
    }
}

BI chooseRankWide(AnswerStream stream, BI N)
{
    enforce(N > M(), "E_WIDE_N");
    int places = 1;
    BI space = M();
    while (space < N)
    {
        ++places;
        space *= M();
    }
    BI wide = 1;
    BI weight = 1;
    foreach (j; 0 .. places)
    {
        wide += (answerAt(stream, j) - 1) * weight;
        weight *= M();
    }
    auto limit = (space / N) * N;
    while (wide > limit)
        wide = BI(1) + regularMod(wide - 1 + stream.step, space);
    return regularMod(wide - 1, N) + 1;
}

BI chooseRank(AnswerStream stream, BI N)
{
    enforce(N >= 1, "E_PICK_N");
    return N <= M() ? chooseRankShort(stream, N) : chooseRankWide(stream, N);
}

BI fallingFactorial(int n, int k)
{
    enforce(k >= 0 && k <= n, "E_FALLING");
    BI r = 1;
    foreach (j; 0 .. k)
        r *= (n - j);
    return r;
}

int[] unrankDistinctIndices(int n, int k, BI rank1)
{
    enforce(k >= 0 && k <= n, "E_UNRANK_DISTINCT_K");
    enforce(rank1 >= 1 && rank1 <= fallingFactorial(n, k), "E_UNRANK_DISTINCT_RANK");
    int[] remaining;
    foreach (i; 1 .. n + 1)
        remaining ~= i;
    int[] out;
    BI r = rank1;
    foreach (position; 0 .. k)
    {
        auto suffixLength = k - position - 1;
        auto block = fallingFactorial(cast(int)remaining.length - 1, suffixLength);
        foreach (candidate; 0 .. remaining.length)
        {
            if (r > block)
                r -= block;
            else
            {
                out ~= remaining[candidate];
                remaining = remaining[0 .. candidate] ~ remaining[candidate + 1 .. $];
                break;
            }
        }
    }
    return out;
}

string key3(int a, int b, int c)
{
    return a.to!string ~ ":" ~ b.to!string ~ ":" ~ c.to!string;
}

class BoundedCompositionFamily
{
    int total;
    int slots;
    int lo;
    int hi;
    BI[string] memo;

    this(int total, int slots, int lo, int hi)
    {
        this.total = total;
        this.slots = slots;
        this.lo = lo;
        this.hi = hi;
    }

    BI countSuffix(int rem, int k)
    {
        if (k == 0)
            return BI(rem == 0 ? 1 : 0);
        if (rem < k * lo || rem > k * hi)
            return BI(0);
        auto key = key3(rem, k, 0);
        if (auto p = key in memo)
            return *p;
        BI s = 0;
        foreach (x; lo .. hi + 1)
            s += countSuffix(rem - x, k - 1);
        memo[key] = s;
        return s;
    }

    BI count()
    {
        return countSuffix(total, slots);
    }

    int[] unrank1(BI rank1)
    {
        enforce(rank1 >= 1 && rank1 <= count(), "E_BOUNDED_RANK");
        BI r = rank1;
        int rem = total;
        int[] out;
        foreach (position; 0 .. slots)
        {
            auto slotsAfter = slots - position - 1;
            foreach (x; lo .. hi + 1)
            {
                auto block = countSuffix(rem - x, slotsAfter);
                if (r > block)
                    r -= block;
                else
                {
                    out ~= x;
                    rem -= x;
                    break;
                }
            }
        }
        return out;
    }
}

string cutletStateKey(int rem, int slots, int cumulative, bool hit)
{
    return rem.to!string ~ ":" ~ slots.to!string ~ ":" ~ cumulative.to!string ~ ":" ~ (hit ? "1" : "0");
}

class CutletPartitionFamily
{
    int G;
    int K;
    int required;
    BI[string] memo;

    this(int G, int K, int required)
    {
        this.G = G;
        this.K = K;
        this.required = required;
    }

    BI countState(int rem, int slots, int cumulative, bool hit)
    {
        if (slots == 0)
        {
            if (rem != 0)
                return BI(0);
            if (required < 0)
                return BI(1);
            return BI(hit ? 1 : 0);
        }
        if (rem < slots)
            return BI(0);
        auto key = cutletStateKey(rem, slots, cumulative, hit);
        if (auto p = key in memo)
            return *p;
        BI total = 0;
        auto maxX = rem - (slots - 1);
        foreach (x; 1 .. maxX + 1)
        {
            auto nextCumulative = cumulative + x;
            auto nextHit = hit;
            if (required >= 0 && !hit)
            {
                if (nextCumulative == required)
                    nextHit = true;
                else if (nextCumulative > required)
                    continue;
            }
            total += countState(rem - x, slots - 1, nextCumulative, nextHit);
        }
        memo[key] = total;
        return total;
    }

    BI count()
    {
        return countState(G, K, 0, false);
    }

    int[] unrank1(BI rank1)
    {
        enforce(rank1 >= 1 && rank1 <= count(), "E_CUTLET_PARTITION_RANK");
        BI r = rank1;
        int rem = G;
        int slots = K;
        int cumulative = 0;
        bool hit = false;
        int[] out;
        while (slots > 0)
        {
            auto maxX = rem - (slots - 1);
            bool selected = false;
            foreach (x; 1 .. maxX + 1)
            {
                auto nextCumulative = cumulative + x;
                auto nextHit = hit;
                if (required >= 0 && !hit)
                {
                    if (nextCumulative == required)
                        nextHit = true;
                    else if (nextCumulative > required)
                        continue;
                }
                auto block = countState(rem - x, slots - 1, nextCumulative, nextHit);
                if (r > block)
                    r -= block;
                else
                {
                    out ~= x;
                    rem -= x;
                    --slots;
                    cumulative = nextCumulative;
                    hit = nextHit;
                    selected = true;
                    break;
                }
            }
            enforce(selected, "E_CUTLET_PARTITION_SELECT");
        }
        return out;
    }
}

string weaveStateKey(int[] remaining, int opened, int closed)
{
    string key = opened.to!string ~ ":" ~ closed.to!string;
    foreach (x; remaining)
        key ~= ":" ~ x.to!string;
    return key;
}

class WeavingFamily
{
    int[] lengths;
    BI[string] memo;

    this(int[] lengths)
    {
        this.lengths = lengths.dup;
    }

    bool legal(int[] remaining, int opened, int closed, int j)
    {
        if (remaining[j] == 0)
            return false;
        auto alreadyOpened = remaining[j] < lengths[j];
        if (!alreadyOpened && j != opened)
            return false;
        auto willClose = remaining[j] == 1;
        if (willClose && j != closed)
            return false;
        return true;
    }

    void apply(int[] remaining, ref int opened, ref int closed, int j)
    {
        if (remaining[j] == lengths[j])
            opened = j + 1;
        --remaining[j];
        if (remaining[j] == 0)
            closed = j + 1;
    }

    BI countState(int[] remaining, int opened, int closed)
    {
        bool done = true;
        foreach (x; remaining)
            if (x != 0)
                done = false;
        if (done)
            return BI(1);
        auto key = weaveStateKey(remaining, opened, closed);
        if (auto p = key in memo)
            return *p;
        BI total = 0;
        foreach (j; 0 .. lengths.length)
        {
            if (!legal(remaining, opened, closed, cast(int)j))
                continue;
            auto nextRemaining = remaining.dup;
            auto nextOpened = opened;
            auto nextClosed = closed;
            apply(nextRemaining, nextOpened, nextClosed, cast(int)j);
            total += countState(nextRemaining, nextOpened, nextClosed);
        }
        memo[key] = total;
        return total;
    }

    BI count()
    {
        return countState(lengths.dup, 0, 0);
    }

    int[] unrank1(BI rank1)
    {
        enforce(rank1 >= 1 && rank1 <= count(), "E_WEAVE_RANK");
        BI r = rank1;
        auto remaining = lengths.dup;
        int opened = 0;
        int closed = 0;
        int[] out;
        int totalLength = 0;
        foreach (x; lengths)
            totalLength += x;
        while (out.length < totalLength)
        {
            bool selected = false;
            foreach (j; 0 .. lengths.length)
            {
                if (!legal(remaining, opened, closed, cast(int)j))
                    continue;
                auto nextRemaining = remaining.dup;
                auto nextOpened = opened;
                auto nextClosed = closed;
                apply(nextRemaining, nextOpened, nextClosed, cast(int)j);
                auto block = countState(nextRemaining, nextOpened, nextClosed);
                if (r > block)
                    r -= block;
                else
                {
                    out ~= cast(int)j + 1;
                    remaining = nextRemaining;
                    opened = nextOpened;
                    closed = nextClosed;
                    selected = true;
                    break;
                }
            }
            enforce(selected, "E_WEAVE_SELECT");
        }
        return out;
    }
}

struct Year
{
    long number;
    int openGateIndex;
    int closeGateIndex;
    long openGateDay;
    long closeGateDay;
}

struct YearStructure
{
    int cutletCount;
    int[] cutletPartition;
    int[] cutletNameIndices;
    int[] cutletOpenGateIndices;
    int[] cutletCloseGateIndices;
    long[] cutletFirstDays;
    long[] cutletLastDays;
    int monthCount;
    int[] monthLengths;
    int[] monthWeaving;
    int[] monthNameIndices;
}

struct CalendarTuple
{
    long yearNumber;
    int cutletCanonicalIndex;
    long dayInCutlet;
    int monthCanonicalIndex;
    int dayInMonth;
}

class OracleCalendar
{
    long[int] gates;
    int minKnown = 0;
    int maxKnown = 0;

    this()
    {
        gates[0] = FOUNDATION_DAY;
    }

    int positiveGateGap(int n)
    {
        auto r = sauce(FOUNDATION_DAY, FOUNDATION_DAY + n);
        auto stream = askBowl(r, 1, SEAL_GATE_GAP);
        auto chosen = chooseRank(stream, BI(922)).toLong();
        return cast(int)(41 + chosen);
    }

    int negativeGateGap(int n)
    {
        auto r = sauce(FOUNDATION_DAY, FOUNDATION_DAY - n);
        auto stream = askBowl(r, 1, SEAL_GATE_GAP);
        auto chosen = chooseRank(stream, BI(922)).toLong();
        return cast(int)(41 + chosen);
    }

    long ensureGateIndex(int k)
    {
        if (k > maxKnown)
        {
            foreach (n; maxKnown + 1 .. k + 1)
            {
                gates[n] = gates[n - 1] + positiveGateGap(n);
                maxKnown = n;
            }
        }
        if (k < minKnown)
        {
            int n = minKnown - 1;
            while (n >= k)
            {
                gates[n] = gates[n + 1] - negativeGateGap(-n);
                minKnown = n;
                --n;
            }
        }
        return gates[k];
    }

    void ensureGatesCover(long lowDay, long highDay)
    {
        enforce(lowDay <= highDay, "E_GATE_COVER");
        while (gates[minKnown] > lowDay)
            ensureGateIndex(minKnown - 1);
        while (gates[maxKnown] < highDay)
            ensureGateIndex(maxKnown + 1);
    }

    int gateIndexAtOrBefore(long day)
    {
        ensureGatesCover(day, day);
        int lo = minKnown;
        int hi = maxKnown;
        while (lo < hi)
        {
            auto mid = lo + (hi - lo + 1) / 2;
            if (gates[mid] <= day)
                lo = mid;
            else
                hi = mid - 1;
        }
        return lo;
    }

    int exactGateIndex(long day)
    {
        auto i = gateIndexAtOrBefore(day);
        return gates[i] == day ? i : int.min;
    }

    bool validYearPair(int openIndex, int closeIndex)
    {
        if (closeIndex - openIndex < 6)
            return false;
        auto length = gates[closeIndex] - gates[openIndex];
        return length >= YEAR_MIN_DAYS && length <= YEAR_MAX_DAYS;
    }

    Year year5000(long calculationDay)
    {
        ensureGatesCover(calculationDay - YEAR_MAX_DAYS, calculationDay + YEAR_MAX_DAYS);
        struct Candidate { int i; int j; long length; long openDay; }
        Candidate[] candidates;
        foreach (i; minKnown .. maxKnown)
        {
            foreach (j; i + 1 .. maxKnown + 1)
            {
                auto length = gates[j] - gates[i];
                if (length > YEAR_MAX_DAYS)
                    break;
                if (!validYearPair(i, j))
                    continue;
                if (!(gates[i] < calculationDay && calculationDay <= gates[j]))
                    continue;
                candidates ~= Candidate(i, j, length, gates[i]);
            }
        }
        for (size_t a = 1; a < candidates.length; ++a)
        {
            auto x = candidates[a];
            size_t b = a;
            while (b > 0 && (x.length < candidates[b - 1].length ||
                (x.length == candidates[b - 1].length && x.openDay < candidates[b - 1].openDay)))
            {
                candidates[b] = candidates[b - 1];
                --b;
            }
            candidates[b] = x;
        }
        enforce(candidates.length > 0, "E_YEAR5000_CANDIDATES");
        auto r = sauce(calculationDay, calculationDay);
        auto stream = askBowl(r, 1, SEAL_YEAR_5000);
        auto rank = chooseRank(stream, BI(candidates.length)).toLong();
        auto c = candidates[cast(size_t)rank - 1];
        return Year(5000, c.i, c.j, gates[c.i], gates[c.j]);
    }

    void sortCloseCandidates(ref int[] candidates, int openIndex)
    {
        for (size_t a = 1; a < candidates.length; ++a)
        {
            auto x = candidates[a];
            auto xLength = gates[x] - gates[openIndex];
            size_t b = a;
            while (b > 0 && xLength < gates[candidates[b - 1]] - gates[openIndex])
            {
                candidates[b] = candidates[b - 1];
                --b;
            }
            candidates[b] = x;
        }
    }

    void sortOpenCandidates(ref int[] candidates, int closeIndex)
    {
        for (size_t a = 1; a < candidates.length; ++a)
        {
            auto x = candidates[a];
            auto xLength = gates[closeIndex] - gates[x];
            size_t b = a;
            while (b > 0 && xLength < gates[closeIndex] - gates[candidates[b - 1]])
            {
                candidates[b] = candidates[b - 1];
                --b;
            }
            candidates[b] = x;
        }
    }

    Year nextYear(long calculationDay, Year known)
    {
        auto openIndex = known.closeGateIndex;
        int[] candidates;
        int closeIndex = openIndex + 1;
        while (true)
        {
            ensureGateIndex(closeIndex);
            if (gates[closeIndex] - gates[openIndex] > YEAR_MAX_DAYS)
                break;
            if (validYearPair(openIndex, closeIndex))
                candidates ~= closeIndex;
            ++closeIndex;
        }
        sortCloseCandidates(candidates, openIndex);
        enforce(candidates.length > 0, "E_NEXT_YEAR_CANDIDATES");
        auto r = sauce(calculationDay, gates[openIndex]);
        auto stream = askBowl(r, 1, SEAL_NEXT_YEAR);
        auto rank = chooseRank(stream, BI(candidates.length)).toLong();
        closeIndex = candidates[cast(size_t)rank - 1];
        return Year(known.number + 1, openIndex, closeIndex, gates[openIndex], gates[closeIndex]);
    }

    Year previousYear(long calculationDay, Year known)
    {
        auto closeIndex = known.openGateIndex;
        int[] candidates;
        int openIndex = closeIndex - 1;
        while (true)
        {
            ensureGateIndex(openIndex);
            if (gates[closeIndex] - gates[openIndex] > YEAR_MAX_DAYS)
                break;
            if (validYearPair(openIndex, closeIndex))
                candidates ~= openIndex;
            --openIndex;
        }
        sortOpenCandidates(candidates, closeIndex);
        enforce(candidates.length > 0, "E_PREVIOUS_YEAR_CANDIDATES");
        auto r = sauce(calculationDay, gates[closeIndex]);
        auto stream = askBowl(r, 1, SEAL_PREVIOUS_YEAR);
        auto rank = chooseRank(stream, BI(candidates.length)).toLong();
        openIndex = candidates[cast(size_t)rank - 1];
        return Year(known.number - 1, openIndex, closeIndex, gates[openIndex], gates[closeIndex]);
    }

    Year findTargetYear(long calculationDay, long targetDay)
    {
        auto y = year5000(calculationDay);
        while (targetDay > y.closeGateDay)
            y = nextYear(calculationDay, y);
        while (targetDay <= y.openGateDay)
            y = previousYear(calculationDay, y);
        enforce(y.openGateDay < targetDay && targetDay <= y.closeGateDay, "E_TARGET_YEAR");
        return y;
    }

    int chooseCutletCount(SauceResult structureSauce, Year year)
    {
        auto gateGaps = year.closeGateIndex - year.openGateIndex;
        int[] candidates;
        foreach (k; MIN_CUTLETS .. MAX_CUTLETS + 1)
            if (k <= gateGaps)
                candidates ~= k;
        enforce(candidates.length > 0, "E_CUTLET_COUNT_CANDIDATES");
        auto stream = askBowl(structureSauce, 2, SEAL_CUTLET_COUNT);
        auto rank = chooseRank(stream, BI(candidates.length)).toLong();
        return candidates[cast(size_t)rank - 1];
    }

    int[] chooseCutletPartition(long calculationDay, SauceResult structureSauce, Year year, int cutletCount)
    {
        auto G = year.closeGateIndex - year.openGateIndex;
        auto g = exactGateIndex(calculationDay);
        int required = -1;
        if (g != int.min && year.openGateIndex < g && g < year.closeGateIndex)
            required = g - year.openGateIndex;
        auto family = new CutletPartitionFamily(G, cutletCount, required);
        auto stream = askBowl(structureSauce, 2, SEAL_CUTLET_PARTITION);
        auto rank = chooseRank(stream, family.count());
        return family.unrank1(rank);
    }

    int[] chooseCutletNames(SauceResult structureSauce, int cutletCount)
    {
        auto N = fallingFactorial(17, cutletCount);
        auto stream = askBowl(structureSauce, 5, SEAL_CUTLET_NAMES);
        auto rank = chooseRank(stream, N);
        return unrankDistinctIndices(17, cutletCount, rank);
    }

    int chooseMonthCount(SauceResult structureSauce, Year year)
    {
        auto L = year.closeGateDay - year.openGateDay;
        auto lo = cast(int)ceilDivLong(L, 123);
        auto hiByLength = cast(int)(L / 4);
        auto hi = hiByLength < 47 ? hiByLength : 47;
        enforce(lo >= 3 && lo <= hi && hi <= 47, "E_MONTH_COUNT_BOUNDS");
        auto stream = askBowl(structureSauce, 3, SEAL_MONTH_COUNT);
        auto rank = chooseRank(stream, BI(hi - lo + 1)).toLong();
        return lo + cast(int)rank - 1;
    }

    int[] chooseMonthLengths(SauceResult structureSauce, Year year, int monthCount)
    {
        auto L = cast(int)(year.closeGateDay - year.openGateDay);
        auto family = new BoundedCompositionFamily(L, monthCount, 4, 123);
        auto stream = askBowl(structureSauce, 3, SEAL_MONTH_LENGTHS);
        auto rank = chooseRank(stream, family.count());
        return family.unrank1(rank);
    }

    int[] chooseMonthWeaving(SauceResult structureSauce, int[] monthLengths)
    {
        auto family = new WeavingFamily(monthLengths);
        auto stream = askBowl(structureSauce, 4, SEAL_MONTH_WEAVING);
        auto rank = chooseRank(stream, family.count());
        return family.unrank1(rank);
    }

    int[] chooseMonthNames(SauceResult structureSauce, int monthCount)
    {
        auto N = fallingFactorial(47, monthCount);
        auto stream = askBowl(structureSauce, 5, SEAL_MONTH_NAMES);
        auto rank = chooseRank(stream, N);
        return unrankDistinctIndices(47, monthCount, rank);
    }

    YearStructure buildYearStructure(long calculationDay, Year year)
    {
        auto firstDay = year.openGateDay + 1;
        auto r = sauce(calculationDay, firstDay);
        YearStructure s;
        s.cutletCount = chooseCutletCount(r, year);
        s.cutletPartition = chooseCutletPartition(calculationDay, r, year, s.cutletCount);
        s.cutletNameIndices = chooseCutletNames(r, s.cutletCount);
        s.cutletOpenGateIndices.length = s.cutletCount;
        s.cutletCloseGateIndices.length = s.cutletCount;
        s.cutletFirstDays.length = s.cutletCount;
        s.cutletLastDays.length = s.cutletCount;
        auto cursor = year.openGateIndex;
        foreach (k; 0 .. s.cutletCount)
        {
            auto open = cursor;
            auto close = cursor + s.cutletPartition[k];
            ensureGateIndex(open);
            ensureGateIndex(close);
            s.cutletOpenGateIndices[k] = open;
            s.cutletCloseGateIndices[k] = close;
            s.cutletFirstDays[k] = gates[open] + 1;
            s.cutletLastDays[k] = gates[close];
            cursor = close;
        }
        s.monthCount = chooseMonthCount(r, year);
        s.monthLengths = chooseMonthLengths(r, year, s.monthCount);
        s.monthWeaving = chooseMonthWeaving(r, s.monthLengths);
        s.monthNameIndices = chooseMonthNames(r, s.monthCount);
        return s;
    }

    CalendarTuple calendarDate(long calculationDay, long targetDay)
    {
        auto year = findTargetYear(calculationDay, targetDay);
        auto structure = buildYearStructure(calculationDay, year);
        int cutletId = -1;
        foreach (k; 0 .. structure.cutletCount)
        {
            if (structure.cutletFirstDays[k] <= targetDay && targetDay <= structure.cutletLastDays[k])
            {
                cutletId = k;
                break;
            }
        }
        enforce(cutletId >= 0, "E_CUTLET_RESOLVE");
        auto dayInCutlet = targetDay - structure.cutletFirstDays[cutletId] + 1;
        auto yearOffset0 = cast(int)(targetDay - (year.openGateDay + 1));
        auto monthId = structure.monthWeaving[yearOffset0];
        int dayInMonth = 0;
        foreach (p; 0 .. yearOffset0 + 1)
            if (structure.monthWeaving[p] == monthId)
                ++dayInMonth;
        return CalendarTuple(year.number, structure.cutletNameIndices[cutletId], dayInCutlet,
            structure.monthNameIndices[monthId - 1], dayInMonth);
    }
}
