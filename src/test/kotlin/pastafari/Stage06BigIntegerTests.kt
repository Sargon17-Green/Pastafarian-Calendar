package pastafari

import java.math.BigInteger
import java.util.Random

/** Oracl annibynnol yn y profion yn unig; dim java.math yn y llwybr cynhyrchu. */
object Stage06BigIntegerTests {
    private val one = BigInteger.ONE
    private val two = BigInteger.valueOf(2L)
    private val foundation = BigInteger.valueOf(-15055671L)

    private fun tag(day: BigInteger): BigInteger =
        day.subtract(foundation).abs().multiply(two).add(if (day >= foundation) one else BigInteger.ZERO)

    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY03_BIGINT_ARGUMENTS" }
        val manager = MonsterBootstrapManager()
        val random = Random(0x6D206BL)
        val magnitudes = mutableListOf<BigInteger>(BigInteger.ZERO, one, two,
            BigInteger.valueOf(3L), BigInteger.valueOf(127L),
            BigInteger.ONE.shiftLeft(127).subtract(one),
            BigInteger.ONE.shiftLeft(127), BigInteger.ONE.shiftLeft(127).add(one),
            BigInteger.ONE.shiftLeft(512), BigInteger.ONE.shiftLeft(1024),
            BigInteger.ONE.shiftLeft(2048))
        repeat(128) { magnitudes.add(BigInteger(1 + random.nextInt(2048), random)) }
        var tested = 0
        var observedRed = 0
        var matches = 0
        val inputs = mutableListOf<Pair<BigInteger, BigInteger>>()
        for (offset in -64..64) {
            val n = BigInteger.valueOf(offset.toLong())
            inputs.add(foundation.subtract(n) to foundation.add(n))
        }
        for (magnitude in magnitudes) {
            inputs.add(foundation.subtract(magnitude) to foundation.add(magnitude))
            inputs.add(foundation.add(magnitude) to foundation.subtract(magnitude))
            inputs.add(foundation.add(magnitude) to foundation.add(magnitude))
        }
        // Tri rheolydd MATCH penodol ochr-ochr (nid yw pob pâr yn goch).
        inputs.add(foundation.subtract(two) to foundation.subtract(one))
        inputs.add(foundation.add(one) to foundation.add(two))
        inputs.add(foundation.subtract(BigInteger.valueOf(3L)) to foundation.subtract(two))
        for ((c, t) in inputs) {
            val expected = tag(c).subtract(tag(t)).abs()
            val normative = t.subtract(c).abs().add(one)
            val result = manager.observeLegacyDistance(ExactInt.parse(c.toString()), ExactInt.parse(t.toString()))
            check(result.discovery03Output?.toString() == expected.toString()) { "E_DISCOVERY03_BIGINT_${tested}" }
            if (expected == normative) matches++ else observedRed++
            check(result.calculationDay.toString() == c.toString() && result.targetDay.toString() == t.toString())
            tested++
        }
        check(tested == 549) { "E_DISCOVERY03_BIGINT_COUNT_${tested}" }
        check(observedRed > 0 && matches > 0) { "E_DISCOVERY03_BIGINT_CLASSIFICATION" }
        check(manager.metrics.snapshot()["discovery03.legacy"] == tested.toLong())
        println("STAGE06_BIGINT_INDEPENDENT_PASS_549")
        println("STAGE06_BIGINT_EXPECTED_RED_${observedRed}_MATCH_${matches}")
    }
}
