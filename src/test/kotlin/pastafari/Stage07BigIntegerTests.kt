package pastafari

import java.math.BigInteger
import java.util.Random

/** Cyfeirnod BigInteger annibynnol yn y profion yn unig, nid mewn cynhyrchu. */
object Stage07BigIntegerTests {
    private val one = BigInteger.ONE
    private val two = BigInteger.valueOf(2L)
    private val foundation = BigInteger.valueOf(-15055671L)

    private fun tag(day: BigInteger): BigInteger =
        day.subtract(foundation).abs().multiply(two).add(if (day >= foundation) one else BigInteger.ZERO)

    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH03_BIGINT_ARGUMENTS" }
        val random = Random(0x6D206BL)
        val magnitudes = mutableListOf<BigInteger>(BigInteger.ZERO, one, two,
            BigInteger.valueOf(3L), BigInteger.valueOf(127L),
            BigInteger.ONE.shiftLeft(127).subtract(one),
            BigInteger.ONE.shiftLeft(127), BigInteger.ONE.shiftLeft(127).add(one),
            BigInteger.ONE.shiftLeft(512), BigInteger.ONE.shiftLeft(1024),
            BigInteger.ONE.shiftLeft(2048))
        repeat(128) { magnitudes.add(BigInteger(1 + random.nextInt(2048), random)) }
        val inputs = mutableListOf<Pair<BigInteger, BigInteger>>()
        for (offset in -64..64) {
            val n = BigInteger.valueOf(offset.toLong())
            inputs.add(foundation.subtract(n) to foundation.add(n))
        }
        for (m in magnitudes) {
            inputs.add(foundation.subtract(m) to foundation.add(m))
            inputs.add(foundation.add(m) to foundation.subtract(m))
            inputs.add(foundation.add(m) to foundation.add(m))
        }
        inputs.add(foundation.subtract(two) to foundation.subtract(one))
        inputs.add(foundation.add(one) to foundation.add(two))
        inputs.add(foundation.subtract(BigInteger.valueOf(3L)) to foundation.subtract(two))

        var replaced = 0L
        var legacyRed = 0L
        val manager = MonsterBootstrapManager()
        for ((index, pair) in inputs.withIndex()) {
            val (c, t) = pair
            val legacy = tag(c).subtract(tag(t)).abs()
            val chronology = t.subtract(c).abs()
            val answer = chronology.add(one)
            val x = manager.applyDistancePatch(ExactInt.parse(c.toString()), ExactInt.parse(t.toString()))
            check(x.patch03Output?.toString() == answer.toString()) { "E_PATCH03_BIGINT_OUTPUT_$index" }
            check(x.patch03LegacyOutput?.toString() == legacy.toString()) { "E_PATCH03_BIGINT_LEGACY_$index" }
            check(x.patch03SelectedBase?.toString() == chronology.toString()) { "E_PATCH03_BIGINT_BASE_$index" }
            check(x.patch03ChronologicalBase?.toString() == chronology.toString()) { "E_PATCH03_BIGINT_CHRONOLOGY_$index" }
            check(x.patch03ReplacementApplied == (legacy != chronology)) { "E_PATCH03_BIGINT_REPLACED_$index" }
            check(x.branchTrace == listOf("BOOT", "PATCH_03") && x.discovery03Output == null) {
                "E_PATCH03_BIGINT_CONTEXT_$index"
            }
            if (legacy != chronology) replaced++
            if (legacy != answer) legacyRed++
        }
        check(inputs.size == 549) { "E_PATCH03_BIGINT_COUNT_${inputs.size}" }
        check(legacyRed == 546L) { "E_PATCH03_BIGINT_OLD_RED_$legacyRed" }
        check(manager.metrics.snapshot()["patch03.legacy.calls"] == 549L)
        check(manager.metrics.snapshot()["patch03.applied"] == 549L)
        check(manager.metrics.snapshot()["patch03.replaced"] == replaced)
        println("STAGE07_BIGINT_INDEPENDENT_GREEN_549")
        println("STAGE07_BIGINT_PRESERVED_LEGACY_RED_546")
    }
}
