package pastafari

import java.math.BigInteger
import java.util.ArrayDeque

/**
 * Independent, exact and resource-bounded production month weaving.
 * Months open and close in ascending ordinal order. Internal occurrences
 * may interleave; the canonical order is lexicographic by ordinal.
 *
 * The memo is intentionally capped: a large exact instance fails closed
 * rather than substituting a test oracle or an approximate rank.
 */
class ProductionMonthWeavingEngine(
    inputLengths: IntArray,
    private val maxStates: Int = 25000
) {
    data class Day(val monthOrdinal: Int, val dayInMonth: Int)

    private val lengths = inputLengths.copyOf()
    private val memo = HashMap<String, BigInteger>()
    private val totalDays = lengths.sum()

    init {
        require(lengths.size in 1..47 && lengths.all { it in 1..123 } &&
            totalDays in 1..5778) { "E_WEAVING_LENGTHS" }
        require(maxStates in 1..250000) { "E_WEAVING_STATE_LIMIT" }
    }

    private data class Frame(
        val remaining: IntArray,
        val opened: Int,
        val closed: Int,
        val key: String,
        val options: IntArray,
        var cursor: Int = 0,
        var sum: BigInteger = BigInteger.ZERO
    )

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

    private fun count(remaining: IntArray, opened: Int, closed: Int): BigInteger {
        val root = key(remaining, opened, closed)
        memo[root]?.let { return it }
        val stack = ArrayDeque<Frame>()
        stack.addLast(Frame(remaining.copyOf(), opened, closed,
            root, options(remaining, opened, closed)))
        while (stack.isNotEmpty()) {
            val frame = stack.last()
            if (frame.remaining.all { it == 0 }) {
                memo[frame.key] = BigInteger.ONE
                stack.removeLast()
                if (stack.isNotEmpty()) stack.last().sum = stack.last().sum.add(BigInteger.ONE)
                continue
            }
            if (frame.cursor == frame.options.size) {
                memo[frame.key] = frame.sum
                stack.removeLast()
                if (stack.isNotEmpty()) stack.last().sum = stack.last().sum.add(frame.sum)
                continue
            }
            val chosen = frame.options[frame.cursor++]
            val (child, nextOpened, nextClosed) = next(frame.remaining, frame.opened, frame.closed, chosen)
            val childKey = key(child, nextOpened, nextClosed)
            val cached = memo[childKey]
            if (cached != null) {
                frame.sum = frame.sum.add(cached)
            } else {
                check(memo.size + stack.size < maxStates) { "E_WEAVING_STATE_BUDGET" }
                stack.addLast(Frame(child, nextOpened, nextClosed, childKey,
                    options(child, nextOpened, nextClosed)))
            }
        }
        return memo[root] ?: error("E_WEAVING_COUNT_MISSING")
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
