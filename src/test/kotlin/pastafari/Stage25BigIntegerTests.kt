package pastafari

import java.math.BigInteger

/** Cam 25: 6 × 720 × 6 prawf BigInteger annibynnol. */
object Stage25BigIntegerTests {
    private val one=BigInteger.ONE
    private val modulus=BigInteger("170141183460469231731687303715884105727")
    private val orderMod=BigInteger.valueOf(720L)
    private fun save(x:BigInteger)=(x-one).mod(modulus)+one
    private fun unrank(x:BigInteger):List<Int> {
        var n=(x-one).mod(orderMod).toInt()
        val ids=mutableListOf(1,2,3,4,5,6)
        val result=ArrayList<Int>()
        for(size in 6 downTo 1){
            var factorial=1
            for(k in 2 until size)factorial*=k
            val idx=n/factorial
            n%=factorial
            result.add(ids.removeAt(idx))
        }
        return result
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_PATCH12_BIGINT_ARGS"}
        val bases=listOf("0","-720","720",
            "123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val patch=PositionalNeighborPatchWrapper()
        var green=0;var scarRed=0;var scarMatch=0;var cycles=0
        for((index,base)in bases.withIndex()){
            val seal=if(index%2==0)21 else 31
            val sealBig=BigInteger.valueOf(seal.toLong())
            val original=mutableListOf(BigInteger.ZERO)
            for(id in 1..6) original.add(
                base*BigInteger.valueOf((id+1).toLong())+
                    BigInteger.valueOf(101L*id*id+17L))
            val bowls=original.toList()
            val exact=bowls.map{ExactInt.parse(it.toString())}
            for(n in 1..720){
                val drop=base+BigInteger.valueOf(n.toLong())
                val order=unrank(drop)
                var allMatch=true
                for(id in 1..6){
                    val numeric=if(id==6)1 else id+1
                    val next=order[(order.indexOf(id)+1)%6]
                    val outcome=patch.patch(
                        exact,ExactInt.parse(drop.toString()),id,seal)
                    val firstBase=bowls[id]+sealBig+BigInteger.valueOf(181L)
                    val correctFirst=save(firstBase*firstBase+
                        bowls[next]*BigInteger.valueOf(179L)+sealBig)
                    val wrongFirst=save(firstBase*firstBase+
                        bowls[numeric]*BigInteger.valueOf(179L)+sealBig)
                    val dirBase=correctFirst+sealBig+BigInteger.valueOf(194L)
                    val direction=save(dirBase*dirBase+
                        correctFirst*BigInteger.valueOf(193L)+
                        bowls[6]*BigInteger.valueOf(197L))
                    check(outcome.drop46.toString()==drop.toString() &&
                        outcome.drop46Order==order &&
                        outcome.correctedNeighborId==next &&
                        outcome.legacyRead.actualNeighborIdWrong==numeric &&
                        outcome.legacyRead.positionalNeighborIdExpected==next &&
                        outcome.correctedFirstAnswer.toString()==
                            correctFirst.toString() &&
                        outcome.correctedDirectionNumber.toString()==
                            direction.toString() &&
                        outcome.correctedDirectionStep==
                            (if(direction.testBit(0))1 else -1) &&
                        outcome.legacyRead.firstAnswer.toString()==
                            wrongFirst.toString() &&
                        outcome.legacyNumericNeighborCalls==1 &&
                        outcome.correctedNeighborCalls==1 &&
                        outcome.patchedPermutationCalls==1){
                        "E_PATCH12_BIGINT_FORMULA_${index}_${n}_${id}"
                    }
                    if(numeric==next){
                        check(wrongFirst==correctFirst)
                        scarMatch++
                    }else{
                        check(wrongFirst!=correctFirst)
                        scarRed++;allMatch=false
                    }
                    green++
                }
                if(allMatch)cycles++
            }
        }
        check(green==25920 && scarRed==20736 &&
            scarMatch==5184 && cycles==36){
            "E_PATCH12_BIGINT_CARDINALITY"
        }
        println("STAGE25_BIGINT_CORRECTED_GREEN_25920")
        println("STAGE25_BIGINT_PRESERVED_LEGACY_RED_20736")
        println("STAGE25_BIGINT_PRESERVED_MATCH_5184")
        println("STAGE25_BIGINT_PRESERVED_NUMERIC_CYCLES_36")
    }
}
