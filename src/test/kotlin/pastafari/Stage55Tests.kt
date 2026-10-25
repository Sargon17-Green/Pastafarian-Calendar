package pastafari

/** Cam 55 — PATCH 27: gwrthbrofion index0/rank1 a chadw'r graith. */
object Stage55Tests {
    private fun insist(id:String,ok:Boolean) { check(ok) { id } }
    private fun rejects(block:()->Unit) {
        try { block() } catch (_:IllegalArgumentException) { return }
        error("E_PATCH27_GUARD_MISSING")
    }
    private fun candidate(g:ExactInt,o:ExactInt,len:Long)=
        Year5000TieCandidate(g,g+6L,o,o+len)
    private fun reference(day:ExactInt,items:List<Year5000TieCandidate>)=
        items.filter { c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
        }.distinctBy { it.openGateIndex to it.closeGateIndex }
            .sortedWith(compareBy<Year5000TieCandidate>{it.length}
                .thenBy{it.openGateDay})

    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val patch=Year5000RankIndexPatchWrapper()
        val historical=LegacyYear5000RankAsIndexAdapter()
        val manager=Year5000RankIndexPatchManager()
        val oracle=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val all=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16) {
            val a=ExactInt.of(i.toLong())
            val open=oracle.gates.get(a)
            for(width in 6..12) {
                val b=a+width.toLong()
                all.add(Year5000TieCandidate(a,b,open,oracle.gates.get(b)))
            }
        }
        val snapshot=all.toList()
        val sorted=reference(day,all)
        insist("E_PATCH27_REAL_COUNT",all.size==231 &&
            sorted.size==43 && all==snapshot)
        var realGreen=0
        var realLegacyRed=0
        for(k in 1..sorted.size) {
            val rank=ExactInt.of(k.toLong())
            val out=patch.patch(day,sorted,rank)
            insist("E_PATCH27_REAL_RANK_$k",
                out.correctedIndex0==k-1 &&
                out.correctedChosen==sorted[k-1] &&
                out.historical==historical.oldChoose(day,sorted,rank) &&
                out.historical.wrongChosen==sorted[k%sorted.size] &&
                out.historical.wrongChosen!=out.correctedChosen &&
                out.correctionApplied &&
                out.historicalCalls==1 && out.correctedChecks==1)
            realGreen++;realLegacyRed++
        }
        insist("E_PATCH27_REAL_TOTAL",realGreen==43 && realLegacyRed==43)
        val stream=NormativeCore.askBowl(
            NormativeCore.sauce(day,day),1,NormativeCore.SEAL_YEAR_5000)
        val rank=NormativeCore.chooseRankInt(stream,sorted.size)
        insist("E_PATCH27_REAL_STREAM",
            patch.patch(day,sorted,ExactInt.of(rank.toLong())).correctedChosen==
                sorted[rank-1] &&
            oracle.year5000(day).openGateDay<day)
        println("STAGE55_REAL_231_PAIRS_43_CORRECTED_GREEN_43_LEGACY_RED")

        var synthGreen=0;var synthLegacyRed=0;var singletonMatch=0
        var sessions=0;var stored:Year5000RankIndexPatchSession?=null
        for(i in 1..64) {
            val g=ExactInt.of(i*100L)
            val open=ExactInt.of(i*100000L)
            val target=open+20L
            val short=candidate(g,open,300L)
            val long=candidate(g+10L,open+1L,600L)
            val items=reference(target,listOf(long,short))
            insist("E_PATCH27_SYNTH_SORT_$i",items==listOf(short,long))
            for(k in 1..2) {
                val rank1=ExactInt.of(k.toLong())
                val out=patch.patch(target,items,rank1)
                val session=manager.apply(target,items,rank1)
                insist("E_PATCH27_SYNTH_$i-$k",
                    out.correctedChosen==items[k-1] &&
                    out.correctedIndex0==k-1 &&
                    out.historical.wrongChosen==items[k%2] &&
                    out.historical.wrongChosen!=out.correctedChosen &&
                    out.correctionApplied &&
                    session.outcome==out &&
                    session.trace==listOf("BOOT","PATCH_27") &&
                    session.context.status=="PATCHED_YEAR5000_RANK_INDEX" &&
                    session.context.phase=="PATCH_27" &&
                    session.diagnostics==
                        listOf("PATCH_27_SUBTRACT_ONE_FROM_RANK1"))
                if(stored==null)stored=session
                synthGreen++;synthLegacyRed++;sessions++
            }
            val one=patch.patch(target,listOf(short),ExactInt.ONE)
            insist("E_PATCH27_SINGLETON_$i",
                one.correctedChosen==short &&
                one.historical.wrongChosen==short &&
                one.correctedIndex0==0 && !one.correctionApplied &&
                one.historical.wrappedAtEnd)
            singletonMatch++
        }
        insist("E_PATCH27_SYNTH_TOTAL",
            synthGreen==128 && synthLegacyRed==128 &&
            singletonMatch==64 && sessions==128)
        println("STAGE55_SYNTHETIC_128_CORRECTED_GREEN_128_LEGACY_RED_64_MATCH")
        println("STAGE55_MANAGER_128_SESSIONS_GREEN")

        val hugeG=ExactInt.parse("99999999999999999999999999999999999999999999999")
        val hugeD=ExactInt.parse("-9999999999999999999999999999999999999999999999")
        var bigGreen=0;var bigLegacyRed=0;var bigWrap=0
        for(i in 1..128) {
            val g=hugeG+i*100L
            val opening=hugeD+i*10000L
            val target=opening+50L
            val a=candidate(g,opening,300L)
            val b=candidate(g+10L,opening+1L,500L)
            val c=candidate(g+20L,opening+2L,800L)
            val items=reference(target,listOf(c,b,a))
            insist("E_PATCH27_BIG_SORT_$i",items==listOf(a,b,c))
            for(k in 1..3) {
                val out=patch.patch(target,items,ExactInt.of(k.toLong()))
                insist("E_PATCH27_BIG_$i-$k",
                    out.correctedChosen==items[k-1] &&
                    out.correctedIndex0==k-1 &&
                    out.historical.wrongChosen==items[k%3] &&
                    out.historical.wrongChosen!=out.correctedChosen &&
                    out.correctionApplied &&
                    out.historical.wrappedAtEnd==(k==3))
                bigGreen++;bigLegacyRed++
                if(k==3)bigWrap++
            }
        }
        insist("E_PATCH27_BIG_TOTAL",bigGreen==384 &&
            bigLegacyRed==384 && bigWrap==128)
        println("STAGE55_BIGINT_128_TRIPLES_384_GREEN_384_LEGACY_RED_128_WRAPS")

        // Cywiro'r tie-break a'r ffiniau hyd cyn dewis rank1.
        var tieGreen=0
        for(i in 1..64) {
            val g=ExactInt.of(i*1000L)
            val early=ExactInt.of(i*10000L)
            val target=early+30L
            val a=candidate(g,early,500L)
            val b=candidate(g+10L,early+10L,500L)
            val items=reference(target,listOf(b,a))
            insist("E_PATCH27_TIE_SORT_$i",items==listOf(a,b))
            for(k in 1..2) {
                val out=patch.patch(target,items,ExactInt.of(k.toLong()))
                insist("E_PATCH27_TIE_$i-$k",
                    out.correctedChosen==items[k-1] &&
                    out.historical.wrongChosen==items[k%2])
                tieGreen++
            }
        }
        insist("E_PATCH27_TIE_TOTAL",tieGreen==128)
        println("STAGE55_TIE_64_PAIRS_128_RANKS_GREEN")

        val zero=ExactInt.ZERO
        val target=ExactInt.of(30)
        val valid=candidate(zero,zero,300L)
        val longer=candidate(zero+10L,zero+1L,500L)
        val boundaries=listOf(
            candidate(zero,zero,252L),
            candidate(zero+10L,zero+1L,5778L)
        )
        val bounded=patch.patch(target,boundaries,ExactInt.ONE)
        insist("E_PATCH27_EDGE_LENGTHS",
            bounded.correctedChosen==boundaries[0] &&
            bounded.historical.wrongChosen==boundaries[1])
        rejects {patch.patch(target,emptyList(),ExactInt.ONE)}
        rejects {patch.patch(target,listOf(valid),zero)}
        rejects {patch.patch(target,listOf(valid),ExactInt.of(-1))}
        rejects {patch.patch(target,listOf(valid),ExactInt.of(2))}
        rejects {patch.patch(target,listOf(longer,valid),ExactInt.ONE)}
        rejects {patch.patch(target,listOf(valid,valid),ExactInt.ONE)}
        rejects {patch.patch(target,listOf(valid),
            ExactInt.parse("999999999999999999999"))}
        rejects {patch.patch(target,listOf(candidate(zero,zero,251L)),ExactInt.ONE)}
        rejects {patch.patch(target,listOf(candidate(zero,zero,5779L)),ExactInt.ONE)}
        rejects {patch.patch(zero,listOf(valid),ExactInt.ONE)}
        rejects {patch.patch(target,listOf(
            Year5000TieCandidate(zero,zero+5L,zero,zero+300L)),ExactInt.ONE)}
        val before=manager.metrics.snapshot()
        val boot=manager.bootstrap.metrics.snapshot()
        rejects {manager.apply(target,listOf(valid),ExactInt.of(2))}
        rejects {manager.apply(target,listOf(longer,valid),ExactInt.ONE)}
        insist("E_PATCH27_METRICS",
            before["patch27.historical.calls"]==128L &&
            before["patch27.corrected.checks"]==128L &&
            before["patch27.applied"]==128L &&
            boot["bootstrap.ready"]==128L &&
            manager.metrics.snapshot()==before &&
            manager.bootstrap.metrics.snapshot()==boot)
        val prior=stored?:error("E_PATCH27_SESSION_MISSING")
        val code=try {manager.rejectReplay(prior);"NO_ERROR"}
            catch(e:MonsterValidationException){e.machineCode}
        insist("E_PATCH27_REPLAY",
            code=="E_PATCH27_CONTEXT_NOT_READY" &&
            manager.metrics.snapshot()==before &&
            manager.bootstrap.metrics.snapshot()==boot)
        println("STAGE55_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE55_PATCH_NATIVE_GREEN")
    }
}
