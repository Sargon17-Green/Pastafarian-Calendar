package pastafari

import java.math.BigInteger

/** Oracl rhifyddol annibynnol: nid yw'n galw NormativeCore i gyfrifo. */
object Stage09BigIntegerTests {
    private val m = BigInteger("170141183460469231731687303715884105727")
    private val one = BigInteger.ONE
    private fun save(x: BigInteger) = x.subtract(one).mod(m).add(one)
    private fun big(x: ExactInt) = BigInteger(x.toString())

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH04_BIGINT_ARGUMENTS" }
        val ctx = MonsterBootstrapManager().applyStonePatch(ExactInt.ZERO, ExactInt.ONE)
        val rows = ctx.patch04StoneRows ?: error("E_PATCH04_BIGINT_NO_ROWS")
        val garbage = ctx.patch04LegacyGarbageRows ?: error("E_PATCH04_BIGINT_NO_GARBAGE")
        val expected = Array(47) { Array(5) { BigInteger.ZERO } }
        val initial = listOf(17L, 29L, 43L, 71L, 101L).map(BigInteger::valueOf)
        for (k in 0..4) expected[1][k] = initial[k]
        var verified = 0
        var garbageRed = 0
        for (i in 1..46) {
            if (i >= 2) {
                val p = expected[i-1]
                expected[i] = arrayOf(
                    save(p[0]*p[0] + p[1]*BigInteger.valueOf(3) + BigInteger.valueOf(i.toLong())),
                    save(p[1]*p[1] + p[2]*BigInteger.valueOf(5) + p[0]),
                    save(p[2]*p[2] + p[3]*BigInteger.valueOf(7) + p[1]),
                    save(p[3]*p[3] + p[4]*BigInteger.valueOf(11) + p[2]),
                    save(p[4]*p[4] + p[0]*BigInteger.valueOf(13) + p[3])
                )
                val g = p.copyOf()
                g[0] = save(g[0]*g[0] + g[1]*BigInteger.valueOf(3) + BigInteger.valueOf(i.toLong()))
                g[1] = save(g[1]*g[1] + g[2]*BigInteger.valueOf(5) + g[0])
                g[2] = save(g[2]*g[2] + g[3]*BigInteger.valueOf(7) + g[1])
                g[3] = save(g[3]*g[3] + g[4]*BigInteger.valueOf(11) + g[2])
                g[4] = save(g[4]*g[4] + g[0]*BigInteger.valueOf(13) + g[3])
                for (k in 0..4) {
                    check(big(garbage[i].components()[k]) == g[k]) { "E_PATCH04_BIGINT_GARBAGE_${i}_${k}" }
                }
            }
            for (k in 0..4) {
                check(big(rows[i].components()[k]) == expected[i][k]) { "E_PATCH04_BIGINT_PATCH_${i}_${k}" }
                if (i >= 2 && big(garbage[i].components()[k]) != expected[i][k]) garbageRed++
                verified++
            }
        }
        check(verified == 230 && garbageRed > 0) { "E_PATCH04_BIGINT_COUNTS" }
        println("STAGE09_BIGINT_INDEPENDENT_GREEN_230")
        println("STAGE09_BIGINT_GARBAGE_CAPTURE_PASS")
    }
}
