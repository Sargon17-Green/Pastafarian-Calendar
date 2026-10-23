package pastafari

/** Cam 47: cymharu ailddefnyddio pâr gyda rhestr safonol unigryw. */
object Stage47Tests {
    private fun must(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit) {
        try {block()} catch(_:IllegalArgumentException){return}
        error("E_PATCH23_INPUT_GUARD_MISSING")
    }
    private fun candidate(
        gate:ExactInt, open:ExactInt, length:Long
    ):Year5000TieCandidate = Year5000TieCandidate(
        gate,gate+6L,open,open+length)
    private fun reference(
        day:ExactInt,items:List<Year5000TieCandidate>
    ):List<Year5000TieCandidate> = items.filter { c ->
        c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
    }.distinctBy { it.openGateIndex to it.closeGateIndex }
        .sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy{it.openGateDay})

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val oracle=NormativeCalendar()
        val historical=LegacyYear5000RepeatedCandidateAdapter()
        val wrapper=Year5000DistinctGatePatchWrapper()
        val manager=Year5000DistinctGatePatchManager()
        val foundation=NormativeCore.FOUNDATION_DAY
        val natural=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val g=ExactInt.of(i.toLong())
            val open=oracle.gates.get(g)
            for(width in 6..12){
                val b=g+width.toLong()
                natural.add(Year5000TieCandidate(g,b,open,oracle.gates.get(b)))
            }
        }
        val snapshot=natural.toList()
        val realNorm=reference(foundation,natural)
        must("E_PATCH23_REAL_COUNT", natural.size==231 &&
            realNorm.isNotEmpty() && natural==snapshot)
        val chosenRanks=listOf(1,realNorm.size,(realNorm.size+1)/2).distinct()
        for(rank in chosenRanks){
            val r=ExactInt.of(rank.toLong())
            val outcome=wrapper.patch(foundation,natural,r)
            must("E_PATCH23_REAL_RANK_$rank",
                outcome.correctedChosen==realNorm[rank-1] &&
                outcome.legacyChosen==historical.chooseAtRank(foundation,natural,r) &&
                outcome.uniqueCandidateCount==realNorm.size &&
                outcome.removedDuplicateCount==1 &&
                outcome.correctionApplied==
                    (outcome.legacyChosen!=outcome.correctedChosen) &&
                outcome.historicalCalls==1 &&
                outcome.correctedChecks==1 && natural==snapshot)
        }
        val year=oracle.year5000(foundation)
        must("E_PATCH23_REAL_ORACLE",
            year.openGateDay<foundation && foundation<=year.closeGateDay)
        println("STAGE47_REAL_GATE_231_PAIRS_GREEN")

        var corrections=0;var matches=0;var sessions=0
        var stored:Year5000DistinctGatePatchSession?=null
        for(i in 1..64){
            val g=ExactInt.of(i*100L)
            val open=ExactInt.of(i*100000L)
            val day=open+25L
            val short=candidate(g,open,252L+i%100)
            val long=candidate(g+10L,open+7L,700L+i%100)
            val mixed=listOf(long,short)
            val expected=reference(day,mixed)
            must("E_PATCH23_SYNTH_ORDER_$i", expected==listOf(short,long))
            for(rank in 1..2) {
                val r=ExactInt.of(rank.toLong())
                val out=wrapper.patch(day,mixed,r)
                val session=manager.apply(day,mixed,r)
                must("E_PATCH23_SYNTH_RANK_$i-$rank",
                    out.correctedChosen==expected[rank-1] &&
                    out.legacyChosen==(if(rank==1)short else short) &&
                    out.correctionApplied==(rank==2) &&
                    out.uniqueCandidateCount==2 &&
                    out.removedDuplicateCount==1 &&
                    session.outcome==out &&
                    session.context.status=="PATCHED_YEAR5000_DISTINCT_GATE_PAIRS" &&
                    session.context.phase=="PATCH_23" &&
                    session.branchTrace==listOf("BOOT","PATCH_23") &&
                    session.context.branchTrace==session.branchTrace &&
                    session.diagnostics==listOf("PATCH_23_REMOVE_REPEATED_GATE_PAIR") &&
                    session.applied && session.invocationCount==1)
                if(stored==null)stored=session
                if(out.correctionApplied)corrections++ else matches++
                sessions++
            }
        }
        must("E_PATCH23_SYNTH_TOTAL",
            corrections==64 && matches==64 && sessions==128)
        println("STAGE47_SYNTHETIC_64_CORRECTIONS_64_MATCH_GREEN")
        println("STAGE47_MANAGER_128_SESSIONS_GREEN")

        val huge=ExactInt.parse("18446744073709551616000000000000000000000000")
        val far=ExactInt.parse("-10000000000000000000000000000000000000000000")
        var triples=0;var fixed=0;var unchanged=0;var rejectedExtra=0
        for(i in 1..128) {
            val g=huge+i*100L
            val open=far+i*20000L
            val day=open+30L
            val short=candidate(g,open,252L)
            val middle=candidate(g+10L,open+8L,500L)
            val long=candidate(g+20L,open+14L,800L)
            val input=listOf(long,middle,short)
            val expected=reference(day,input)
            must("E_PATCH23_BIG_REF_$i",
                expected==listOf(short,middle,long))
            for(rank in 1..3) {
                val r=ExactInt.of(rank.toLong())
                val out=wrapper.patch(day,input,r)
                must("E_PATCH23_BIG_RANK_$i-$rank",
                    out.correctedChosen==expected[rank-1] &&
                    out.legacyChosen==(if(rank<=2)short else middle) &&
                    out.correctionApplied==(rank!=1) &&
                    out.removedDuplicateCount==1)
                if(out.correctionApplied)fixed++ else unchanged++
            }
            rejects { wrapper.patch(day,input,ExactInt.of(4)) }
            rejectedExtra++
            triples++
        }
        must("E_PATCH23_BIG_TOTAL",
            triples==128 && fixed==256 && unchanged==128 &&
            rejectedExtra==128)
        println("STAGE47_BIGINT_128_TRIPLES_256_CORRECTIONS_128_MATCH_128_EXTRA_REJECTS")

        val zero=ExactInt.ZERO
        val day=ExactInt.of(30)
        val good=candidate(zero,zero,300L)
        val below=candidate(zero+10L,zero+2L,251L)
        val above=candidate(zero+20L,zero+7L,5779L)
        val badGaps=Year5000TieCandidate(zero+30L,zero+35L,zero+9L,zero+400L)
        val norm=reference(day,listOf(below,above,badGaps,good))
        val actual=wrapper.patch(day,listOf(below,above,badGaps,good),ExactInt.ONE)
        must("E_PATCH23_ELIGIBILITY_SINGLETON",
            norm==listOf(good) &&
            actual.correctedChosen==good &&
            actual.uniqueCandidateCount==1 &&
            actual.removedDuplicateCount==1 &&
            !actual.correctionApplied)
        rejects { wrapper.patch(day,emptyList(),ExactInt.ONE) }
        rejects { wrapper.patch(day,listOf(
            Year5000TieCandidate(zero,zero,zero,zero+300L)),ExactInt.ONE) }
        rejects { wrapper.patch(day,listOf(
            Year5000TieCandidate(zero,zero+6L,zero+300L,zero)),ExactInt.ONE) }
        rejects { wrapper.patch(day,listOf(below,above),ExactInt.ONE) }
        rejects { wrapper.patch(day,listOf(good),zero) }
        rejects { wrapper.patch(day,listOf(good),ExactInt.of(2)) }
        val beforeMetrics=manager.metrics.snapshot()
        val beforeBoot=manager.bootstrap.metrics.snapshot()
        rejects { manager.apply(day,emptyList(),ExactInt.ONE) }
        rejects { manager.apply(day,listOf(below,above),ExactInt.ONE) }
        rejects { manager.apply(day,listOf(good),zero) }
        must("E_PATCH23_METRICS_NO_SIDE_EFFECT",
            beforeMetrics["patch23.historical.calls"]==128L &&
            beforeMetrics["patch23.corrected.checks"]==128L &&
            beforeMetrics["patch23.applied"]==128L &&
            beforeBoot["bootstrap.ready"]==128L &&
            manager.metrics.snapshot()==beforeMetrics &&
            manager.bootstrap.metrics.snapshot()==beforeBoot)
        val session=stored?:error("E_PATCH23_NO_STORED_SESSION")
        val outcome=session.outcome
        val trace=session.branchTrace.toList()
        val code=try{manager.rejectReplay(session);"NO_ERROR"}
            catch(e:MonsterValidationException){e.machineCode}
        must("E_PATCH23_REPLAY_REJECTED",
            code=="E_PATCH23_CONTEXT_NOT_READY" &&
            session.outcome===outcome &&
            session.branchTrace==trace &&
            manager.metrics.snapshot()==beforeMetrics &&
            manager.bootstrap.metrics.snapshot()==beforeBoot)
        println("STAGE47_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE47_PATCH_NATIVE_GREEN")
    }
}
