package pastafari

import java.math.BigInteger

/** Cam 19: 6 × 720 prawf ffynonellau annibynnol â BigInteger. */
object Stage19BigIntegerTests {
    private val modulus = BigInteger("170141183460469231731687303715884105727")
    private val orderMod = BigInteger.valueOf(720L)
    private val one = BigInteger.ONE
    private val bowls = listOf(
        "0","101","211","307","401","503","607"
    ).map(::BigInteger)
    private val stones = listOf("17","29","43").map(::BigInteger)
    private fun save(n: BigInteger): BigInteger =
        n.subtract(one).mod(modulus).add(one)

    private fun independentOrder(rank0: Int): List<Int> {
        require(rank0 in 0..719)
        var n = rank0
        val remaining = mutableListOf(1,2,3,4,5,6)
        val order = ArrayList<Int>(6)
        for (length in 6 downTo 1) {
            var factorial = 1
            for (x in 2 until length) factorial *= x
            val index = n / factorial
            n %= factorial
            order.add(remaining.removeAt(index))
        }
        return order
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH09_BIGINT_ARGS" }
        val bases = listOf(
            "0","-720","720",
            "1234567890123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val patch = PourPatchWrapper()
        val oldExact = bowls.map { ExactInt.parse(it.toString()) }
        val stoneRow = MutableStoneRow(
            ExactInt.of(17L),ExactInt.of(29L),ExactInt.of(43L),
            ExactInt.of(71L),ExactInt.of(101L))
        var green = 0
        var red = 0
        var incidental = 0
        var wrongCells = 0
        for (base in bases) for (offset in 1..720) {
            val n = base.add(BigInteger.valueOf(offset.toLong()))
            val oneBased = n.subtract(one).mod(orderMod).add(one).toInt()
            val order = independentOrder(oneBased-1)
            val outcome = patch.patch(ExactInt.parse(n.toString()),1,oldExact,stoneRow)
            check(outcome.drop.toString() == n.toString() &&
                outcome.iteration == 1 && outcome.order == order &&
                outcome.sourceIdsByPosition == order.take(3) &&
                outcome.legacyRead.sourceIdsWrong == listOf(1,2,3) &&
                outcome.legacyRead.patch08Calls == 1 &&
                outcome.legacyRead.fixedPourCalls == 1 &&
                outcome.correctedPourCalls == 1) {
                "E_PATCH09_BIGINT_SHAPE_$n"
            }
            var different = false
            for (position in 1..3) {
                val coef = stones[position-1]
                val additive = BigInteger.valueOf((2L*position+1))
                val correct = save(n*n + coef*bowls[order[position-1]]+additive)
                val legacy = save(n*n + coef*bowls[position]+additive)
                check(outcome.correctedPours[position].toString() ==
                    correct.toString()) {
                    "E_PATCH09_BIGINT_CORRECT_$n-$position"
                }
                check(outcome.legacyRead.pours[position].toString() ==
                    legacy.toString()) {
                    "E_PATCH09_BIGINT_LEGACY_$n-$position"
                }
                if (correct != legacy) {
                    different = true
                    wrongCells++
                }
            }
            check(outcome.correctedPours[0] == ExactInt.ZERO &&
                outcome.correctedPours.drop(4).all { it == ExactInt.ZERO }) {
                "E_PATCH09_BIGINT_UNUSED_POURS_$n"
            }
            if (different) red++ else incidental++
            green++
        }
        check(green == 4320 && red == 4284 &&
            incidental == 36 && wrongCells == 10800) {
            "E_PATCH09_BIGINT_CARDINALITY"
        }
        println("STAGE19_BIGINT_CORRECTED_GREEN_4320")
        println("STAGE19_BIGINT_PRESERVED_LEGACY_RED_4284")
        println("STAGE19_BIGINT_PRESERVED_INCIDENTAL_MATCH_36")
        println("STAGE19_BIGINT_LEGACY_WRONG_CELLS_10800")
    }
}
