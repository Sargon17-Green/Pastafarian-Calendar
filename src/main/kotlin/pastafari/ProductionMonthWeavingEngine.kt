package pastafari

import java.math.BigInteger
import java.util.LinkedHashMap

/**
 * Independent, exact and resource-bounded production month weaving.
 * First occurrences and last occurrences are both ordered by month ordinal.
 * A completed prefix may have opened some months without closing them.
 *
 * Count the legal suffixes by inserting each next month into the already
 * counted lower-ordinal words. In every valid word of months <= j, the last
 * occurrence of month j is the last symbol. If j has not yet opened, its
 * first occurrence must follow the first occurrence of j-1 (unless j-1
 * opened before the prefix). This gives a one-dimensional exact DP.
 *
 * maxStates limits coefficient evaluations in ONE count; maxWorkUnits limits
 * cumulative evaluations in the engine, including unranking. Both budgets
 * fail closed; no oracle, approximation, or partial rank is ever returned.
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

    private val memo = object : LinkedHashMap<String, BigInteger>(512, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, BigInteger>?): Boolean =
            size > 4096
    }

    init {
        require(lengths.size in 1..47 && lengths.all { it in 1..123 } &&
            totalDays in 1..5778) { "E_WEAVING_LENGTHS" }
        require(maxStates in 1..250000 && maxWorkUnits in 1L..50_000_000L) {
            "E_WEAVING_STATE_LIMIT"
        }
    }

    private fun key(remaining: IntArray, opened: Int, closed: Int): String {
        val chars = CharArray(remaining.size + 2)
        chars[0] = opened.toChar()
        chars[1] = closed.toChar()
        for (i in remaining.indices) chars[i + 2] = remaining[i].toChar()
        return String(chars)
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

    private fun choose(n: Int, k: Int, spend: () -> Unit): BigInteger {
        val smaller = minOf(k, n - k)
        var value = BigInteger.ONE
        for (i in 1..smaller) {
            spend()
            value = value.multiply(BigInteger.valueOf((n - smaller + i).toLong()))
                .divide(BigInteger.valueOf(i.toLong()))
        }
        return value
    }

    private fun count(remaining: IntArray, opened: Int, closed: Int): BigInteger {
        val root = key(remaining, opened, closed)
        memo[root]?.let { return it }
        if (remaining.all { it == 0 }) return BigInteger.ONE

        var localStates = 0
        fun spend() {
            localStates++
            workUnits++
            check(localStates <= maxStates && workUnits <= maxWorkUnits) {
                "E_WEAVING_STATE_BUDGET"
            }
        }

        val maxDay = remaining.sum()
        var distribution = Array(maxDay + 1) { BigInteger.ZERO }
        var countSoFar = 0

        for (month in closed until remaining.size) {
            val size = remaining[month]
            check(size > 0) { "E_WEAVING_STATE_INVALID" }
            if (month == closed) {
                // A month opened before the given prefix has first-position 0.
                // Otherwise its first occurrence in the residual word is 1.
                distribution[if (month < opened) 0 else 1] = BigInteger.ONE
                countSoFar = size
                spend()
                continue
            }
            val successor = Array(maxDay + 1) { BigInteger.ZERO }
            if (month < opened) {
                // This month's first occurrence is already in the fixed prefix.
                // Insert size-1 indistinguishable symbols before the final symbol.
                successor[0] = distribution[0].multiply(
                    choose(countSoFar + size - 1, size - 1, ::spend))
                spend()
            } else if (size == 1) {
                // The sole occurrence must be last, after the preceding month.
                successor[countSoFar + 1] = distribution.fold(BigInteger.ZERO, BigInteger::add)
                spend()
            } else {
                // distribution[p]: words whose preceding month's first
                // residual occurrence is at position p (p=0 if pre-opened).
                // Place first current symbol after t parent symbols (t>=p),
                // then insert the remaining size-2 symbols before its final
                // occurrence in C(countSoFar-t+size-2, size-2) ways.
                var prefix = distribution.fold(BigInteger.ZERO, BigInteger::add)
                var coefficient = BigInteger.ONE // t=countSoFar
                for (t in countSoFar downTo 0) {
                    spend()
                    successor[t + 1] = prefix.multiply(coefficient)
                    prefix = prefix.subtract(distribution[t])
                    if (t > 0) {
                        coefficient = coefficient
                            .multiply(BigInteger.valueOf((countSoFar - t + size - 1).toLong()))
                            .divide(BigInteger.valueOf((countSoFar - t + 1).toLong()))
                    }
                }
            }
            distribution = successor
            countSoFar += size
        }
        val answer = distribution.fold(BigInteger.ZERO, BigInteger::add)
        memo[root] = answer
        return answer
    }

    fun countAll(): BigInteger = count(lengths, 0, 0)

    /** Return only the required day; do not materialize the full year. */
    fun dayAt(rank1: BigInteger, targetOffset0: Int): Day {
        require(targetOffset0 in 0 until totalDays) { "E_WEAVING_OFFSET" }
        require(rank1 >= BigInteger.ONE && rank1 <= countAll()) { "E_WEAVING_RANK" }
        var remaining = lengths.copyOf()
        var opened = 0
        var closed = 0
        var rank = rank1
        var selected = -1
        for (position in 0..targetOffset0) {
            var found = false
            for (ordinal in options(remaining, opened, closed)) {
                val (child, nextOpened, nextClosed) = next(remaining, opened, closed, ordinal)
                val possibilities = count(child, nextOpened, nextClosed)
                if (rank > possibilities) {
                    rank = rank.subtract(possibilities)
                } else {
                    remaining = child
                    opened = nextOpened
                    closed = nextClosed
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
