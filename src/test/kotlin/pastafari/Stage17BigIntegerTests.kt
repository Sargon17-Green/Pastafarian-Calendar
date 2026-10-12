package pastafari

import java.math.BigInteger

/** Cam 17: 6 cylch o 720 prawf BigInteger annibynnol. */
object Stage17BigIntegerTests {
    private val modulus = BigInteger.valueOf(720L)
    private val one = BigInteger.ONE
    private fun independentOrder(rank0: Int): List<Int> {
        require(rank0 in 0..719)
        var rest = rank0
        val available = mutableListOf(1,2,3,4,5,6)
        val answer = ArrayList<Int>(6)
        for (length in 6 downTo 1) {
            var block = 1
            for (factor in 2 until length) block *= factor
            val chosen = rest / block
            rest %= block
            answer.add(available.removeAt(chosen))
        }
        return answer
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH08_BIGINT_ARGS" }
        val bases = listOf(
            "0","-720","720","123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val wrapper = PermutationPatchWrapper()
        var green = 0
        var numericRed = 0
        var undefined = 0
        for (base in bases) for (offset in 1..720) {
            val input = base + BigInteger.valueOf(offset.toLong())
            val ordinal = input.subtract(one).mod(modulus).add(one).toInt()
            val result = wrapper.patch(ExactInt.parse(input.toString()))
            val expected = independentOrder(ordinal - 1)
            check(result.dropValue.toString() == input.toString() &&
                result.oneBased == ordinal &&
                result.correctedRank0 == ordinal - 1 &&
                result.correctedOrder == expected &&
                result.correctedUnrankCalls == 1 &&
                result.legacyRead.legacyCalls == 1) {
                "E_PATCH08_BIGINT_CORRECTION_$input"
            }
            if (ordinal == 720) {
                check(result.legacyRead.undefined &&
                    result.legacyRead.legacyOrder == null &&
                    result.legacyRead.errorId == "E_DISCOVERY08_RANK0_RANGE") {
                    "E_PATCH08_BIGINT_UNDEFINED_$input"
                }
                undefined++
            } else {
                check(!result.legacyRead.undefined &&
                    result.legacyRead.legacyOrder == independentOrder(ordinal) &&
                    result.legacyRead.legacyOrder != expected) {
                    "E_PATCH08_BIGINT_LEGACY_$input"
                }
                numericRed++
            }
            green++
        }
        check(green == 4320 && numericRed == 4314 && undefined == 6) {
            "E_PATCH08_BIGINT_CARDINALITY"
        }
        println("STAGE17_BIGINT_CORRECTED_GREEN_4320")
        println("STAGE17_BIGINT_PRESERVED_NUMERIC_RED_4314")
        println("STAGE17_BIGINT_PRESERVED_UNDEFINED_6")
    }
}
