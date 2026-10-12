package pastafari

import java.math.BigInteger

/** Cam 24 — chwe chylch o 720 permutation × chwe bowl. */
object Stage24BigIntegerTests {
    private val one=BigInteger.ONE
    private val modulus=BigInteger("170141183460469231731687303715884105727")
    private val orderMod=BigInteger.valueOf(720L)
    private fun save(v:BigInteger)=(v-one).mod(modulus)+one
    private fun unrank(drop:BigInteger):List<Int> {
        var rank=(drop-one).mod(orderMod).toInt()
        val ids=mutableListOf(1,2,3,4,5,6)
        val out=ArrayList<Int>()
        for(n in 6 downTo 1){
            var factorial=1
            for(k in 2 until n)factorial*=k
            val i=rank/factorial
            rank%=factorial
            out.add(ids.removeAt(i))
        }
        return out
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY12_BIGINT_ARGS"}
        val bases=listOf("0","-720","720",
            "123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val adapter=LegacyNumericNeighborAdapter()
        var wrong=0;var coincident=0;var queries=0;var cyc=0
        for((i,base) in bases.withIndex()){
            val seal=if(i%2==0)21 else 31
            val sealBig=BigInteger.valueOf(seal.toLong())
            val final=mutableListOf(BigInteger.ZERO)
            for(id in 1..6) final.add(
                base*BigInteger.valueOf((id+1L))+
                BigInteger.valueOf((101L*id*id+17L)))
            val exact=final.map{ExactInt.parse(it.toString())}
            for(n in 1..720){
                val drop=base+BigInteger.valueOf(n.toLong())
                val order=unrank(drop)
                var allMatch=true
                for(id in 1..6){
                    val numeric=if(id==6)1 else id+1
                    val canonical=order[(order.indexOf(id)+1)%6]
                    val actual=adapter.oldNumericNeighborQuestion(
                        exact,ExactInt.parse(drop.toString()),id,seal)
                    val firstBase=final[id]+sealBig+BigInteger.valueOf(181L)
                    val badFirst=save(firstBase*firstBase+
                        final[numeric]*BigInteger.valueOf(179L)+sealBig)
                    val trueFirst=save(firstBase*firstBase+
                        final[canonical]*BigInteger.valueOf(179L)+sealBig)
                    val directionBase=badFirst+sealBig+
                        BigInteger.valueOf(194L)
                    val badDirection=save(directionBase*directionBase+
                        badFirst*BigInteger.valueOf(193L)+
                        final[6]*BigInteger.valueOf(197L))
                    check(actual.drop46.toString()==drop.toString() &&
                        actual.drop46Order==order &&
                        actual.queriedBowlId==id &&
                        actual.actualNeighborIdWrong==numeric &&
                        actual.positionalNeighborIdExpected==canonical &&
                        actual.firstAnswer.toString()==badFirst.toString() &&
                        actual.directionNumber.toString()==
                            badDirection.toString() &&
                        actual.directionStep==
                            (if(badDirection.testBit(0))1 else -1) &&
                        actual.permutationPatchCalls==1 &&
                        actual.numericNeighborCalls==1){
                        "E_DISCOVERY12_BIGINT_LEGACY_FORMULA_${i}_${n}_${id}"
                    }
                    if(numeric==canonical){
                        check(badFirst==trueFirst)
                        coincident++
                    }else{
                        check(badFirst!=trueFirst){
                            "E_DISCOVERY12_BIGINT_NUMERIC_RED_${i}_${n}_${id}"
                        }
                        wrong++;allMatch=false
                    }
                    queries++
                }
                if(allMatch)cyc++
            }
        }
        check(queries==25920 && wrong==20736 &&
            coincident==5184 && cyc==36){
            "E_DISCOVERY12_BIGINT_CARDINALITY"
        }
        println("STAGE24_BIGINT_QUERIES_25920")
        println("STAGE24_BIGINT_EXPECTED_RED_20736")
        println("STAGE24_BIGINT_INCIDENTAL_MATCH_5184")
        println("STAGE24_BIGINT_NUMERIC_CYCLES_36")
    }
}
