package pastafari

import java.math.BigInteger

/** Cam 26 — prawf BigInteger cwbl annibynnol o 922 o fylchau. */
object Stage26BigIntegerTests {
    private val modulus=BigInteger("170141183460469231731687303715884105727")
    private val family=BigInteger.valueOf(922L)
    private val one=BigInteger.ONE
    private val acceptanceLimit=modulus.divide(family).multiply(family)
    private fun trueGateGap(first:BigInteger,direction:Int):Int {
        var answer=first
        var count=0
        while(answer>acceptanceLimit){
            answer=answer.subtract(one)
                .add(BigInteger.valueOf(direction.toLong()))
                .mod(modulus).add(one)
            count++
            check(count<=922){"E_DISCOVERY13_BIGINT_REJECTION_LIMIT"}
        }
        return 42+answer.subtract(one).mod(family).toInt()
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY13_BIGINT_ARGS"}
        val bases=listOf("0","-922","922",
            "123456789012345678901234567890",
            "-98765432109876543210987654321098765432109876543210",
            "123456789012345678901234567890123456789012345678901234567890"
        ).map(::BigInteger)
        val adapter=LegacyGateGapRankAdapter()
        var allRed=0;var checked=0;var minWrong=0;var maxTrue=0
        for(base in bases)for(n in 1..922)for(direction in listOf(1,-1)){
            val shifted=base.add(BigInteger.valueOf(n.toLong()))
            val first=shifted.subtract(one).mod(acceptanceLimit).add(one)
            val expected=trueGateGap(first,direction)
            val index=BigInteger.valueOf((direction*n).toLong())
            val got=adapter.oldGateGapWithoutRank1(
                ExactInt.parse(index.toString()),
                ExactInt.parse(first.toString()),direction)
            val zeroBased=first.subtract(one).mod(family).toInt()
            check(got.gateIndex.toString()==index.toString() &&
                got.streamFirst.toString()==first.toString() &&
                got.streamDirectionStep==direction &&
                got.rank0Wrong==zeroBased &&
                got.gateGapWrong==41+zeroBased &&
                got.gateGapWrong==expected-1 &&
                got.oneShotReads==1 &&
                got.rejectedCandidatesProcessed==0){
                "E_DISCOVERY13_BIGINT_GAP_${n}_${direction}"
            }
            if(got.gateGapWrong==41)minWrong++
            if(expected==963)maxTrue++
            allRed++;checked++
        }
        check(checked==11064 && allRed==11064 &&
            minWrong>0 && maxTrue>0){
            "E_DISCOVERY13_BIGINT_COUNTS"
        }
        println("STAGE26_BIGINT_INPUTS_11064")
        println("STAGE26_BIGINT_EXPECTED_RED_11064")
        println("STAGE26_BIGINT_ILLEGAL_LOW_BOUND_CONFIRMED")
        println("STAGE26_BIGINT_CORRECT_HIGH_BOUND_CONFIRMED")
    }
}
