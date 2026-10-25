package pastafari

/** Cam 54: profion gwyrdd am anghysondeb hanesyddol a strict RED ar wahân. */
object Stage54Tests {
    private fun insist(id:String,ok:Boolean) { check(ok) { id } }
    private fun rejects(block:()->Unit) {
        try { block() } catch (_:IllegalArgumentException) { return }
        error("E_DISCOVERY27_GUARD_MISSING")
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
        val legacy=LegacyYear5000RankAsIndexAdapter()
        val manager=LegacyYear5000RankAsIndexManager()
        val oracle=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val all=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val a=ExactInt.of(i.toLong())
            val open=oracle.gates.get(a)
            for(width in 6..12) {
                val b=a+width.toLong()
                all.add(Year5000TieCandidate(a,b,open,oracle.gates.get(b)))
            }
        }
        val snapshot=all.toList()
        val sorted=reference(day,all)
        insist("E_DISCOVERY27_NATURAL_COUNT",
            all.size==231 && sorted.size>=2 && all==snapshot)
        var realRed=0
        for(rank in 1..sorted.size){
            val requested=ExactInt.of(rank.toLong())
            val read=legacy.oldChoose(day,sorted,requested)
            insist("E_DISCOVERY27_REAL_$rank",
                read.rank1==requested && read.count==sorted.size &&
                read.wrongIndex0==rank%sorted.size &&
                read.wrongChosen==sorted[rank%sorted.size] &&
                read.wrongChosen!=sorted[rank-1] &&
                read.wrappedAtEnd==(rank==sorted.size) && read.listReads==1)
            realRed++
        }
        val stream=NormativeCore.askBowl(
            NormativeCore.sauce(day,day),1,NormativeCore.SEAL_YEAR_5000)
        val rank=NormativeCore.chooseRankInt(stream,sorted.size)
        insist("E_DISCOVERY27_NATURAL_STREAM",
            legacy.oldChoose(day,sorted,ExactInt.of(rank.toLong())).wrongChosen !=
                sorted[rank-1] && oracle.year5000(day).openGateDay<day)
        println("STAGE54_REAL_231_PAIRS_RANK_POSITION_EXPECTED_RED")
        println("STAGE54_REAL_DIFFERENTIAL_COUNT_$realRed")

        var syntheticRed=0;var singletonMatch=0;var sessions=0
        var saved:LegacyYear5000RankAsIndexSession?=null
        for(i in 1..64) {
            val g=ExactInt.of(i*100L)
            val opening=ExactInt.of(i*100000L)
            val target=opening+20L
            val short=candidate(g,opening,300L)
            val long=candidate(g+10L,opening+1L,600L)
            val items=reference(target,listOf(long,short))
            insist("E_DISCOVERY27_SYNTH_SORT_$i",items==listOf(short,long))
            for(k in 1..2) {
                val r=ExactInt.of(k.toLong())
                val read=legacy.oldChoose(target,items,r)
                val session=manager.observe(target,items,r)
                insist("E_DISCOVERY27_SYNTH_$i-$k",
                    read.wrongChosen==items[k%2] &&
                    read.wrongChosen!=items[k-1] &&
                    session.outcome==read &&
                    session.trace==listOf("BOOT","DISCOVERY_27") &&
                    session.context.phase=="DISCOVERY_27" &&
                    session.context.status=="OBSERVED_YEAR5000_RANK_AS_INDEX" &&
                    session.diagnostics==
                        listOf("DISCOVERY_27_ONE_BASED_RANK_USED_AS_INDEX0"))
                if(saved==null)saved=session
                syntheticRed++;sessions++
            }
            val solo=legacy.oldChoose(target,listOf(short),ExactInt.ONE)
            insist("E_DISCOVERY27_SINGLETON_$i",
                solo.wrongChosen==short && solo.wrappedAtEnd)
            singletonMatch++
        }
        insist("E_DISCOVERY27_SYNTH_TOTAL",
            syntheticRed==128 && singletonMatch==64 && sessions==128)
        println("STAGE54_SYNTHETIC_128_EXPECTED_RED_64_SINGLETON_MATCH")
        println("STAGE54_MANAGER_128_SESSIONS_GREEN")

        val hugeG=ExactInt.parse("99999999999999999999999999999999999999999999999")
        val hugeD=ExactInt.parse("-9999999999999999999999999999999999999999999999")
        var bigRed=0;var bigWrap=0
        for(i in 1..128){
            val g=hugeG+i*100L
            val open=hugeD+i*10000L
            val target=open+50L
            val a=candidate(g,open,300L)
            val b=candidate(g+10L,open+1L,500L)
            val c=candidate(g+20L,open+2L,800L)
            val items=reference(target,listOf(c,b,a))
            insist("E_DISCOVERY27_BIG_SORT_$i",items==listOf(a,b,c))
            for(k in 1..3){
                val read=legacy.oldChoose(target,items,ExactInt.of(k.toLong()))
                insist("E_DISCOVERY27_BIG_$i-$k",
                    read.wrongChosen==items[k%3] &&
                    read.wrongChosen!=items[k-1] &&
                    read.wrappedAtEnd==(k==3))
                bigRed++
                if(k==3)bigWrap++
            }
        }
        insist("E_DISCOVERY27_BIG_TOTAL",bigRed==384 && bigWrap==128)
        println("STAGE54_BIGINT_128_TRIPLES_384_EXPECTED_RED_128_WRAPS")

        val zero=ExactInt.ZERO
        val target=ExactInt.of(30)
        val good=candidate(zero,zero,300L)
        val longer=candidate(zero+10L,zero+1L,500L)
        rejects { legacy.oldChoose(target,emptyList(),ExactInt.ONE) }
        rejects { legacy.oldChoose(target,listOf(good),zero) }
        rejects { legacy.oldChoose(target,listOf(good),ExactInt.of(-1)) }
        rejects { legacy.oldChoose(target,listOf(good),ExactInt.of(2)) }
        rejects { legacy.oldChoose(target,listOf(longer,good),ExactInt.ONE) }
        rejects { legacy.oldChoose(target,listOf(good,good),ExactInt.ONE) }
        rejects { legacy.oldChoose(target,listOf(good),
            ExactInt.parse("999999999999999999999")) }
        rejects { legacy.oldChoose(target,listOf(candidate(zero,zero,251L)),ExactInt.ONE) }
        rejects { legacy.oldChoose(target,listOf(candidate(zero,zero,5779L)),ExactInt.ONE) }
        rejects { legacy.oldChoose(zero,listOf(good),ExactInt.ONE) }
        rejects { legacy.oldChoose(target,listOf(
            Year5000TieCandidate(zero,zero+5L,zero,zero+300L)),ExactInt.ONE) }
        val before=manager.metrics.snapshot()
        val boot=manager.bootstrap.metrics.snapshot()
        rejects { manager.observe(target,listOf(good),ExactInt.of(2)) }
        rejects { manager.observe(target,listOf(longer,good),ExactInt.ONE) }
        insist("E_DISCOVERY27_METRICS",
            before["discovery27.historical.calls"]==128L &&
            before["discovery27.observed"]==128L &&
            boot["bootstrap.ready"]==128L &&
            manager.metrics.snapshot()==before &&
            manager.bootstrap.metrics.snapshot()==boot)
        val seen=saved?:error("E_DISCOVERY27_SESSION_MISSING")
        val code=try {manager.rejectReplay(seen);"NO_ERROR"}
            catch(e:MonsterValidationException){e.machineCode}
        insist("E_DISCOVERY27_REPLAY",
            code=="E_DISCOVERY27_CONTEXT_NOT_READY" &&
            manager.metrics.snapshot()==before &&
            manager.bootstrap.metrics.snapshot()==boot)
        println("STAGE54_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE54_DISCOVERY_EXPECTED_RED_PASS")
    }
}
