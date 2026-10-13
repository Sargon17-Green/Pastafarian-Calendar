package pastafari

import java.math.BigInteger

/** Cam 27: oracl annibynnol BigInteger, 922 rank a rejection. */
object Stage27BigIntegerTests {
    private val one=BigInteger.ONE
    private val m=BigInteger("170141183460469231731687303715884105727")
    private val family=BigInteger.valueOf(922L)
    private val upper=m.divide(family).multiply(family)
    private data class Result(val answer:BigInteger,
        val rejected:List<BigInteger>,val rank:Int,val gap:Int)
    private fun reference(first:BigInteger,step:Int):Result {
        var x=first
        val rejected=ArrayList<BigInteger>()
        while(x>upper){
            rejected.add(x)
            check(rejected.size<=922){"E_PATCH13_BI_REJECTION_BOUND"}
            x=x.subtract(one)
                .add(BigInteger.valueOf(step.toLong())).mod(m).add(one)
        }
        val rank=x.subtract(one).mod(family).toInt()+1
        return Result(x,rejected.toList(),rank,41+rank)
    }
    private fun checkCase(first:BigInteger,step:Int,index:BigInteger,
                          wrapper:GateGapRankPatchWrapper) : Boolean {
        val oracle=reference(first,step)
        val corrected=wrapper.patch(
            ExactInt.parse(index.toString()),
            ExactInt.parse(first.toString()),step)
        val wrong=41+first.subtract(one).mod(family).toInt()
        check(corrected.gateIndex.toString()==index.toString() &&
            corrected.streamFirst.toString()==first.toString() &&
            corrected.directionStep==step &&
            corrected.acceptedAnswer.toString()==oracle.answer.toString() &&
            corrected.acceptedAnswerIndex0==oracle.rejected.size &&
            corrected.rejectedCandidates.map{it.toString()}==
                oracle.rejected.map{it.toString()} &&
            corrected.correctedRank1==oracle.rank &&
            corrected.correctedGateGap==oracle.gap &&
            corrected.correctedGateGap in 42..963 &&
            corrected.legacyRead.gateGapWrong==wrong &&
            corrected.legacyRead.rank0Wrong==wrong-41 &&
            corrected.legacyRead.rejectedCandidatesProcessed==0 &&
            corrected.legacyRead.oneShotReads==1 &&
            corrected.legacyRank0Calls==1 &&
            corrected.correctedRankCalls==1 &&
            corrected.acceptedAnswerReads==oracle.rejected.size+1 &&
            corrected.rejectionChecks==oracle.rejected.size+1 &&
            corrected.seal==1){
            "E_PATCH13_BIGINT_ORACLE_${first}_${step}"
        }
        return wrong!=oracle.gap
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_PATCH13_BIGINT_ARGS"}
        val seeds=listOf("0","-922","922",
            "123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val wrapper=GateGapRankPatchWrapper()
        var green=0;var legacyRed=0
        for(seed in seeds)for(n in 1..922)for(step in listOf(1,-1)){
            val value=seed+BigInteger.valueOf(n.toLong())
            val first=value.subtract(one).mod(upper).add(one)
            val index=BigInteger.valueOf((step*n).toLong())
            val red=checkCase(first,step,index,wrapper)
            check(red){"E_PATCH13_BIGINT_EXPECT_LEGACY_RED"}
            legacyRed++;green++
        }
        check(green==11064 && legacyRed==11064)
        println("STAGE27_BIGINT_CORRECTED_GREEN_11064")
        println("STAGE27_BIGINT_PRESERVED_LEGACY_RED_11064")

        // Pob un o'r 221 gwerth anghymwys, i'r ddau gyfeiriad.
        var boundary=0;var positive=0;var negative=0
        var totalRejected=0
        var longest=0
        var coincident=0
        for(delta in 1..221)for(step in listOf(1,-1)){
            val first=upper+BigInteger.valueOf(delta.toLong())
            val index=BigInteger.valueOf((step*delta).toLong())
            val red=checkCase(first,step,index,wrapper)
            val truth=reference(first,step)
            check(truth.rejected.isNotEmpty() &&
                truth.answer<=upper && truth.gap in 42..963) {
                "E_PATCH13_BIGINT_REJECTED_INPUT"
            }
            if(!red)coincident++
            boundary++
            if(step==1)positive++ else negative++
            totalRejected+=truth.rejected.size
            longest=maxOf(longest,truth.rejected.size)
        }
        check(boundary==442 && positive==221 && negative==221 &&
            longest>=221 && totalRejected>442 && coincident>0){
            "E_PATCH13_BIGINT_BOUNDARY_COUNTS"
        }
        println("STAGE27_BIGINT_REJECTION_GREEN_442")
        println("STAGE27_BIGINT_REJECTION_POSITIVE_221_NEGATIVE_221")
        println("STAGE27_BIGINT_REJECTION_FULL_TRACE_442")
        println("STAGE27_BIGINT_REJECTION_LONG_STREAM_CONFIRMED")
        println("STAGE27_BIGINT_BOUNDARY_INCIDENTAL_MATCH_CONFIRMED")
    }
}
