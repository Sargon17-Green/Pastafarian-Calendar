package pastafari

/** Cam 43: rheng ar ôl trefnu, gydag oracl gwreiddiol yn y prawf yn unig. */
object Stage43Tests {
    private fun must(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try{block()}catch(_:IllegalArgumentException){return}
        error("E_PATCH21_GUARD_NOT_ENFORCED")
    }
    private fun candidate(
        gate:ExactInt,start:ExactInt,length:Long
    )=Year5000TieCandidate(gate,gate+6L,start,start+length)
    private fun normative(
        day:ExactInt, input:List<Year5000TieCandidate>
    ):List<Year5000TieCandidate> = input.filter { c ->
        val len=c.closeGateDay-c.openGateDay
        c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            len>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            len<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
    }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
        .thenBy{it.openGateDay})

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val oracle=NormativeCalendar()
        val old=LegacyYear5000PreSortRankAdapter()
        val wrapper=Year5000PostSortRankPatchWrapper()
        val manager=Year5000PostSortRankPatchManager()
        val origin=NormativeCore.FOUNDATION_DAY
        val real=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val a=ExactInt.of(i.toLong())
            val start=oracle.gates.get(a)
            for(width in 6..12){
                val b=a+width.toLong()
                real.add(Year5000TieCandidate(a,b,start,oracle.gates.get(b)))
            }
        }
        val prior=real.toList()
        val correctReal=normative(origin,real)
        must("E_PATCH21_REAL_NONEMPTY",real.size==231 &&
            correctReal.isNotEmpty() &&
            correctReal.size==old.eligibleInEncounterOrder(origin,real).size)
        val ranking=linkedSetOf(1,correctReal.size,(correctReal.size+1)/2)
        for(rank in ranking){
            val actual=wrapper.patch(origin,real,ExactInt.of(rank.toLong()))
            val historical=old.chooseAtRank(origin,real,ExactInt.of(rank.toLong()))
            must("E_PATCH21_REAL_$rank",
                actual.legacyChosen==historical &&
                actual.correctedChosen==correctReal[rank-1] &&
                actual.correctionApplied==(historical!=correctReal[rank-1]) &&
                actual.legacyCalls==1 && actual.correctedChecks==1 &&
                actual.candidateCount==correctReal.size &&
                real==prior)
        }
        val year=oracle.year5000(origin)
        must("E_PATCH21_YEAR5000_ORACLE",
            year.openGateDay<origin && origin<=year.closeGateDay)
        println("STAGE43_REAL_231_GATE_PAIRS_RANKED_GREEN")

        var altered=0;var unchanged=0;var sessions=0
        var saved:Year5000PostSortRankPatchSession?=null
        for(i in 1..64){
            val g=ExactInt.of(i*100L)
            val start=ExactInt.of(i*100000L)
            val day=start+20L
            val long=candidate(g,start,600L+(i%11))
            val short=candidate(g+10L,start+5L,300L+(i%11))
            val unsorted=listOf(long,short)
            val expected=normative(day,unsorted)
            must("E_PATCH21_SYNTH_CANON_$i",expected==listOf(short,long))
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                val out=wrapper.patch(day,unsorted,r)
                must("E_PATCH21_SYNTH_RED_$i-$rank",
                    out.legacyChosen==unsorted[rank-1] &&
                    out.correctedChosen==expected[rank-1] &&
                    out.correctionApplied)
                altered++
            }
            val session=manager.apply(day,unsorted,ExactInt.ONE)
            must("E_PATCH21_SESSION_RED_$i",
                session.outcome.correctedChosen==short &&
                session.outcome.legacyChosen==long &&
                session.outcome.correctionApplied &&
                session.context.phase=="PATCH_21" &&
                session.context.status=="PATCHED_YEAR5000_RANK_AFTER_SORT" &&
                session.branchTrace==listOf("BOOT","PATCH_21") &&
                session.context.branchTrace==session.branchTrace &&
                session.diagnostics==listOf("PATCH_21_SORT_BEFORE_RANK") &&
                session.applied && session.invocationCount==1)
            if(saved==null)saved=session
            sessions++
            val sorted=listOf(short,long)
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                val out=wrapper.patch(day,sorted,r)
                must("E_PATCH21_SYNTH_MATCH_$i-$rank",
                    out.legacyChosen==out.correctedChosen &&
                    out.correctedChosen==sorted[rank-1] &&
                    !out.correctionApplied)
                unchanged++
            }
            val unmodified=manager.apply(day,sorted,ExactInt.ONE)
            must("E_PATCH21_SESSION_MATCH_$i",
                !unmodified.outcome.correctionApplied &&
                unmodified.outcome.correctedChosen==short)
            sessions++
        }
        must("E_PATCH21_SYNTH_COUNTS",
            altered==128 && unchanged==128 && sessions==128)
        println("STAGE43_SYNTHETIC_64_REVERSED_128_RANK_FIXED_64_SORTED_128_RANK_MATCH")
        println("STAGE43_MANAGER_128_SESSIONS_GREEN")

        val big=ExactInt.parse("1844674407370955161600000000000000000000000")
        val far=ExactInt.parse("-1000000000000000000000000000000000000000000")
        var triples=0;var rankFixed=0;var middleMatch=0
        for(i in 1..128){
            val g=big+(i*100L)
            val start=far+(i*20000L)
            val day=start+35L
            val long=candidate(g,start,750L)
            val middle=candidate(g+10L,start+5L,500L)
            val short=candidate(g+20L,start+10L,252L)
            val input=listOf(long,middle,short)
            val correct=normative(day,input)
            must("E_PATCH21_BIG_CANON_$i",correct==listOf(short,middle,long))
            for(rank in 1..3){
                val r=ExactInt.of(rank.toLong())
                val result=wrapper.patch(day,input,r)
                must("E_PATCH21_BIG_RANK_$i-$rank",
                    result.legacyChosen==input[rank-1] &&
                    result.correctedChosen==correct[rank-1] &&
                    result.correctionApplied==(rank!=2))
                if(rank==2)middleMatch++ else rankFixed++
            }
            triples++
        }
        must("E_PATCH21_BIG_TOTAL",
            triples==128 && rankFixed==256 && middleMatch==128)
        println("STAGE43_BIGINT_128_TRIPLES_256_CORRECTIONS_128_MIDDLE_MATCH")

        val g=ExactInt.ZERO
        val day=ExactInt.of(10)
        val valid=candidate(g,g,252L)
        rejects{wrapper.patch(day,emptyList(),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(
            Year5000TieCandidate(g,g,g,g+252L)),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(
            Year5000TieCandidate(g,g+6L,g+252L,g)),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(candidate(g,g,251L)),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(candidate(g,g,5779L)),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(valid),g)}
        rejects{wrapper.patch(day,listOf(valid),ExactInt.of(2))}
        val counters=manager.metrics.snapshot()
        val bootstrapCounters=manager.bootstrap.metrics.snapshot()
        rejects{manager.apply(day,emptyList(),ExactInt.ONE)}
        rejects{manager.apply(day,listOf(valid),g)}
        must("E_PATCH21_METRICS_UNCHANGED",
            counters["patch21.legacy.calls"]==128L &&
            counters["patch21.corrected.checks"]==128L &&
            counters["patch21.applied"]==128L &&
            bootstrapCounters["bootstrap.ready"]==128L &&
            manager.metrics.snapshot()==counters &&
            manager.bootstrap.metrics.snapshot()==bootstrapCounters)
        val s=saved?:error("E_PATCH21_SAVED_SESSION_MISSING")
        val oldOutcome=s.outcome
        val trace=s.branchTrace.toList()
        val code=try{manager.rejectReplay(s);"NO_ERROR"}
            catch(e:MonsterValidationException){e.machineCode}
        must("E_PATCH21_REPLAY",
            code=="E_PATCH21_CONTEXT_NOT_READY" &&
            s.outcome===oldOutcome &&
            s.branchTrace==trace &&
            manager.metrics.snapshot()==counters &&
            manager.bootstrap.metrics.snapshot()==bootstrapCounters)
        println("STAGE43_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE43_PATCH_NATIVE_GREEN")
    }
}
