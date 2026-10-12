package pastafari
import java.math.BigInteger

/** Cam 22: 6 × 720 tyst BigInteger heb oracl cynhyrchu. */
object Stage22BigIntegerTests {
    private val m=BigInteger("170141183460469231731687303715884105727")
    private val one=BigInteger.ONE
    private fun save(x:BigInteger)=(x-one).mod(m)+one
    private fun order(x:BigInteger):List<Int>{
        var rank=(x-one).mod(BigInteger.valueOf(720L)).toInt()
        val available=mutableListOf(1,2,3,4,5,6)
        val result=ArrayList<Int>()
        for(length in 6 downTo 1){
            var block=1
            for(k in 2 until length)block*=k
            val index=rank/block
            rank%=block
            result.add(available.removeAt(index))
        }
        return result
    }
    private fun sum(old:List<BigInteger>,stir:Int):BigInteger =
        save(old.drop(1).fold(BigInteger.ZERO){a,b->a+b}+
            BigInteger.valueOf(149L*stir))
    private fun step(old:List<BigInteger>,stir:Int,cached:BigInteger):
        Pair<List<Int>,List<BigInteger>> {
        val ord=order(cached)
        val out=MutableList(7){BigInteger.ZERO}
        for(p in 1..6){
            val id=ord[p-1]
            val prev=ord[if(p==1)5 else p-2]
            val next=ord[if(p==6)0 else p]
            val s=old[id]+old[prev]*BigInteger.valueOf(3L)+
                old[next]*BigInteger.valueOf(5L)+cached+
                BigInteger.valueOf((stir+p*p).toLong())
            out[id]=save(s*s+old[prev]*old[next]*BigInteger.valueOf(7L))
        }
        return ord to out.toList()
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY11_BIGINT_ARGS"}
        val starts=listOf("0","-720","720",
            "123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val adapter=LegacyCachedStirAdapter()
        var first=0;var second=0;var finalRed=0;var checks=0
        for(base in starts)for(n in 1..720){
            val value=base+BigInteger.valueOf(n.toLong())
            val bowls=mutableListOf(BigInteger.ZERO)
            for(id in 1..6)bowls.add(
                BigInteger.valueOf(101L*id*id)+
                    value*BigInteger.valueOf(id.toLong()))
            val initial=bowls.toList()
            val result=adapter.oldCachedPostStir12(
                initial.map{ExactInt.parse(it.toString())})
            check(result.steps.size==12 &&
                result.cachedSumComputations==1 &&
                result.permutationPatchCalls==12){
                "E_DISCOVERY11_BIGINT_SHAPE"
            }
            var stale=initial;var fresh=initial
            val frozen=sum(initial,1)
            check(result.originalCachedSum.toString()==frozen.toString())
            for(stir in 1..12){
                val wrong=step(stale,stir,frozen)
                val liveSum=sum(fresh,stir)
                val correct=step(fresh,stir,liveSum)
                val record=result.steps[stir-1]
                check(record.stir==stir &&
                    record.savedSumUsed.toString()==frozen.toString() &&
                    record.correctedPermutationOrder==wrong.first &&
                    record.oldSnapshot.map{it.toString()}==
                        stale.map{it.toString()} &&
                    record.newBowls.map{it.toString()}==
                        wrong.second.map{it.toString()}){
                    "E_DISCOVERY11_BIGINT_STALE_${n}_${stir}"
                }
                if(stir==1){
                    check(wrong.second==correct.second)
                    first++
                }
                if(stir==2){
                    check(wrong.second!=correct.second && frozen!=liveSum)
                    second++
                }
                stale=wrong.second;fresh=correct.second;checks++
            }
            check(stale!=fresh && result.finalBowls.map{it.toString()}==
                stale.map{it.toString()})
            finalRed++
        }
        check(first==4320 && second==4320 &&
            finalRed==4320 && checks==51840)
        println("STAGE22_BIGINT_FIRST_GREEN_4320")
        println("STAGE22_BIGINT_SECOND_RED_4320")
        println("STAGE22_BIGINT_FINAL_RED_4320")
        println("STAGE22_BIGINT_STALE_STEPS_51840")
    }
}
