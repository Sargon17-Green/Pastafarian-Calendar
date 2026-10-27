package pastafari

import java.math.BigInteger

/** Independent brute-force check on tiny synthetic families, not a full-date certification. */
object Post55ProductionWeavingTests {
    private fun enumerate(lengths: IntArray): List<List<Int>> {
        val out = ArrayList<List<Int>>()
        fun walk(left: IntArray, opened: Int, closed: Int, prefix: List<Int>) {
            if (left.all { it == 0 }) { out.add(prefix); return }
            for (i in left.indices) {
                if (left[i] == 0) continue
                if (left[i] == lengths[i] && i != opened) continue
                if (left[i] == 1 && i != closed) continue
                val first = left[i] == lengths[i]
                left[i]--
                walk(left, if (first) i + 1 else opened,
                    if (left[i] == 0) i + 1 else closed, prefix + (i + 1))
                left[i]++
            }
        }
        walk(lengths.copyOf(), 0, 0, emptyList())
        return out
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        var checks = 0
        for (lengths in listOf(intArrayOf(1), intArrayOf(2, 2),
                intArrayOf(3, 2, 2), intArrayOf(3, 3, 2), intArrayOf(2, 2, 2, 2))) {
            val expected = enumerate(lengths)
            val engine = ProductionMonthWeavingEngine(lengths)
            check(engine.countAll() == BigInteger.valueOf(expected.size.toLong())) {
                "E_WEAVING_COUNT"
            }
            for ((index, sequence) in expected.withIndex()) {
                for (offset in sequence.indices) {
                    val month = sequence[offset]
                    val day = sequence.take(offset + 1).count { it == month }
                    check(engine.dayAt(BigInteger.valueOf(index + 1L), offset) ==
                        ProductionMonthWeavingEngine.Day(month, day)) { "E_WEAVING_ORDER" }
                    checks++
                }
            }
        }
        var blocked = false
        try { ProductionMonthWeavingEngine(intArrayOf(4, 4, 4), maxStates = 1).countAll() }
        catch (error: IllegalStateException) { blocked = error.message == "E_WEAVING_STATE_BUDGET" }
        check(blocked) { "E_WEAVING_BUDGET_FAIL_CLOSED" }
        println("POST55_PRODUCTION_WEAVING_SYNTHETIC_" + checks + "_GREEN")
        println("POST55_WEAVING_COMPONENT_NOT_FULL_DATE_CERTIFICATION")
    }
}
