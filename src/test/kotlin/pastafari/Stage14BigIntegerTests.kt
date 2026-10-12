package pastafari

import java.math.BigInteger

/**
 * Cam 14: gwirio'r tablau rhifol yn annibynnol â BigInteger.
 * Nid yw'r prawf hwn yn adeiladu diferion gweledig Cam 16.
 */
object Stage14BigIntegerTests {
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
    private fun grind(n: BigInteger, row: IntArray): BigInteger {
        val p1=b(3); val p3=b(5); val p7=b(7)
        return save(n*n + n*b(row[0]) + p1*b(row[1]) +
            p3*b(row[2]) + p7*b(row[3]) + stones[row[4]])
    }
    private fun grind(n: BigInteger, row: VisibleGrindRow): BigInteger =
        save(n*n + n*b(row.a) + b(3)*b(row.b) +
            b(5)*b(row.c) + b(7)*b(row.d) + stones[row.stoneKind])

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY07_BIGINT_ARGS" }
        val adapter = LegacyGrindTableAdapter()
        val seeds = listOf(
            "1", "2", "17", "88", "123456789",
            "98765432109876543210987654321098765432109876543210"
        ).map(::BigInteger)
        var red = 0
        var numeric = 0
        var undefined = 0
        for (seed in seeds) {
            for (ordinal in 1..11) {
                val raw = adapter.legacyGrindRow(ordinal)
                val expected = grind(seed, rows[ordinal - 1])
                if (ordinal == 11) {
                    check(raw.row == null && raw.undefined) {
                        "E_DISCOVERY07_BIGINT_UNDEFINED"
                    }
                    undefined++
                } else {
                    val physical = raw.row ?: error("E_DISCOVERY07_BIGINT_RAW_MISSING")
                    val got = grind(seed, physical)
                    check(got == grind(seed, rows[ordinal]) && got != expected) {
                        "E_DISCOVERY07_BIGINT_SHIFT_${seed}_${ordinal}"
                    }
                    numeric++
                }
                red++
            }
        }
        check(numeric == 60 && undefined == 6 && red == 66) {
            "E_DISCOVERY07_BIGINT_CARDINALITY"
        }
        println("STAGE14_BIGINT_INDEPENDENT_RED_66")
        println("STAGE14_BIGINT_SHIFTED_NUMERIC_60")
        println("STAGE14_BIGINT_UNDEFINED_6")
    }
}
