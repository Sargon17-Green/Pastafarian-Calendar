package pastafari

import java.math.BigInteger

/** Oracl cyfrifiadurol annibynnol: BigInteger yw prawf yn unig. */
object Stage05BigIntegerTests {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty())
        val foundation = BigInteger.valueOf(-15055671L)
        val two = BigInteger.valueOf(2)
        val modulus = BigInteger("170141183460469231731687303715884105727")
        val magnitudes = mutableListOf(BigInteger.ZERO, BigInteger.ONE, two, modulus,
            modulus.subtract(BigInteger.ONE), modulus.add(BigInteger.ONE),
            modulus.multiply(two), modulus.multiply(BigInteger.valueOf(3)), modulus.pow(2))
        // 200 gwerth terfynol annibynnol: hyd at 2,048 did, gan gynnwys seroau.
        for (i in 1..200) {
            val bitCount = 1 + ((i * 83) % 2048)
            val magnitude = BigInteger.ONE.shiftLeft(bitCount).add(BigInteger.valueOf((i * 971).toLong()))
            magnitudes.add(magnitude)
        }
        val manager = MonsterBootstrapManager()
        var checked = 0
        for (magnitude in magnitudes) {
            for (positive in listOf(false, true)) {
                val day = if (positive) foundation.add(magnitude) else foundation.subtract(magnitude)
                val dayExact = ExactInt.parse(day.toString())
                val legacy = magnitude.multiply(two)
                val expected = legacy.add(if (day >= foundation) BigInteger.ONE else BigInteger.ZERO)
                val c = manager.applyDayTagPatch(ExactInt.of(-4), ExactInt.of(7), dayExact)
                check(c.patch02LegacyOutput.toString() == legacy.toString()) { "E_PATCH02_BIGINT_LEGACY_$checked" }
                check(c.patch02Output.toString() == expected.toString()) { "E_PATCH02_BIGINT_PATCH_$checked" }
                check(manager.legacyDayTagAdapter.oldDayTag(dayExact).toString() == legacy.toString()) {
                    "E_PATCH02_BIGINT_SCAR_$checked"
                }
                checked++
            }
        }
        check(checked == 418) { "E_PATCH02_BIGINT_COUNT" }
        check(manager.metrics.snapshot()["patch02.applied"] == checked.toLong()) {
            "E_PATCH02_BIGINT_METRICS"
        }
        println("STAGE05_BIGINT_INDEPENDENT_PASS_$checked")
    }
}
