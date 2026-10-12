package pastafari

import java.math.BigInteger

/** Chwe chylch llawn; mae'r oracl rhifyddol yn defnyddio BigInteger. */
object Stage16BigIntegerTests {
    private val modulus = BigInteger.valueOf(720L)
    private val one = BigInteger.ONE
    private fun independentlyUnrank0(rank0: Int): List<Int> {
        require(rank0 in 0..719)
        var rest = rank0
        val available = mutableListOf(1,2,3,4,5,6)
        val result = ArrayList<Int>()
        for (length in 6 downTo 1) {
            var factorial = 1
            for (i in 2 until length) factorial *= i
            val idx = rest / factorial
            rest %= factorial
            result.add(available.removeAt(idx))
        }
        return result
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY08_BIGINT_ARGS" }
        val bases = listOf(
            "0","-720","720","123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val adapter = LegacyPermutationOrderAdapter()
        var numeric = 0
        var undefined = 0
        var red = 0
        for (base in bases) for (offset in 1..720) {
            val number = base.add(BigInteger.valueOf(offset.toLong()))
            val oneBased = number.subtract(one).mod(modulus).add(one).toInt()
            val normative = independentlyUnrank0(oneBased - 1)
            val raw = adapter.legacyPermutationOrderFromDropWrong(
                ExactInt.parse(number.toString()))
            check(raw.dropValue.toString() == number.toString() &&
                raw.oneBased == oneBased && raw.passedRank0 == oneBased &&
                raw.legacyCalls == 1) { "E_DISCOVERY08_BIGINT_ORDINAL_$number" }
            if (oneBased == 720) {
                check(raw.legacyOrder == null && raw.undefined &&
                    raw.errorId == "E_DISCOVERY08_RANK0_RANGE") {
                    "E_DISCOVERY08_BIGINT_UNDEFINED_$number"
                }
                undefined++
            } else {
                check(raw.legacyOrder == independentlyUnrank0(oneBased) &&
                    raw.legacyOrder != normative && !raw.undefined &&
                    raw.errorId == null) {
                    "E_DISCOVERY08_BIGINT_SHIFT_$number"
                }
                numeric++
            }
            red++
        }
        check(red == 4320 && numeric == 4314 && undefined == 6) {
            "E_DISCOVERY08_BIGINT_COUNTS"
        }
        println("STAGE16_BIGINT_INDEPENDENT_RED_4320")
        println("STAGE16_BIGINT_SHIFTED_NUMERIC_4314")
        println("STAGE16_BIGINT_UNDEFINED_6")
    }
}
