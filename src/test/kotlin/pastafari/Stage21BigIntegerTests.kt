package pastafari

import java.math.BigInteger

/** Chwe chylch llawn × 720 gyda'r oracl BigInteger annibynnol. */
object Stage21BigIntegerTests {
    private val modulus=BigInteger("170141183460469231731687303715884105727")
    private val orderModulus=BigInteger.valueOf(720L)
    private val one=BigInteger.ONE
    private val old=listOf("0","101","211","307","401","503","607")
        .map(::BigInteger)
    private val stones=listOf("17","29","43","71","101").map(::BigInteger)
    private val stoneByPosition=intArrayOf(0,1,2,3,4,0)
    private fun saved(n:BigInteger):BigInteger=n.subtract(one).mod(modulus).add(one)

    private fun unrank(rank0:Int):List<Int> {
        require(rank0 in 0..719)
        var rank=rank0
        val available=mutableListOf(1,2,3,4,5,6)
        val out=ArrayList<Int>()
        for(size in 6 downTo 1){
            var block=1
            for(n in 2 until size)block*=n
            val index=rank/block
            rank%=block
            out.add(available.removeAt(index))
        }
        return out
    }

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_PATCH10_BIGINT_ARGS"}
        val seeds=listOf(
            "0","-720","720",
            "1234567890123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val oldExact=old.map{ExactInt.parse(it.toString())}
        val stone=MutableStoneRow(ExactInt.of(17L),ExactInt.of(29L),
            ExactInt.of(43L),ExactInt.of(71L),ExactInt.of(101L))
        val wrapper=BowlSnapshotPatchWrapper()
        var good=0
        var legacyRed=0
        var legacyFirstGreen=0
        var wrongWrites=0
        for(seed in seeds)for(offset in 1..720){
            val drop=seed.add(BigInteger.valueOf(offset.toLong()))
            val rank0=drop.subtract(one).mod(orderModulus).toInt()
            val order=unrank(rank0)
            val actual=wrapper.patch(ExactInt.parse(drop.toString()),1,oldExact,stone)
            val pour=MutableList(7){BigInteger.ZERO}
            for(p in 1..3){
                pour[p]=saved(drop*drop+
                    stones[p-1]*old[order[p-1]]+
                    BigInteger.valueOf((2*p+1).toLong()))
                check(actual.legacyStep.pourPatch.correctedPours[p].toString()==
                    pour[p].toString()){
                    "E_PATCH10_BIGINT_POUR_$drop-$p"
                }
            }
            val expected=MutableList(7){BigInteger.ZERO}
            val legacyLive=old.toMutableList()
            check(actual.legacyStep.pourPatch.order==order &&
                actual.legacyMutatorCalls==1 &&
                actual.correctedSnapshotCalls==1 &&
                actual.oldSnapshot==oldExact &&
                actual.legacyStep.writes.size==6 &&
                actual.correctedWrites.size==6){
                "E_PATCH10_BIGINT_SHAPE_$drop"
            }
            var wrong=false
            for(p in 1..6){
                val id=order[p-1]
                val prev=order[if(p==1)5 else p-2]
                val following=order[if(p==6)0 else p]
                val mixed=old[id]+old[prev]*BigInteger.valueOf(2)+
                    old[following]*BigInteger.valueOf(3)+pour[p]+drop+
                    stones[stoneByPosition[p-1]]
                expected[id]=saved(mixed*mixed+
                    old[prev]*old[following]*BigInteger.valueOf(5)+
                    BigInteger.valueOf(p.toLong()))
                val previousLive=legacyLive[prev]
                val nextLive=legacyLive[following]
                val badMixed=legacyLive[id]+previousLive*BigInteger.valueOf(2)+
                    nextLive*BigInteger.valueOf(3)+pour[p]+drop+
                    stones[stoneByPosition[p-1]]
                legacyLive[id]=saved(badMixed*badMixed+
                    previousLive*nextLive*BigInteger.valueOf(5)+
                    BigInteger.valueOf(p.toLong()))
                val correctedTrace=actual.correctedWrites[p-1]
                val scarTrace=actual.legacyStep.writes[p-1]
                check(correctedTrace.position==p &&
                    correctedTrace.bowlId==id &&
                    correctedTrace.previousId==prev &&
                    correctedTrace.nextId==following &&
                    correctedTrace.previousSnapshotRead.toString()==
                        old[prev].toString() &&
                    correctedTrace.nextSnapshotRead.toString()==
                        old[following].toString() &&
                    correctedTrace.newValue.toString()==
                        expected[id].toString() &&
                    actual.correctedBowls[id].toString()==
                        expected[id].toString() &&
                    scarTrace.previousLiveRead.toString()==
                        previousLive.toString() &&
                    scarTrace.nextLiveRead.toString()==
                        nextLive.toString() &&
                    scarTrace.newValue.toString()==legacyLive[id].toString()){
                    "E_PATCH10_BIGINT_WRITE_$drop-$p"
                }
                if(legacyLive[id]!=expected[id]){
                    check(p!=1){"E_PATCH10_BIGINT_FIRST_RED_$drop"}
                    wrong=true
                    wrongWrites++
                }else if(p==1){
                    legacyFirstGreen++
                }
            }
            check(actual.legacyStep.newBowls.map{it.toString()}==
                legacyLive.map{it.toString()}){
                "E_PATCH10_BIGINT_SCAR_$drop"
            }
            if(wrong)legacyRed++
            good++
        }
        check(good==4320 && legacyRed==4320 &&
            legacyFirstGreen==4320 && wrongWrites==21600){
            "E_PATCH10_BIGINT_CARDINALITY"
        }
        println("STAGE21_BIGINT_CORRECTED_GREEN_4320")
        println("STAGE21_BIGINT_PRESERVED_LEGACY_RED_4320")
        println("STAGE21_BIGINT_PRESERVED_FIRST_GREEN_4320")
        println("STAGE21_BIGINT_LEGACY_WRONG_WRITES_21600")
    }
}
