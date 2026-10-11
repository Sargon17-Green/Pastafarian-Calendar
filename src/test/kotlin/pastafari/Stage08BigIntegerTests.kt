package pastafari

import java.math.BigInteger

/** Cyfrifydd BigInteger annibynnol, dim defnyddio ExactInt i gyfrifo'r disgwyl. */
object Stage08BigIntegerTests {
    private val m = BigInteger("170141183460469231731687303715884105727")
    private val one = BigInteger.ONE
    private fun save(x: BigInteger) = x.subtract(one).mod(m).add(one)
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY04_BIGINT_ARGUMENTS" }
        val observed = MonsterBootstrapManager().observeLegacyStones(ExactInt.ZERO, ExactInt.ONE)
            .discovery04LegacyStoneRows ?: error("E_DISCOVERY04_BIGINT_MISSING")
        val snapshotNormative = Array(47) { Array(5) { BigInteger.ZERO } }
        val legacy = Array(47) { Array(5) { BigInteger.ZERO } }
        val seed = listOf(17L, 29L, 43L, 71L, 101L).map(BigInteger::valueOf)
        for (k in 0..4) { snapshotNormative[1][k] = seed[k]; legacy[1][k] = seed[k] }
        var independentlyChecked = 0
        var normRed = 0
        for (i in 1..46) {
            if (i >= 2) {
                val old = snapshotNormative[i-1]
                val sq: (Int)->BigInteger = { k -> old[k].multiply(old[k]) }
                snapshotNormative[i] = arrayOf(
                    save(sq(0) + old[1]*BigInteger.valueOf(3) + BigInteger.valueOf(i.toLong())),
                    save(sq(1) + old[2]*BigInteger.valueOf(5) + old[0]),
                    save(sq(2) + old[3]*BigInteger.valueOf(7) + old[1]),
                    save(sq(3) + old[4]*BigInteger.valueOf(11) + old[2]),
                    save(sq(4) + old[0]*BigInteger.valueOf(13) + old[3])
                )
                val v=legacy[i-1].copyOf()
                v[0]=save(v[0]*v[0] + BigInteger.valueOf(3)*v[1] + BigInteger.valueOf(i.toLong()))
                v[1]=save(v[1]*v[1] + BigInteger.valueOf(5)*v[2] + v[0])
                v[2]=save(v[2]*v[2] + BigInteger.valueOf(7)*v[3] + v[1])
                v[3]=save(v[3]*v[3] + BigInteger.valueOf(11)*v[4] + v[2])
                v[4]=save(v[4]*v[4] + BigInteger.valueOf(13)*v[0] + v[3])
                legacy[i]=v
            }
            for (k in 0..4) {
                val got=BigInteger(observed[i].components()[k].toString())
                check(got==legacy[i][k]) { "E_DISCOVERY04_BIGINT_${i}_${k}" }
                independentlyChecked++
                if (i>=2 && got!=snapshotNormative[i][k]) normRed++
            }
        }
        check(independentlyChecked==230 && normRed==224) {
            "E_DISCOVERY04_BIGINT_COUNTS_${independentlyChecked}_${normRed}" }
        println("STAGE08_BIGINT_INDEPENDENT_PASS_230")
        println("STAGE08_BIGINT_NORMATIVE_RED_224")
    }
}
