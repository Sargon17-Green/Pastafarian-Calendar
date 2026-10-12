package pastafari

import java.math.BigInteger

/** Oracl rhifyddol annibynnol, heb ddefnyddio cyfrifiad cynhyrchu na'r builder gweledig. */
object Stage15BigIntegerTests {
    private val mod = BigInteger("170141183460469231731687303715884105727")
    private val one = BigInteger.ONE
    private fun b(n: Int): BigInteger = BigInteger.valueOf(n.toLong())
    private val rows = arrayOf(
        intArrayOf(3,5,7,11,0), intArrayOf(5,7,11,13,1),
        intArrayOf(7,11,13,17,2), intArrayOf(11,13,17,19,3),
        intArrayOf(13,17,19,23,4), intArrayOf(17,19,23,29,0),
        intArrayOf(19,23,29,31,1), intArrayOf(23,29,31,37,2),
        intArrayOf(29,31,37,41,3), intArrayOf(31,37,41,43,4),
        intArrayOf(37,41,43,47,0)
    )
    private val stones = arrayOf(b(17),b(29),b(43),b(71),b(101))
    private fun save(x: BigInteger): BigInteger = (x-one).mod(mod)+one
    private fun calc(n: BigInteger, row: IntArray): BigInteger =
        save(n*n + n*b(row[0]) + b(3)*b(row[1]) +
            b(5)*b(row[2]) + b(7)*b(row[3]) + stones[row[4]])
    private fun calc(n: BigInteger, row: VisibleGrindRow): BigInteger =
        save(n*n + n*b(row.a) + b(3)*b(row.b) +
            b(5)*b(row.c) + b(7)*b(row.d) + stones[row.stoneKind])
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH07_BIGINT_ARGS" }
        val wrapper = GrindPatchWrapper()
        val seeds = listOf("1","2","17","88","123456789",
            "98765432109876543210987654321098765432109876543210")
            .map(::BigInteger)
        var green = 0
        var redNumeric = 0
        var redUndefined = 0
        for (seed in seeds) {
            for (ordinal in 1..11) {
                val result = wrapper.patch(ordinal)
                val expected = calc(seed,rows[ordinal-1])
                check(calc(seed,result.correctedRow) == expected) {
                    "E_PATCH07_BIGINT_GREEN_${seed}_${ordinal}"
                }
                val old = result.legacyRead
                if (ordinal == 11) {
                    check(old.row == null && old.undefined) {
                        "E_PATCH07_BIGINT_LAST_UNDEFINED"
                    }
                    redUndefined++
                } else {
                    val wrong = old.row ?: error("E_PATCH07_BIGINT_SCAR_MISSING")
                    check(calc(seed,wrong) == calc(seed,rows[ordinal]) &&
                        calc(seed,wrong) != expected) {
                        "E_PATCH07_BIGINT_SCAR_${seed}_${ordinal}"
                    }
                    redNumeric++
                }
                green++
            }
        }
        check(green == 66 && redNumeric == 60 && redUndefined == 6) {
            "E_PATCH07_BIGINT_COUNTS"
        }
        println("STAGE15_BIGINT_CORRECTED_GREEN_66")
        println("STAGE15_BIGINT_LEGACY_NUMERIC_RED_60")
        println("STAGE15_BIGINT_LEGACY_UNDEFINED_6")
    }
}
