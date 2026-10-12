package pastafari

import java.math.BigInteger

/** 6 × 720 tyst annibynnol ar gyfer y tri arllwys anghywir. */
object Stage18BigIntegerTests {
    private val m = BigInteger("170141183460469231731687303715884105727")
    private val modOrder = BigInteger.valueOf(720L)
    private val one = BigInteger.ONE
    private val old = listOf("0","101","211","307","401","503","607").map(::BigInteger)
    private val stone = listOf("17","29","43").map(::BigInteger)
    private fun saved(v: BigInteger): BigInteger = v.subtract(one).mod(m).add(one)
    private fun independentPermutation(rank0: Int): List<Int> {
        require(rank0 in 0..719)
        val values = mutableListOf(1,2,3,4,5,6)
        var n = rank0
        val order = ArrayList<Int>(6)
        for (slots in 6 downTo 1) {
            var factorial = 1
            for (a in 2 until slots) factorial *= a
            val which = n / factorial
            n %= factorial
            order.add(values.removeAt(which))
        }
        return order
    }
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY09_BIGINT_ARGS" }
        val starts = listOf(
            "0","-720","720",
            "1234567890123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val adapter = LegacyFixedPourAdapter()
        val oldExact = old.map { ExactInt.parse(it.toString()) }
        val stoneRow = MutableStoneRow(ExactInt.of(17),ExactInt.of(29),
            ExactInt.of(43),ExactInt.of(71),ExactInt.of(101))
        var wrongRuns = 0
        var incidentalMatches = 0
        var wrongCells = 0
        for (base in starts) for (offset in 1..720) {
            val n = base.add(BigInteger.valueOf(offset.toLong()))
            val oneBased = n.subtract(one).mod(modOrder).add(one).toInt()
            val correctOrder = independentPermutation(oneBased - 1)
            val raw = adapter.oldFixedPour(ExactInt.parse(n.toString()),1,oldExact,stoneRow)
            check(raw.order == correctOrder && raw.sourceIdsWrong == listOf(1,2,3) &&
                raw.sourceIdsByPosition == correctOrder.take(3) &&
                raw.fixedPourCalls == 1 && raw.patch08Calls == 1) {
                "E_DISCOVERY09_BIGINT_ORDER_$n"
            }
            var difference = false
            for (p in 1..3) {
                val coefficient = stone[p-1]
                val additive = BigInteger.valueOf((2L*p+1))
                val oldFixed = saved(n.multiply(n) + coefficient * old[p] + additive)
                val ordered = saved(n.multiply(n) +
                    coefficient * old[correctOrder[p-1]] + additive)
                check(raw.pours[p].toString() == oldFixed.toString()) {
                    "E_DISCOVERY09_BIGINT_WRONG_PHYSICAL_$n-$p"
                }
                if (oldFixed != ordered) {
                    difference = true
                    wrongCells++
                }
            }
            if (difference) wrongRuns++ else incidentalMatches++
        }
        check(wrongRuns == 4284 && incidentalMatches == 36 &&
            wrongCells == 10800) { "E_DISCOVERY09_BIGINT_CARDINALITY" }
        println("STAGE18_BIGINT_EXPECTED_RED_4284")
        println("STAGE18_BIGINT_INCIDENTAL_MATCH_36")
        println("STAGE18_BIGINT_WRONG_POUR_CELLS_10800")
    }
}
