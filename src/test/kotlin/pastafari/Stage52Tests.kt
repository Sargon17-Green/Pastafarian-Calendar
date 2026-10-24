package pastafari

/** Cam 52: arbrofion ar yr union ffin derbyn sampl. */
object Stage52Tests {
    private fun must(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit) {
        try {block()} catch(_:IllegalArgumentException){return}
        error("E_DISCOVERY26_GUARD_MISSING")
    }
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val legacy=LegacyYear5000ExclusiveAcceptanceAdapter()
        val m=NormativeCore.M
        must("E_DISCOVERY26_MODULUS",
            LegacyYear5000ExclusiveAcceptanceAdapter.MODULUS==m)
        val oracle=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val pairs=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16) {
            val a=ExactInt.of(i.toLong())
            val start=oracle.gates.get(a)
            for(width in 6..12) {
                val b=a+width.toLong()
                pairs.add(Year5000TieCandidate(a,b,start,oracle.gates.get(b)))
            }
        }
        val eligible=pairs.filter { c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy{it.openGateDay})
        must("E_DISCOVERY26_REAL_PAIRS",pairs.size==231 && eligible.isNotEmpty())
        val stream=NormativeCore.askBowl(
            NormativeCore.sauce(day,day),1,NormativeCore.SEAL_YEAR_5000)
        val canonical=NormativeCore.chooseRankInt(stream,eligible.size)
        must("E_DISCOVERY26_REAL_RANK",canonical in 1..eligible.size &&
            oracle.year5000(day).openGateDay<day)
        val nReal=ExactInt.of(eligible.size.toLong())
        val limitReal=(m/nReal)*nReal
        if(stream.first<limitReal){
            must("E_DISCOVERY26_REAL_FIRST_ACCEPT_CONTROL",
                legacy.rankOrNull(stream.first,stream.directionStep,eligible.size,1)==canonical)
        }
        println("STAGE52_REAL_231_PAIRS_STREAM_ORACLE_GREEN")

        var red=0;var controls=0
        for(n in 2..65) {
            val divisor=ExactInt.of(n.toLong())
            val boundary=(m/divisor)*divisor
            val trueRank=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(boundary,-1),divisor).toIntExact()
            val wrong=legacy.rankOrNull(boundary,-1,n,3)
            must("E_DISCOVERY26_SYNTH_BOUNDARY_$n",
                trueRank==n && wrong==n-1 && wrong!=trueRank)
            red++
            val beforeBoundary=boundary-ExactInt.ONE
            val correctControl=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(beforeBoundary,-1),divisor).toIntExact()
            must("E_DISCOVERY26_SYNTH_CONTROL_$n",
                legacy.rankOrNull(beforeBoundary,-1,n,1)==correctControl &&
                correctControl==n-1)
            controls++
        }
        must("E_DISCOVERY26_SYNTH_COUNTS",red==64 && controls==64)
        println("STAGE52_SYNTHETIC_64_BOUNDARY_REDS_64_CONTROLS_GREEN")

        var bigReds=0;var bigControls=0
        for(n in 1001..1128) {
            val divisor=ExactInt.of(n.toLong())
            val boundary=(m/divisor)*divisor
            val good=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(boundary,-1),divisor).toIntExact()
            val old=legacy.rankOrNull(boundary,-1,n,3)
            must("E_DISCOVERY26_BIGINT_RED_$n",
                good==n && old==n-1 && old!=good)
            bigReds++
            val before=boundary-ExactInt.ONE
            must("E_DISCOVERY26_BIGINT_CONTROL_$n",
                legacy.rankOrNull(before,-1,n,1)==n-1)
            bigControls++
        }
        must("E_DISCOVERY26_BIG_COUNTS",bigReds==128 && bigControls==128)
        println("STAGE52_BIGINT_128_BOUNDARY_REDS_128_CONTROLS_GREEN")

        val three=ExactInt.of(3)
        val boundary=(m/three)*three
        must("E_DISCOVERY26_FORWARD_EDGE",
            NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(boundary,1),three)==three &&
            legacy.rankOrNull(boundary,1,3,6)==1)
        must("E_DISCOVERY26_SINGLETON",
            NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,-1),ExactInt.ONE)==ExactInt.ONE &&
            legacy.rankOrNull(m,-1,1,3)==1)
        rejects{legacy.rankOrNull(ExactInt.ZERO,-1,3,3)}
        rejects{legacy.rankOrNull(m+1L,-1,3,3)}
        rejects{legacy.rankOrNull(m,0,3,3)}
        rejects{legacy.rankOrNull(m,2,3,3)}
        rejects{legacy.rankOrNull(m,-1,0,3)}
        rejects{legacy.rankOrNull(m,-1,-4,3)}
        rejects{legacy.rankOrNull(m,-1,3,0)}
        rejects{legacy.rankOrNull(m,-1,3,-1)}
        println("STAGE52_BOUNDARY_AND_GUARDS_GREEN")
        println("STAGE52_DISCOVERY_EXPECTED_RED_PASS")
    }
}
