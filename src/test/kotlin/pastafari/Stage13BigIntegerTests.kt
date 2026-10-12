package pastafari

import java.math.BigInteger

/** Oracl prawf annibynnol: nid yw gwerth disgwyliedig yn defnyddio ExactInt. */
object Stage13BigIntegerTests {
    private val m = BigInteger("170141183460469231731687303715884105727")
    private val one = BigInteger.ONE
    private val two = BigInteger.valueOf(2)
    private val foundation = BigInteger.valueOf(-15055671)
    private fun n(v: Int) = BigInteger.valueOf(v.toLong())
    private fun save(x: BigInteger) = x.subtract(one).mod(m).add(one)
    private val coeff = arrayOf(
        intArrayOf(0,0,0,0), intArrayOf(3,4,6,8),
        intArrayOf(5,7,10,12), intArrayOf(7,10,14,16),
        intArrayOf(9,13,18,20), intArrayOf(11,16,22,24),
        intArrayOf(13,19,26,28), intArrayOf(15,22,30,32)
    )
    private val grindStone = intArrayOf(0,1,2,3,4,0,1)
    private fun tag(day: BigInteger): BigInteger = if (day < foundation) {
        foundation.subtract(day).multiply(two)
    } else {
        day.subtract(foundation).multiply(two).add(one)
    }

    private fun independentStones(): Array<Array<BigInteger>> {
        val s=Array(8) { Array(5) { BigInteger.ZERO } }
        s[1] = arrayOf(n(17),n(29),n(43),n(71),n(101))
        for (i in 2..7) {
            val old=s[i-1]
            s[i]=arrayOf(
                save(old[0]*old[0]+old[1]*n(3)+n(i)),
                save(old[1]*old[1]+old[2]*n(5)+old[0]),
                save(old[2]*old[2]+old[3]*n(7)+old[1]),
                save(old[3]*old[3]+old[4]*n(11)+old[2]),
                save(old[4]*old[4]+old[0]*n(13)+old[3])
            )
        }
        return s
    }

    private fun compute(c: BigInteger,t: BigInteger,s:Array<Array<BigInteger>>):Array<BigInteger> {
        val a=tag(c);val b=tag(t)
        val distance=t.subtract(c).abs().add(one)
        val connection=a+b
        val direction=n(if (t<c) 1 else if (t==c) 2 else 3)
        val counts=arrayOf(a,b,distance,connection,direction)
        val values=Array(8){BigInteger.ZERO}
        for(k in 1..7){
            val v=coeff[k]
            var x=counts[0]+counts[1]*n(v[0])+counts[2]*n(v[1])+
                counts[3]*n(v[2])+counts[4]*n(v[3])
            for(z in s[k])x+=z
            x=save(x)
            for(j in 1..7)x=save(x*x + x*n(3)+s[k][grindStone[j-1]]+n(j))
            values[k]=x
        }
        return values
    }

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){ "E_DISCOVERY05_BIGINT_ARGUMENTS" }
        val manager=MonsterBootstrapManager()
        val stone=independentStones()
        val pairs=listOf(
            0L to 0L, -10L to 11L, 34L to -19L, -90001L to -90001L,
            123456789L to -987654321L
        )
        var checked=0
        var missingHistoryRed=0
        var positiveGreen=0
        var hiddenGreen=0
        for ((deltaC,deltaT) in pairs){
            val c=foundation+BigInteger.valueOf(deltaC)
            val t=foundation+BigInteger.valueOf(deltaT)
            val expected=compute(c,t,stone)
            val visible=manager.applyPriorPatch(ExactInt.parse(c.toString()),ExactInt.parse(t.toString()))
            check(visible.patch06Output != null && BigInteger(visible.patch06Output.toString())==expected[1] &&
                visible.patch06LegacyPriorCalled == true && visible.patch06HiddenK == null &&
                visible.patch06Slot == 1) { "E_PATCH06_BIGINT_VISIBLE_${deltaC}_${deltaT}" }
            positiveGreen++
            val context=manager.observeLegacyHiddenDrop(ExactInt.parse(c.toString()),ExactInt.parse(t.toString()))
            val backward=context.discovery05BackwardStorage ?: error("E_DISCOVERY05_BIGINT_STORAGE")
            val patched=context.discovery05PatchedStoneRows ?: error("E_DISCOVERY05_BIGINT_STONES")
            for (k in 1..7){
                check(BigInteger(backward[8-k].toString())==expected[k]){
                    "E_DISCOVERY05_BIGINT_${deltaC}_${deltaT}_${k}"
                }
                for (kind in 0..4) check(BigInteger(patched[k].components()[kind].toString())==stone[k][kind]){
                    "E_DISCOVERY05_BIGINT_STONE_${k}_${kind}"
                }
                val repaired=manager.applyHiddenNearnessPatch(
                    ExactInt.parse(c.toString()), ExactInt.parse(t.toString()), k)
                val corrected=repaired.patch05CorrectedValue ?: error("E_PATCH05_BIGINT_NO_PATCH")
                val raw=repaired.patch05LegacyDirectValue ?: error("E_PATCH05_BIGINT_NO_LEGACY")
                check(BigInteger(corrected.toString())==expected[k]) {
                    "E_PATCH05_BIGINT_CORRECTED_${deltaC}_${deltaT}_${k}"
                }
                check(BigInteger(raw.toString())==expected[8-k] &&
                    repaired.patch05PhysicalSlot == 8-k &&
                    repaired.patch05Applied &&
                    repaired.patch05RequestedK == k) {
                    "E_PATCH05_BIGINT_LEGACY_${deltaC}_${deltaT}_${k}"
                }
                if (k == 1 || k == 3 || k == 7) {
                    val broken=manager.observeLegacyPrior(
                        ExactInt.parse(c.toString()), ExactInt.parse(t.toString()), 1, k)
                    check(broken.discovery06PriorSlot == 1-k &&
                        broken.discovery06PriorValue == null &&
                        broken.discovery06ErrorId == "E_DISCOVERY06_MISSING_HIDDEN_HISTORY" &&
                        broken.discovery06Patch05HiddenOne != null) {
                        "E_DISCOVERY06_BIGINT_MISSING_${deltaC}_${deltaT}_${k}"
                    }
                    check(BigInteger(corrected.toString()) == expected[k]) {
                        "E_DISCOVERY06_BIGINT_EXPECTED_${deltaC}_${deltaT}_${k}"
                    }
                    missingHistoryRed++
                }
                val patched=manager.applyPriorPatch(
                    ExactInt.parse(c.toString()), ExactInt.parse(t.toString()), 1, k)
                val mapped=patched.patch06Output ?: error("E_PATCH06_BIGINT_NO_RESULT")
                check(BigInteger(mapped.toString())==expected[k] &&
                    patched.patch06Slot == 1-k && patched.patch06HiddenK == k &&
                    patched.patch06LegacyPriorCalled == false &&
                    patched.patch06Source == "HIDDEN_PATCH05") {
                    "E_PATCH06_BIGINT_HIDDEN_${deltaC}_${deltaT}_${k}"
                }
                hiddenGreen++
                checked++
            }
        }
        check(positiveGreen==5 && hiddenGreen==35) { "E_PATCH06_BIGINT_TOTALS" }
        check(missingHistoryRed==15) { "E_DISCOVERY06_BIGINT_RED_COUNT" }
        check(checked==35){"E_DISCOVERY05_BIGINT_CHECK_COUNT"}
        println("STAGE12_BIGINT_INDEPENDENT_GREEN_35")
        println("STAGE12_BIGINT_PATCH04_STONES_GREEN_175")
        println("STAGE13_BIGINT_VISIBLE_GREEN_5")
        println("STAGE13_BIGINT_HIDDEN_GREEN_35")
        println("STAGE13_BIGINT_STONES_GREEN_175")
        println("STAGE13_BIGINT_PRESERVED_DISCOVERY06_RED_15")
    }
}
