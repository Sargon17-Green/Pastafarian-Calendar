package pastafari

/** Cam 50: tystiolaeth o golli'r lapio, gyda'r oracl mewn profion yn unig. */
object Stage50Tests {
    private fun must(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try{block()}catch(_:IllegalArgumentException){return}
        error("E_DISCOVERY25_MISSING_GUARD")
    }

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val old=LegacyYear5000UnwrappedAnswerAdapter()
        val m=NormativeCore.M
        must("E_DISCOVERY25_MODULUS_LOCK",
            LegacyYear5000UnwrappedAnswerAdapter.MODULUS==m)

        val oracle=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val real=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16) {
            val a=ExactInt.of(i.toLong())
            val open=oracle.gates.get(a)
            for(width in 6..12){
                val b=a+width.toLong()
                real.add(Year5000TieCandidate(a,b,open,oracle.gates.get(b)))
            }
        }
        val eligible=real.filter { c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy {it.openGateDay})
        must("E_DISCOVERY25_REAL_GATES",
            real.size==231 && eligible.isNotEmpty())
        val realStream=NormativeCore.askBowl(
            NormativeCore.sauce(day,day),1,NormativeCore.SEAL_YEAR_5000)
        val originalRank=NormativeCore.chooseRankInt(realStream,eligible.size)
        must("E_DISCOVERY25_REAL_ORACLE",
            originalRank in 1..eligible.size &&
            oracle.year5000(day).openGateDay<day)
        val limit=(m/ExactInt.of(eligible.size.toLong()))*
            ExactInt.of(eligible.size.toLong())
        // Ym mhob achos lle derbynnir y sampl gyntaf, mae'r llwybrau'n cyfateb.
        if(realStream.first<=limit){
            must("E_DISCOVERY25_REAL_FIRST_ACCEPT_MATCH",
                old.tryRank(realStream.first,realStream.directionStep,
                    eligible.size,1)==originalRank)
        }
        println("STAGE50_REAL_231_GATE_PAIRS_ORACLE_GREEN")

        var red=0;var controls=0
        for(n in 2..65){
            val divisor=ExactInt.of(n.toLong())
            must("E_DISCOVERY25_REMAINDER_$n",
                m.euclideanMod(divisor)>ExactInt.ZERO)
            val oracleWrap=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,1),divisor)
            must("E_DISCOVERY25_FORWARD_WRAP_$n",
                oracleWrap==ExactInt.ONE &&
                old.tryRank(m,1,n,5)==null)
            red++
            val oracleNegative=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,-1),divisor).toIntExact()
            must("E_DISCOVERY25_NEGATIVE_CONTROL_$n",
                old.tryRank(m,-1,n,n+2)==oracleNegative)
            val accepted=old.tryRank(ExactInt.ONE,1,n,1)
            must("E_DISCOVERY25_FIRST_ACCEPTED_$n",
                accepted==1 && NormativeCore.chooseRankShort(
                    NormativeCore.AnswerStream(ExactInt.ONE,1),divisor)==
                    ExactInt.ONE)
            controls++
        }
        must("E_DISCOVERY25_SYNTH_COUNTS",
            red==64 && controls==64)
        println("STAGE50_SYNTHETIC_64_NO_WRAP_RED_64_CONTROLS_GREEN")

        var largeRed=0;var largeControl=0
        for(n in 1001..1128){
            val divisor=ExactInt.of(n.toLong())
            must("E_DISCOVERY25_BIG_REMAINDER_$n",
                m.euclideanMod(divisor)>ExactInt.ZERO)
            must("E_DISCOVERY25_BIG_WRAP_$n",
                NormativeCore.chooseRankShort(
                    NormativeCore.AnswerStream(m,1),divisor)==ExactInt.ONE &&
                old.tryRank(m,1,n,8)==null)
            largeRed++
            val valid=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,-1),divisor).toIntExact()
            must("E_DISCOVERY25_BIG_BACKWARDS_$n",
                old.tryRank(m,-1,n,n+2)==valid)
            largeControl++
        }
        must("E_DISCOVERY25_BIG_COUNTS",
            largeRed==128 && largeControl==128)
        println("STAGE50_BIGINT_128_NO_WRAP_RED_128_CONTROLS_GREEN")

        must("E_DISCOVERY25_SINGLETON",
            old.tryRank(m,1,1,1)==1 &&
            NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,1),ExactInt.ONE)==ExactInt.ONE)
        rejects{old.tryRank(ExactInt.ZERO,1,3,5)}
        rejects{old.tryRank(m+1L,1,3,5)}
        rejects{old.tryRank(m,0,3,5)}
        rejects{old.tryRank(m,2,3,5)}
        rejects{old.tryRank(m,1,0,5)}
        rejects{old.tryRank(m,1,-1,5)}
        rejects{old.tryRank(m,1,3,0)}
        rejects{old.tryRank(m,1,3,-2)}
        println("STAGE50_BOUNDS_AND_INPUT_GUARDS_GREEN")
        println("STAGE50_DISCOVERY_EXPECTED_RED_PASS")
    }
}
