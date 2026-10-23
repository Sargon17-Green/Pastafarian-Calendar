package pastafari

/** Cam 48: gwrthenghraifft i fodiwlo'r ateb cyntaf heb wrthodiad. */
object Stage48Tests {
    private fun must(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try{block()}catch(_:IllegalArgumentException){return}
        error("E_DISCOVERY24_MISSING_INPUT_GUARD")
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val historical=LegacyYear5000FirstAnswerModuloAdapter()
        val modulus=NormativeCore.M
        must("E_DISCOVERY24_MODULUS_LOCK",
            historical.ANSWER_MODULUS==modulus)
        val calendar=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val real=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val a=ExactInt.of(i.toLong())
            val open=calendar.gates.get(a)
            for(width in 6..12){
                val b=a+width.toLong()
                real.add(Year5000TieCandidate(a,b,open,calendar.gates.get(b)))
            }
        }
        val eligible=real.filter{c->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy{it.openGateDay})
        must("E_DISCOVERY24_REAL_COUNT",real.size==231 && eligible.isNotEmpty())
        val stream=NormativeCore.askBowl(
            NormativeCore.sauce(day,day),1,NormativeCore.SEAL_YEAR_5000)
        val originalRank=NormativeCore.chooseRankInt(stream,eligible.size)
        val oldRank=historical.rankFromFirstAnswer(stream.first,eligible.size)
        must("E_DISCOVERY24_REAL_COMPARISON",
            originalRank in 1..eligible.size &&
            oldRank in 1..eligible.size &&
            historical.shouldRejectFirstAnswer(stream.first,eligible.size)==
                (stream.first>(modulus/ExactInt.of(eligible.size.toLong()))*
                    ExactInt.of(eligible.size.toLong())) &&
            calendar.year5000(day).openGateDay<day)
        println("STAGE48_REAL_231_GATE_PAIRS_STREAM_ORACLE_GREEN")

        var forcedRed=0;var acceptedMatch=0
        for(i in 1..64){
            val n=2+i
            val divisor=ExactInt.of(n.toLong())
            val remainder=modulus.euclideanMod(divisor)
            if(remainder==ExactInt.ZERO)continue
            val limit=(modulus/divisor)*divisor
            val force=NormativeCore.AnswerStream(modulus,-1)
            val canonical=NormativeCore.chooseRankShort(force,divisor)
            val naive=historical.rankFromFirstAnswer(modulus,n)
            must("E_DISCOVERY24_FORCED_REJECT_$i",
                historical.shouldRejectFirstAnswer(modulus,n) &&
                canonical==divisor && naive!=canonical &&
                naive in 1..n)
            forcedRed++
            val accepted=NormativeCore.AnswerStream(limit,-1)
            val reference=NormativeCore.chooseRankShort(accepted,divisor)
            must("E_DISCOVERY24_ACCEPT_MATCH_$i",
                !historical.shouldRejectFirstAnswer(limit,n) &&
                historical.rankFromFirstAnswer(limit,n)==reference.toIntExact())
            acceptedMatch++
        }
        // Os oes rhannwr damweiniol yn yr ystod, cyfrif y achosion dilys yn unig.
        must("E_DISCOVERY24_SYNTHETIC_COUNTS",
            forcedRed>=56 && acceptedMatch==forcedRed)
        println("STAGE48_SYNTHETIC_REJECT_DIFFERENTIALS_GREEN")

        var cases=0
        for(i in 1..128){
            val n=1000+i
            val divisor=ExactInt.of(n.toLong())
            if(modulus.euclideanMod(divisor)==ExactInt.ZERO)continue
            val expected=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(modulus,-1),divisor)
            val wrong=historical.rankFromFirstAnswer(modulus,n)
            must("E_DISCOVERY24_BIGINT_RED_$i",
                expected==divisor &&
                wrong!=expected.toIntExact() &&
                historical.shouldRejectFirstAnswer(modulus,n))
            cases++
        }
        must("E_DISCOVERY24_BIGINT_COUNTS",cases>=120)
        println("STAGE48_BIGINT_MODULUS_EDGE_DIFFERENTIALS_GREEN")

        val one=NormativeCore.AnswerStream(modulus,-1)
        must("E_DISCOVERY24_SINGLETON",
            historical.rankFromFirstAnswer(modulus,1)==1 &&
            !historical.shouldRejectFirstAnswer(modulus,1) &&
            NormativeCore.chooseRankShort(one,ExactInt.ONE)==ExactInt.ONE)
        rejects{historical.rankFromFirstAnswer(modulus,0)}
        rejects{historical.rankFromFirstAnswer(modulus,-1)}
        rejects{historical.rankFromFirstAnswer(ExactInt.ZERO,3)}
        rejects{historical.rankFromFirstAnswer(modulus+1L,3)}
        rejects{historical.shouldRejectFirstAnswer(ExactInt.ZERO,3)}
        rejects{historical.shouldRejectFirstAnswer(modulus,0)}
        println("STAGE48_INPUT_GUARDS_GREEN")
        println("STAGE48_DISCOVERY_EXPECTED_RED_PASS")
    }
}
