package pastafari

import java.math.BigInteger
import java.util.Random

/**
 * Archwiliad annibynnol Cam 4: defnyddir BigInteger yn y prawf JVM yn unig.
 * Nid yw LegacyDayTagAdapter na'r cod cynhyrchu yn dibynnu ar BigInteger.
 * Nid yw'r prawf hwn yn ychwanegu PATCH 02 nac yn newid cyfrif y pum tyst.
 */
object Stage04BigIntegerTests {
    private fun requireCheck(code: String, condition: Boolean) {
        check(condition) { code }
    }

    @JvmStatic
    fun main(args: Array<String>) {
        requireCheck("E_DISCOVERY02_BIGINT_ARGUMENTS", args.isEmpty())
        val foundation = BigInteger.valueOf(-15055671L)
        val modulus = BigInteger("170141183460469231731687303715884105727")
        requireCheck("E_DISCOVERY02_BIGINT_FOUNDATION",
            NormativeCore.FOUNDATION_DAY.toString() == foundation.toString())
        requireCheck("E_DISCOVERY02_BIGINT_MODULUS",
            NormativeCore.M.toString() == modulus.toString())

        val anchors = listOf(
            modulus.subtract(BigInteger.ONE),
            modulus,
            modulus.add(BigInteger.ONE),
            modulus.multiply(BigInteger.valueOf(2)),
            modulus.multiply(BigInteger.valueOf(3)),
            BigInteger.ONE.shiftLeft(31),
            BigInteger.ONE.shiftLeft(63),
            BigInteger.ONE.shiftLeft(127),
            BigInteger.ONE.shiftLeft(255),
            BigInteger.ONE.shiftLeft(511),
            BigInteger.ONE.shiftLeft(1023),
            BigInteger.ONE.shiftLeft(2047)
        )
        val random = Random(0x31415926L)
        val generated = (0 until 192).map { i ->
            val bits = 1 + (i * 53 % 2048)
            BigInteger(bits, random).add(BigInteger.ONE)
        }
        val magnitudes = anchors + generated
        val manager = MonsterBootstrapManager()
        val calculationDay = ExactInt.parse(foundation.subtract(BigInteger.valueOf(119)).toString())
        val targetDay = ExactInt.parse(foundation.add(BigInteger.valueOf(211)).toString())
        var cases = 0
        var differences = 0
        var matches = 0
        var firstContext: BaseMonsterContext? = null

        fun verify(day: BigInteger) {
            val input = ExactInt.parse(day.toString())
            val expectedOld = day.subtract(foundation).abs().shiftLeft(1)
            val expectedNormative = if (day >= foundation) {
                expectedOld.add(BigInteger.ONE)
            } else {
                expectedOld
            }
            val result = manager.observeLegacyDayTag(calculationDay, targetDay, input)
            val actual = result.discovery02Output ?: error("E_DISCOVERY02_BIGINT_NULL_$cases")
            requireCheck("E_DISCOVERY02_BIGINT_OLD_$cases",
                BigInteger(actual.toString()) == expectedOld)
            requireCheck("E_DISCOVERY02_BIGINT_ORACLE_$cases",
                BigInteger(NormativeCore.dayCount(input).toString()) == expectedNormative)
            requireCheck("E_DISCOVERY02_BIGINT_ADAPTER_$cases",
                BigInteger(manager.legacyDayTagAdapter.oldDayTag(input).toString()) == expectedOld)
            requireCheck("E_DISCOVERY02_BIGINT_ROUTE_$cases",
                result.discovery02Input == input &&
                result.calculationDay == calculationDay && result.targetDay == targetDay &&
                result.phase == "DISCOVERY_02" && result.status == "LEGACY_DAY_TAG_OBSERVED" &&
                result.branchTrace == listOf("BOOT", "DISCOVERY_02") &&
                result.diagnostics == listOf("DISCOVERY_02_LEGACY_DAY_TAG") &&
                result.discovery01Input == null && result.patch01Input == null)
            if (actual.toString() == expectedNormative.toString()) {
                matches++
            } else {
                differences++
            }
            if (cases == 0) firstContext = result
            cases++
        }

        verify(foundation)
        for (magnitude in magnitudes) {
            verify(foundation.subtract(magnitude))
            verify(foundation.add(magnitude))
        }
        requireCheck("E_DISCOVERY02_BIGINT_COUNTS",
            cases == 409 && differences == 205 && matches == 204)
        requireCheck("E_DISCOVERY02_BIGINT_METRICS",
            manager.metrics.snapshot()["bootstrap.ready"] == cases.toLong() &&
            manager.metrics.snapshot()["discovery02.legacy"] == cases.toLong() &&
            manager.metrics.snapshot().size == 2)
        val first = firstContext ?: error("E_DISCOVERY02_BIGINT_NO_FIRST")
        requireCheck("E_DISCOVERY02_BIGINT_CONTEXT_IMMUTABILITY",
            first.discovery02Input == ExactInt.parse(foundation.toString()) &&
            first.discovery02Output == ExactInt.ZERO &&
            first.branchTrace == listOf("BOOT", "DISCOVERY_02") &&
            first.diagnostics == listOf("DISCOVERY_02_LEGACY_DAY_TAG"))
        println("STAGE04_BIGINT_INDEPENDENT_PASS_$cases")
        println("STAGE04_BIGINT_RED_${differences}_MATCH_${matches}")
    }
}
