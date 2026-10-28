package pastafari

import java.math.BigInteger

/**
 * Independent, exact and resource-bounded production month weaving.
 * First occurrences and last occurrences are both ordered by month ordinal.
 * A completed prefix may have opened some months without closing them.
 *
 * Count suffixes once with a bounded exact combinatorial table.
 * Lexicographic unranking uses conditional ratios of opened months and
 * the suffix counts; no repeated whole-suffix DP per day.
 * Budgets fail closed; no oracle, approximation, or partial rank is returned.
 */
class ProductionMonthWeavingEngine(
    inputLengths: IntArray,
    private val maxStates: Int = 250000,
    private val maxWorkUnits: Long = 4_000_000L
) {
    data class Day(val monthOrdinal: Int, val dayInMonth: Int)

    private val lengths = inputLengths.copyOf()
    private val totalDays = lengths.sum()
    private var workUnits = 0L

    private var suffixCounts: Array<Array<BigInteger>>? = null

    init {
        require(lengths.size in 1..47 && lengths.all { it in 1..123 } &&
            totalDays in 1..5778) { "E_WEAVING_LENGTHS" }
        require(maxStates in 1..250000 && maxWorkUnits in 1L..50_000_000L) {
            "E_WEAVING_STATE_LIMIT"
        }
    }

    private fun options(remaining: IntArray, opened: Int, closed: Int): IntArray {
        val out = ArrayList<Int>()
        for (i in remaining.indices) {
            if (remaining[i] == 0) continue
            if (remaining[i] == lengths[i] && i != opened) continue
            if (remaining[i] == 1 && i != closed) continue
            out.add(i)
        }
        return out.toIntArray()
    }

    private fun next(remaining: IntArray, opened: Int, closed: Int, i: Int): Triple<IntArray, Int, Int> {
        val result = remaining.copyOf()
        val first = result[i] == lengths[i]
        result[i]--
        return Triple(result, if (first) i + 1 else opened,
            if (result[i] == 0) i + 1 else closed)
    }

    private fun spend() {
        workUnits++
        check(workUnits <= maxWorkUnits) { "E_WEAVING_STATE_BUDGET" }
    }

    /**
     * F[j][s] counts completions of unopened months j..last relative
     * to an ordered-endings word of s already-opened remaining tokens.
     * The total does not depend on the distribution of those s tokens.
     *
     * Choose one previously opened token: F[j][s-1], or open month j.
     * When L>1, its remaining L-1 tokens must end after the old s tokens,
     * yielding C(s+L-2,L-2) interleavings times F[j+1][s+L-1].
     * When L=1, the new month can open only after s reaches zero.
     * Reachable s <= sum(lengths[0 until j]); no unbounded table.
     */
    private fun suffix(): Array<Array<BigInteger>> {
        suffixCounts?.let { return it }
        val prefix = IntArray(lengths.size + 1)
        for (i in lengths.indices) prefix[i + 1] = prefix[i] + lengths[i]
        val table = Array(lengths.size + 1) { emptyArray<BigInteger>() }
        table[lengths.size] = Array(totalDays + 1) { BigInteger.ONE }
        var states = totalDays + 1
        check(states <= maxStates) { "E_WEAVING_STATE_BUDGET" }

        for (j in lengths.lastIndex downTo 0) {
            val length = lengths[j]
            val row = Array(prefix[j] + 1) { BigInteger.ZERO }
            var coefficient = BigInteger.ONE
            for (s in row.indices) {
                states++
                spend()
                check(states <= maxStates) { "E_WEAVING_STATE_BUDGET" }
                row[s] = if (length == 1) {
                    if (s == 0) table[j + 1][0] else row[s - 1]
                } else {
                    val opened = coefficient.multiply(table[j + 1][s + length - 1])
                    (if (s == 0) BigInteger.ZERO else row[s - 1]).add(opened)
                }
                if (length > 1 && s < prefix[j]) {
                    coefficient = exactQuotient(
                        coefficient.multiply(BigInteger.valueOf((s + length - 1).toLong())),
                        BigInteger.valueOf((s + 1).toLong())
                    )
                }
            }
            table[j] = row
        }
        suffixCounts = table
        return table
    }

    fun countAll(): BigInteger = suffix()[0][0]

    /**
     * For already-opened months, ordered last occurrences give an exact
     * product of binomial coefficients. After consuming any one opened
     * month, the still-unopened suffix sees the SAME total opened length.
     * Consequently its completion factor is common to every opened choice.
     *
     * These ratios are N(opened-child) / N(parent-opened-prefix);
     * they are rational individually, but each complete branch count is
     * integral. We keep exact numerators and denominators, never floats.
     */
    private data class BranchRatio(val numerator: BigInteger, val denominator: BigInteger)

    private fun openedBranchRatios(
        remaining: IntArray, opened: Int, closed: Int
    ): Array<BranchRatio?> {
        val ratios = arrayOfNulls<BranchRatio>(remaining.size)
        if (opened == closed) return ratios
        val sums = IntArray(opened)
        var total = 0
        for (j in closed until opened) {
            total += remaining[j]
            sums[j] = total
        }
        var suffixNumerator = BigInteger.ONE
        var suffixDenominator = BigInteger.ONE
        for (i in opened - 1 downTo closed) {
            val numerator = if (i == closed) suffixNumerator else
                suffixNumerator.multiply(BigInteger.valueOf((remaining[i] - 1).toLong()))
            val denominator = if (i == closed) suffixDenominator else
                suffixDenominator.multiply(BigInteger.valueOf((sums[i] - 1).toLong()))
            ratios[i] = BranchRatio(numerator, denominator)
            if (i > closed) {
                suffixNumerator = suffixNumerator.multiply(
                    BigInteger.valueOf(sums[i - 1].toLong()))
                suffixDenominator = suffixDenominator.multiply(
                    BigInteger.valueOf((sums[i] - 1).toLong()))
            }
        }
        return ratios
    }

    private fun exactQuotient(numerator: BigInteger, denominator: BigInteger): BigInteger {
        check(denominator.signum() > 0) { "E_WEAVING_RATIO_DENOMINATOR" }
        val (result, remainder) = numerator.divideAndRemainder(denominator)
        check(remainder.signum() == 0) { "E_WEAVING_RATIO_NONINTEGRAL" }
        return result
    }

    /** Return only the requested day; do not materialize the full year. */
    fun dayAt(rank1: BigInteger, targetOffset0: Int): Day {
        require(targetOffset0 in 0 until totalDays) { "E_WEAVING_OFFSET" }
        val table = suffix()
        val total = table[0][0]
        require(rank1 >= BigInteger.ONE && rank1 <= total) { "E_WEAVING_RANK" }
        var remaining = lengths.copyOf()
        var opened = 0
        var closed = 0
        var rank = rank1
        var parentCount = total
        var selected = -1

        for (position in 0..targetOffset0) {
            val openedSum = (closed until opened).sumOf { remaining[it] }
            val currentFactor = table[opened][openedSum]
            val openedChildFactor = if (openedSum == 0) BigInteger.ZERO else
                table[opened][openedSum - 1]
            val ratios = openedBranchRatios(remaining, opened, closed)
            var consumedOpenedCount = BigInteger.ZERO
            var found = false
            for (ordinal in options(remaining, opened, closed)) {
                spend()
                val possibilities = if (ordinal < opened) {
                    val ratio = ratios[ordinal] ?: error("E_WEAVING_RATIO_STATE")
                    exactQuotient(parentCount.multiply(ratio.numerator)
                        .multiply(openedChildFactor), ratio.denominator.multiply(currentFactor))
                } else {
                    // Every opened choice precedes the single eligible new month.
                    parentCount.subtract(consumedOpenedCount)
                }
                check(possibilities.signum() > 0) { "E_WEAVING_ZERO_BRANCH" }
                if (rank > possibilities) {
                    rank = rank.subtract(possibilities)
                    if (ordinal < opened)
                        consumedOpenedCount = consumedOpenedCount.add(possibilities)
                } else {
                    val (child, nextOpened, nextClosed) =
                        next(remaining, opened, closed, ordinal)
                    remaining = child
                    opened = nextOpened
                    closed = nextClosed
                    parentCount = possibilities
                    selected = ordinal
                    found = true
                    break
                }
            }
            check(found) { "E_WEAVING_UNRANK" }
        }
        return Day(selected + 1, lengths[selected] - remaining[selected])
    }

}
