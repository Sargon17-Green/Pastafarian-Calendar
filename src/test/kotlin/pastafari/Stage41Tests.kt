package pastafari

/** Cam 41: atgyweirio rhengo cyfartal heb ddileu graith Cam 40. */
object Stage41Tests {
    private fun insist(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try{block()}catch(_:IllegalArgumentException){return}
        error("E_PATCH20_MISSING_INPUT_GUARD")
    }
    private fun normative(
        day:ExactInt,
        input:List<Year5000TieCandidate>
    ):List<Year5000TieCandidate> = input.filter { c ->
        val len=c.closeGateDay-c.openGateDay
        c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            len>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            len<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
    }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
        .thenBy{it.openGateDay})

    private fun candidate(
        gate:ExactInt,open:ExactInt,length:Long
    )=Year5000TieCandidate(gate,gate+6L,open,open+length)

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val original=NormativeCalendar()
        val adapter=LegacyYear5000TieBreakAdapter()
        val wrapper=Year5000TieAscendingPatchWrapper()
        val manager=Year5000TieAscendingPatchManager()
        val foundation=NormativeCore.FOUNDATION_DAY
        val natural=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val a=ExactInt.of(i.toLong())
            val open=original.gates.get(a)
            for(width in 6..12){
                val b=a+width.toLong()
                natural.add(Year5000TieCandidate(
                    a,b,open,original.gates.get(b)))
            }
        }
        val before=natural.toList()
        val real=wrapper.patch(foundation,natural)
        val correct=normative(foundation,natural)
        insist("E_PATCH20_REAL_GATES",
            natural.size==231 && natural==before &&
            correct.isNotEmpty() && real.correctedOrder==correct &&
            real.legacyOrder==adapter.order(foundation,natural) &&
            real.legacyCalls==1 && real.correctedChecks==1 &&
            real.candidateCount==correct.size &&
            real.correctionApplied==(real.legacyOrder!=correct))
        val selected=original.year5000(foundation)
        insist("E_PATCH20_REAL_ORACLE_YEAR5000",
            selected.openGateDay<foundation &&
            foundation<=selected.closeGateDay)
        println("STAGE41_REAL_GATE_RANKING_GREEN_231")

        var patched=0;var unchanged=0;var sessions=0
        var first:Year5000TieAscendingPatchSession?=null
        for(i in 1..64){
            val g=ExactInt.of((i*100).toLong())
            val open=ExactInt.of(i*100000L)
            val length=252L+(i*37L)%5527L
            val low=candidate(g,open,length)
            val high=candidate(g+10L,open+7L,length)
            val day=open+12L
            val tied=listOf(high,low)
            val save=tied.toList()
            val outcome=wrapper.patch(day,tied)
            val session=manager.apply(day,tied)
            insist("E_PATCH20_TIED_$i",
                tied==save &&
                outcome.legacyOrder==listOf(high,low) &&
                outcome.correctedOrder==listOf(low,high) &&
                outcome.correctedOrder==normative(day,tied) &&
                outcome.correctionApplied &&
                session.outcome==outcome &&
                session.context.status=="PATCHED_YEAR5000_TIE_ASCENDING" &&
                session.context.phase=="PATCH_20" &&
                session.branchTrace==listOf("BOOT","PATCH_20") &&
                session.diagnostics==listOf(
                    "PATCH_20_STABLE_ASCENDING_TIE_BREAK") &&
                session.context.branchTrace==session.branchTrace &&
                session.applied && session.invocationCount==1 &&
                wrapper.chooseAtRank(day,tied,ExactInt.ONE)==low &&
                wrapper.chooseAtRank(day,tied,ExactInt.of(2))==high)
            if(first==null)first=session
            patched++;sessions++
            val untied=listOf(low,
                candidate(g+10L,open+7L,length+1L))
            val unout=wrapper.patch(day,untied)
            val unsess=manager.apply(day,untied)
            insist("E_PATCH20_UNTIED_$i",
                unout.correctedOrder==normative(day,untied) &&
                unout.legacyOrder==unout.correctedOrder &&
                !unout.correctionApplied &&
                unsess.outcome==unout)
            unchanged++;sessions++
        }
        insist("E_PATCH20_SYNTH_COUNTS",
            patched==64 && unchanged==64 && sessions==128)
        println("STAGE41_SYNTHETIC_GREEN_64_PATCHED_64_MATCH")
        println("STAGE41_MANAGER_SESSIONS_GREEN_128")

        val huge=ExactInt.parse("1844674407370955161600000000000000000000000000")
        val far=ExactInt.parse("-1000000000000000000000000000000000000000000")
        var wide=0;var rankFixed=0
        for(i in 1..128){
            val g=huge+(i*100L)
            val open=far+(i*20000L)
            val length=252L+(i*31L)%5527L
            val low=candidate(g,open,length)
            val high=candidate(g+10L,open+8L,length)
            val day=open+15L
            val input=listOf(low,high)
            val out=wrapper.patch(day,input)
            insist("E_PATCH20_BIG_$i",
                out.legacyOrder==listOf(high,low) &&
                out.correctedOrder==listOf(low,high) &&
                out.correctedOrder==normative(day,input) &&
                out.correctionApplied)
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                val old=adapter.chooseAtRank(day,input,r)
                val fixed=wrapper.chooseAtRank(day,input,r)
                insist("E_PATCH20_BIG_RANK_$i-$rank",
                    fixed==out.correctedOrder[rank-1] &&
                    fixed!=old)
                rankFixed++
            }
            wide++
        }
        insist("E_PATCH20_BIG_TOTAL",wide==128 && rankFixed==256)
        println("STAGE41_BIGINT_GREEN_128_PAIRS_256_RANK_CORRECTIONS")

        for(len in listOf(251L,252L,5778L,5779L)){
            val g=ExactInt.ZERO
            val day=ExactInt.of(15)
            val valid=candidate(g,g,252L)
            val extra=candidate(g+10L,g+2L,len)
            val out=wrapper.patch(day,listOf(extra,valid))
            val expected=normative(day,listOf(extra,valid))
            insist("E_PATCH20_LENGTH_$len",
                out.correctedOrder==expected &&
                out.candidateCount==(if(len in 252L..5778L)2 else 1))
        }
        println("STAGE41_YEAR_LENGTH_BOUNDARIES_GREEN")

        val day=ExactInt.of(10)
        val zero=ExactInt.ZERO
        val good=candidate(zero,zero,252)
        rejects{wrapper.patch(day,emptyList())}
        rejects{wrapper.patch(day,listOf(
            Year5000TieCandidate(zero,zero,zero,zero+252L)))}
        rejects{wrapper.patch(day,listOf(
            Year5000TieCandidate(zero,zero+6L,zero+252L,zero)))}
        rejects{wrapper.patch(day,listOf(candidate(zero,zero,251)))}
        rejects{wrapper.chooseAtRank(day,listOf(good),zero)}
        rejects{wrapper.chooseAtRank(day,listOf(good),ExactInt.of(2))}
        val counts=manager.metrics.snapshot()
        val boots=manager.bootstrap.metrics.snapshot()
        rejects{manager.apply(day,emptyList())}
        rejects{manager.apply(day,listOf(
            Year5000TieCandidate(zero,zero,zero,zero+252L)))}
        insist("E_PATCH20_METRICS",
            counts["patch20.legacy.calls"]==128L &&
            counts["patch20.corrected.checks"]==128L &&
            counts["patch20.applied"]==128L &&
            boots["bootstrap.ready"]==128L &&
            manager.metrics.snapshot()==counts &&
            manager.bootstrap.metrics.snapshot()==boots)
        val session=first?:error("E_PATCH20_NO_SESSION")
        val oldOutcome=session.outcome
        val oldTrace=session.branchTrace.toList()
        val code=try{manager.rejectReplay(session);"NO_ERROR"}
            catch(e:MonsterValidationException){e.machineCode}
        insist("E_PATCH20_REPLAY",
            code=="E_PATCH20_CONTEXT_NOT_READY" &&
            session.outcome===oldOutcome &&
            session.branchTrace==oldTrace &&
            manager.metrics.snapshot()==counts &&
            manager.bootstrap.metrics.snapshot()==boots)
        println("STAGE41_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE41_PATCH_NATIVE_GREEN")
    }
}
