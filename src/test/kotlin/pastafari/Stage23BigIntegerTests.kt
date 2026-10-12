package pastafari

import java.math.BigInteger

/** Cam 23 — chwe chylch × 720, oracl BigInteger annibynnol. */
object Stage23BigIntegerTests {
    private val one=BigInteger.ONE
    private val m=BigInteger("170141183460469231731687303715884105727")
    private val orderMod=BigInteger.valueOf(720L)
    private fun saved(value:BigInteger)=(value-one).mod(m)+one
    private fun unrank(sum:BigInteger):List<Int>{
        var rank=(sum-one).mod(orderMod).toInt()
        val remaining=mutableListOf(1,2,3,4,5,6)
        val order=ArrayList<Int>()
        for(slots in 6 downTo 1){
            var fac=1
            for(k in 2 until slots)fac*=k
            val index=rank/fac
            rank%=fac
            order.add(remaining.removeAt(index))
        }
        return order
    }
    private fun sum(bowls:List<BigInteger>,stir:Int):BigInteger =
        saved(bowls.drop(1).fold(BigInteger.ZERO){a,b->a+b}+
            BigInteger.valueOf(149L*stir))
    private fun next(old:List<BigInteger>,stir:Int,savedSum:BigInteger):
        Pair<List<Int>,List<BigInteger>> {
        val order=unrank(savedSum)
        val bowls=MutableList(7){BigInteger.ZERO}
        for(p in 1..6){
            val id=order[p-1]
            val prev=order[if(p==1)5 else p-2]
            val following=order[if(p==6)0 else p]
            val mixed=old[id]+old[prev]*BigInteger.valueOf(3L)+
                old[following]*BigInteger.valueOf(5L)+savedSum+
                BigInteger.valueOf((stir+p*p).toLong())
            bowls[id]=saved(mixed*mixed+
                old[prev]*old[following]*BigInteger.valueOf(7L))
        }
        return order to bowls.toList()
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_PATCH11_BIGINT_ARGS"}
        val bases=listOf(
            "0","-720","720",
            "123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val patch=FreshStirPatchWrapper()
        var green=0;var legacyRed=0;var first=0
        var second=0;var allSteps=0
        for(base in bases)for(n in 1..720){
            val v=base+BigInteger.valueOf(n.toLong())
            val bowls=mutableListOf(BigInteger.ZERO)
            for(id in 1..6)bowls.add(
                BigInteger.valueOf(101L*id*id)+v*BigInteger.valueOf(id.toLong()))
            val initial=bowls.toList()
            val result=patch.patch(initial.map{ExactInt.parse(it.toString())})
            check(result.steps.size==12 &&
                result.legacyRun.steps.size==12 &&
                result.correctedSumComputations==12 &&
                result.legacyCacheComputations==1 &&
                result.correctedPermutationCalls==12 &&
                result.legacyPermutationCalls==12 &&
                result.legacyRuns==1){"E_PATCH11_BIGINT_SHAPE"}
            var current=initial
            var stale=initial
            val fixedSum=sum(stale,1)
            for(stir in 1..12){
                val currentSum=sum(current,stir)
                val (correctOrder,correctBowls)=next(current,stir,currentSum)
                val (_,badBowls)=next(stale,stir,fixedSum)
                val trace=result.steps[stir-1]
                val legacy=result.legacyRun.steps[stir-1]
                check(trace.stir==stir &&
                    trace.freshSavedSum.toString()==currentSum.toString() &&
                    trace.oldSnapshot.map{it.toString()}==
                        current.map{it.toString()} &&
                    trace.correctedPermutationOrder==correctOrder &&
                    trace.newBowls.map{it.toString()}==
                        correctBowls.map{it.toString()} &&
                    trace.permutationPatchCalls==1 &&
                    legacy.savedSumUsed.toString()==fixedSum.toString() &&
                    legacy.newBowls.map{it.toString()}==
                        badBowls.map{it.toString()}) {
                    "E_PATCH11_BIGINT_TRACE_${n}_${stir}"
                }
                if(stir==1){
                    check(correctBowls==badBowls)
                    first++
                }
                if(stir==2){
                    check(currentSum!=fixedSum && correctBowls!=badBowls)
                    second++
                }
                current=correctBowls;stale=badBowls
                allSteps++
            }
            check(result.finalBowls.map{it.toString()}==
                    current.map{it.toString()} &&
                result.legacyRun.finalBowls.map{it.toString()}==
                    stale.map{it.toString()} && current!=stale){
                "E_PATCH11_BIGINT_FINAL_${n}"
            }
            green++;legacyRed++
        }
        check(green==4320 && legacyRed==4320 &&
            first==4320 && second==4320 && allSteps==51840){
            "E_PATCH11_BIGINT_COUNTS"
        }
        println("STAGE23_BIGINT_FINAL_GREEN_4320")
        println("STAGE23_BIGINT_PRESERVED_LEGACY_RED_4320")
        println("STAGE23_BIGINT_FIRST_BOTH_GREEN_4320")
        println("STAGE23_BIGINT_SECOND_FRESH_GREEN_4320")
        println("STAGE23_BIGINT_INDEPENDENT_STEPS_51840")
    }
}
