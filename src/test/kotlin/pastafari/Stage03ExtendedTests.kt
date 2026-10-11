package pastafari

import java.math.BigInteger
import java.util.Random
import java.util.IdentityHashMap
import java.util.Collections

/**
 * Cam 3 — archwiliad annibynnol: BigInteger fel meincnod PRAWF yn unig.
 * Nid yw'r dosbarth hwn na java.math.BigInteger yn rhan o'r cod cynhyrchu.
 */
object Stage03ExtendedTests {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH01_EXT_ARGUMENTS" }
        val random = Random(0x50A57AFA1234L)
        val m = BigInteger("170141183460469231731687303715884105727")
        val manager = MonsterBootstrapManager()
        val witnesses = mutableListOf<BigInteger>()
        val delta = listOf(-2L, -1L, 0L, 1L, 2L).map { BigInteger.valueOf(it) }
        for (k in -40..40) {
            for (d in delta) witnesses.add(m.multiply(BigInteger.valueOf(k.toLong())).add(d))
        }
        for (bits in intArrayOf(1, 31, 63, 64, 127, 128, 256, 512, 1024, 2048)) {
            repeat(48) {
                val magnitude = BigInteger(bits, random)
                witnesses.add(if (random.nextBoolean()) magnitude else magnitude.negate())
            }
        }
        for (shift in intArrayOf(32, 63, 64, 127, 128, 256, 512, 1024, 2048)) {
            val power = BigInteger.ONE.shiftLeft(shift)
            witnesses.addAll(listOf(power, power.negate(), power.add(m), power.negate().subtract(m)))
        }
        val recorded = Collections.newSetFromMap(IdentityHashMap<BaseMonsterContext, Boolean>())
        for ((index, x) in witnesses.withIndex()) {
            val input = ExactInt.parse(x.toString())
            val context = manager.applySavePatch(ExactInt.of(-15055671), ExactInt.of(20261011), input)
            val expectedLegacy = x.mod(m)
            val expectedPatched = x.subtract(BigInteger.ONE).mod(m).add(BigInteger.ONE)
            check(context.patch01LegacyOutput?.toString() == expectedLegacy.toString()) {
                "E_EXT_LEGACY_$index"
            }
            check(context.patch01Output?.toString() == expectedPatched.toString()) {
                "E_EXT_PATCHED_$index"
            }
            check(context.patch01Input == input && context.status == "PATCHED" &&
                context.branchTrace == listOf("BOOT", "PATCH_01") &&
                context.diagnostics == listOf("PATCH_01_SAVE_WRAPPER")) {
                "E_EXT_CONTEXT_$index"
            }
            check(context.discovery01Input == null && context.discovery01Output == null) {
                "E_EXT_DISCOVERY_CONTAMINATION_$index"
            }
            check(recorded.add(context)) {
                "E_EXT_CONTEXT_IDENTITY_$index"
            }
        }
        val count = witnesses.size.toLong()
        check(manager.metrics.snapshot()["bootstrap.ready"] == count &&
            manager.metrics.snapshot()["patch01.legacy.calls"] == count &&
            manager.metrics.snapshot()["patch01.applied"] == count &&
            manager.metrics.snapshot().getOrDefault("discovery01.legacy", 0L) == 0L) {
            "E_EXT_METRICS"
        }
        println("STAGE03_EXTENDED_BIGINT_GREEN_${witnesses.size}")
    }
}
