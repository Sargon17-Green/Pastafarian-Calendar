package pastafari

/** Cam 45: cymhwysedd cyn rheng, gan ddefnyddio'r oracl mewn profion yn unig. */
object Stage45Tests {
    private fun must(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try { block() } catch(_:IllegalArgumentException){return}
        error("E_PATCH22_EXPECTED_GUARD")
    }
    private fun candidate(
        gate:ExactInt,first:ExactInt,length:Long,width:Long=6L
    )=Year5000TieCandidate(gate,gate+width,first,first+length)

    private fun reference(
        day:ExactInt,items:List<Year5000TieCandidate>
    ):List<Year5000TieCandidate> = items.filter { c ->
        c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
        c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
        c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
        c.openGateDay<day && day<=c.closeGateDay
    }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
        .thenBy{it.openGateDay})

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val oracle=NormativeCalendar()
        val historical=LegacyYear5000UnfilteredRankAdapter()
        val wrapper=Year5000FilteredRankPatchWrapper()
        val manager=Year5000FilteredRankPatchManager()
        val foundation=NormativeCore.FOUNDATION_DAY
        val real=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val a=ExactInt.of(i.toLong())
            val start=oracle.gates.get(a)
            for(width in 1..12){
                val b=a+width.toLong()
                real.add(Year5000TieCandidate(a,b,start,oracle.gates.get(b)))
            }
        }
        val copy=real.toList()
        val realNorm=reference(foundation,real)
        must("E_PATCH22_REAL_NONEMPTY",real.size==396 &&
            realNorm.isNotEmpty() && realNorm.size<real.size)
        val rankChecks=listOf(1,(realNorm.size+1)/2,realNorm.size).distinct()
        for(rank in rankChecks){
            val r=ExactInt.of(rank.toLong())
            val outcome=wrapper.patch(foundation,real,r)
            must("E_PATCH22_REAL_RANK_$rank",
                outcome.correctedChosen==realNorm[rank-1] &&
                outcome.legacyChosen==historical.chooseUnfiltered(real,r) &&
                outcome.eligibleCandidateCount==realNorm.size &&
                outcome.discardedCandidateCount==396-realNorm.size &&
                outcome.correctionApplied==
                    (outcome.correctedChosen!=outcome.legacyChosen) &&
                outcome.historicalCalls==1 && outcome.correctedChecks==1 &&
                real==copy)
        }
        val year=oracle.year5000(foundation)
        must("E_PATCH22_ORACLE_YEAR",
            year.openGateDay<foundation &&
            foundation<=year.closeGateDay)
        println("STAGE45_REAL_GATE_396_PAIRS_RANKED_GREEN")

        var corrections=0;var matches=0;var sessions=0
        var saved:Year5000FilteredRankPatchSession?=null
        for(i in 1..64){
            val g=ExactInt.of(i*100L)
            val start=ExactInt.of(i*100000L)
            val target=start+20L
            val invalidShort=candidate(g,start,251)
            val validShort=candidate(g+10L,start+3L,300)
            val validLong=candidate(g+20L,start+7L,500)
            val invalidLong=candidate(g+30L,start+11L,5779)
            val mixed=listOf(validLong,invalidLong,validShort,invalidShort)
            val expected=reference(target,mixed)
            must("E_PATCH22_SYNTH_REFERENCE_$i",
                expected==listOf(validShort,validLong))
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                val result=wrapper.patch(target,mixed,r)
                val session=manager.apply(target,mixed,r)
                must("E_PATCH22_SYNTH_CORRECTION_$i-$rank",
                    result.legacyChosen!=expected[rank-1] &&
                    result.correctedChosen==expected[rank-1] &&
                    result.eligibleCandidateCount==2 &&
                    result.discardedCandidateCount==2 &&
                    result.correctionApplied &&
                    session.outcome==result &&
                    session.context.phase=="PATCH_22" &&
                    session.context.status=="PATCHED_YEAR5000_ELIGIBILITY_BEFORE_RANK" &&
                    session.branchTrace==listOf("BOOT","PATCH_22") &&
                    session.context.branchTrace==session.branchTrace &&
                    session.diagnostics==listOf("PATCH_22_FILTER_BEFORE_RANK") &&
                    session.applied && session.invocationCount==1)
                if(saved==null)saved=session
                corrections++;sessions++
            }
            val validOnly=listOf(validLong,validShort)
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                val out=wrapper.patch(target,validOnly,r)
                must("E_PATCH22_SYNTH_UNCHANGED_$i-$rank",
                    out.correctedChosen==expected[rank-1] &&
                    out.legacyChosen==out.correctedChosen &&
                    !out.correctionApplied && out.discardedCandidateCount==0)
                matches++
            }
        }
        must("E_PATCH22_SYNTH_COUNTS",
            corrections==128 && matches==128 && sessions==128)
        println("STAGE45_SYNTHETIC_128_CORRECTIONS_128_MATCH_GREEN")
        println("STAGE45_MANAGER_128_SESSIONS_GREEN")

        val huge=ExactInt.parse("184467440737095516160000000000000000000000")
        val far=ExactInt.parse("-100000000000000000000000000000000000000000")
        var bigPairs=0;var bigFixes=0;var invalidThird=0
        for(i in 1..128){
            val g=huge+i*100L
            val open=far+i*20000L
            val day=open+30L
            val invalid=candidate(g,open,251)
            val valid1=candidate(g+10L,open+5L,252)
            val valid2=candidate(g+20L,open+10L,500)
            val all=listOf(valid2,invalid,valid1)
            val ordered=reference(day,all)
            must("E_PATCH22_BIG_ORACLE_$i",ordered==listOf(valid1,valid2))
            for(rank in 1..2){
                val out=wrapper.patch(day,all,ExactInt.of(rank.toLong()))
                must("E_PATCH22_BIG_RANK_$i-$rank",
                    out.correctedChosen==ordered[rank-1] &&
                    out.correctedChosen!=out.legacyChosen &&
                    out.correctionApplied)
                bigFixes++
            }
            rejects{wrapper.patch(day,all,ExactInt.of(3))}
            invalidThird++
            bigPairs++
        }
        must("E_PATCH22_BIG_COUNTS",
            bigPairs==128 && bigFixes==256 && invalidThird==128)
        println("STAGE45_BIGINT_128_TRIPLES_256_CORRECTIONS_128_INVALID_RANK_REJECTS")

        val zero=ExactInt.ZERO
        val day=ExactInt.of(20)
        val lower=candidate(zero,zero,252)
        val upper=candidate(zero+10L,zero+2L,5778)
        val below=candidate(zero+20L,zero+4L,251)
        val above=candidate(zero+30L,zero+6L,5779)
        val tooFewGaps=candidate(zero+40L,zero+8L,300,5L)
        val onOpen=candidate(zero+50L,day,300)
        val expired=candidate(zero+60L,day-300L,252)
        val exactClosing=candidate(zero+70L,day-252L,252)
        val input=listOf(above,below,lower,upper,tooFewGaps,onOpen,expired,exactClosing)
        val eligible=reference(day,input)
        must("E_PATCH22_BOUNDARY_REFERENCE",
            eligible==listOf(exactClosing,lower,upper) &&
            wrapper.patch(day,input,ExactInt.ONE).correctedChosen==exactClosing &&
            wrapper.patch(day,input,ExactInt.of(3)).correctedChosen==upper &&
            wrapper.patch(day,input,ExactInt.of(3)).eligibleCandidateCount==3)
        println("STAGE45_YEAR_BOUNDS_AND_CLOSING_GATE_GREEN")

        rejects{wrapper.patch(day,emptyList(),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(
            Year5000TieCandidate(zero,zero,zero,zero+252L)),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(
            Year5000TieCandidate(zero,zero+6L,zero+252L,zero)),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(below,above),ExactInt.ONE)}
        rejects{wrapper.patch(day,listOf(lower),zero)}
        rejects{wrapper.patch(day,listOf(lower),ExactInt.of(2))}
        val counters=manager.metrics.snapshot()
        val boot=manager.bootstrap.metrics.snapshot()
        rejects{manager.apply(day,emptyList(),ExactInt.ONE)}
        rejects{manager.apply(day,listOf(below,above),ExactInt.ONE)}
        rejects{manager.apply(day,listOf(lower),zero)}
        must("E_PATCH22_GUARDS_NO_SIDE_EFFECT",
            counters["patch22.historical.calls"]==128L &&
            counters["patch22.corrected.checks"]==128L &&
            counters["patch22.applied"]==128L &&
            boot["bootstrap.ready"]==128L &&
            manager.metrics.snapshot()==counters &&
            manager.bootstrap.metrics.snapshot()==boot)
        val session=saved?:error("E_PATCH22_SAVED_SESSION_MISSING")
        val earlier=session.outcome
        val earlierTrace=session.branchTrace.toList()
        val code=try { manager.rejectReplay(session); "NO_ERROR" }
            catch(e:MonsterValidationException){ e.machineCode }
        must("E_PATCH22_REPLAY",
            code=="E_PATCH22_CONTEXT_NOT_READY" &&
            session.outcome===earlier && session.branchTrace==earlierTrace &&
            manager.metrics.snapshot()==counters &&
            manager.bootstrap.metrics.snapshot()==boot)
        println("STAGE45_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE45_PATCH_NATIVE_GREEN")
    }
}
