package pastafari

/** Cam 46 — canfod ailgyfrif pâr clwyd yn y rhestr flwyddyn 5000. */
object Stage46Tests {
    private fun must(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit) {
        try {block()} catch(_:IllegalArgumentException){return}
        error("E_DISCOVERY23_GUARD_MISSING")
    }
    private fun candidate(
        gate:ExactInt, open:ExactInt, length:Long
    ):Year5000TieCandidate = Year5000TieCandidate(
        gate,gate+6L,open,open+length
    )
    /** Yr oracl safonol a chynnwys unigryw y parau yma mewn profion yn unig. */
    private fun reference(
        day:ExactInt,
        items:List<Year5000TieCandidate>
    ):List<Year5000TieCandidate> = items.filter { c ->
        c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
    }.distinctBy { it.openGateIndex to it.closeGateIndex }
        .sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy{it.openGateDay})

    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val adapter=LegacyYear5000RepeatedCandidateAdapter()
        val original=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val natural=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16) {
            val a=ExactInt.of(i.toLong())
            val open=original.gates.get(a)
            for(width in 6..12) {
                val b=a+width.toLong()
                natural.add(Year5000TieCandidate(a,b,open,original.gates.get(b)))
            }
        }
        val before=natural.toList()
        val expected=reference(day,natural)
        val withOverlap=adapter.candidatesWithOverlap(day,natural)
        must("E_DISCOVERY23_REAL_231_PAIRS",
            natural.size==231 &&
            expected.isNotEmpty() &&
            expected.map { it.openGateIndex to it.closeGateIndex }.distinct().size==expected.size &&
            natural==before &&
            withOverlap.size==expected.size+1 &&
            withOverlap[0]==expected.first() &&
            withOverlap[1]==expected.first() &&
            withOverlap.drop(1)==expected &&
            (expected.size==1 ||
                adapter.chooseAtRank(day,natural,ExactInt.of(2))!=expected[1]))
        val year=original.year5000(day)
        must("E_DISCOVERY23_REAL_ORACLE_YEAR",
            year.openGateDay<day && day<=year.closeGateDay)
        println("STAGE46_REAL_231_PAIRS_DUPLICATE_RED_GREEN")

        var red=0;var match=0;var extraRank=0
        for(i in 1..64) {
            val g=ExactInt.of(i*100L)
            val start=ExactInt.of(i*100000L)
            val target=start+25L
            val short=candidate(g,start,252L+i%100)
            val long=candidate(g+10L,start+7L,700L+i%100)
            val input=listOf(long,short)
            val save=input.toList()
            val correct=reference(target,input)
            must("E_DISCOVERY23_SYNTH_SORT_$i",
                correct==listOf(short,long) &&
                adapter.candidatesWithOverlap(target,input)==listOf(short,short,long))
            must("E_DISCOVERY23_SYNTH_MATCH_$i",
                adapter.chooseAtRank(target,input,ExactInt.ONE)==correct.first())
            match++
            must("E_DISCOVERY23_SYNTH_RED_$i",
                adapter.chooseAtRank(target,input,ExactInt.of(2))!=correct[1])
            red++
            must("E_DISCOVERY23_SYNTH_EXTRA_$i",
                adapter.chooseAtRank(target,input,ExactInt.of(3))==correct[1] &&
                correct.size==2 && input==save)
            extraRank++
        }
        must("E_DISCOVERY23_SYNTH_TOTAL",
            red==64 && match==64 && extraRank==64)
        println("STAGE46_SYNTHETIC_64_RED_64_MATCH_64_EXTRA_RANK")

        val huge=ExactInt.parse("1844674407370955161600000000000000000000")
        val far=ExactInt.parse("-1000000000000000000000000000000000000000")
        var triples=0;var rankRed=0;var lastValidOnlyLegacy=0
        for(i in 1..128) {
            val g=huge+i*100L
            val start=far+i*20000L
            val target=start+30L
            val short=candidate(g,start,252L)
            val middle=candidate(g+10L,start+8L,500L)
            val long=candidate(g+20L,start+14L,800L)
            val input=listOf(long,middle,short)
            val correct=reference(target,input)
            val wrong=adapter.candidatesWithOverlap(target,input)
            must("E_DISCOVERY23_BIG_ORDER_$i",
                correct==listOf(short,middle,long) &&
                wrong==listOf(short,short,middle,long))
            for(rank in 2..3) {
                val observed=adapter.chooseAtRank(
                    target,input,ExactInt.of(rank.toLong()))
                must("E_DISCOVERY23_BIG_RED_$i-$rank",
                    observed!=correct[rank-1])
                rankRed++
            }
            must("E_DISCOVERY23_BIG_EXTRA_$i",
                adapter.chooseAtRank(target,input,ExactInt.of(4))==long &&
                correct.size==3)
            lastValidOnlyLegacy++
            triples++
        }
        must("E_DISCOVERY23_BIG_COUNTS",
            triples==128 && rankRed==256 && lastValidOnlyLegacy==128)
        println("STAGE46_BIGINT_128_TRIPLES_256_RED_128_EXTRA_RANK")

        val g=ExactInt.ZERO
        val target=ExactInt.of(30)
        val good=candidate(g,g,300L)
        val invalidShort=candidate(g+10L,g+2L,251L)
        val invalidLong=candidate(g+20L,g+7L,5779L)
        val invalidGap=Year5000TieCandidate(g+30L,g+35L,g+9L,g+400L)
        must("E_DISCOVERY23_ELIGIBILITY",
            adapter.candidatesWithOverlap(target,
                listOf(invalidShort,invalidLong,invalidGap,good))==
                    listOf(good,good))
        rejects {adapter.candidatesWithOverlap(target,emptyList())}
        rejects {adapter.candidatesWithOverlap(target,listOf(
            Year5000TieCandidate(g,g,g,g+300L)))}
        rejects {adapter.candidatesWithOverlap(target,listOf(
            Year5000TieCandidate(g,g+6L,g+300L,g)))}
        rejects {adapter.candidatesWithOverlap(target,listOf(invalidShort))}
        rejects {adapter.chooseAtRank(target,listOf(good),g)}
        rejects {adapter.chooseAtRank(target,listOf(good),ExactInt.of(3))}
        println("STAGE46_INPUT_GUARDS_AND_BOUNDARIES_GREEN")
        println("STAGE46_DISCOVERY_EXPECTED_RED_PASS")
    }
}
