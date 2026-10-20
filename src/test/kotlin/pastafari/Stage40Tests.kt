package pastafari

/** Cam 40: gwahaniaeth rhengo ar gyfartaledd hyd â giatiau agor gwahanol. */
object Stage40Tests {
    private fun must(id: String, ok: Boolean) { check(ok) { id } }
    private fun rejects(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return }
        error("E_DISCOVERY20_MISSING_INPUT_GUARD")
    }
    private fun reference(
        day: ExactInt,
        candidates: List<Year5000TieCandidate>
    ): List<Year5000TieCandidate> = candidates.filter { c ->
        c.closeGateIndex - c.openGateIndex >= ExactInt.of(6) &&
            c.length >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay < day && day <= c.closeGateDay
    }.sortedWith(compareBy<Year5000TieCandidate> { it.length }
        .thenBy { it.openGateDay })

    private fun candidate(
        gate: ExactInt,
        start: ExactInt,
        length: Long
    ): Year5000TieCandidate = Year5000TieCandidate(
        gate,gate+6L,start,start+length
    )

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val adapter = LegacyYear5000TieBreakAdapter()
        val oracle = NormativeCalendar()
        val foundation = NormativeCore.FOUNDATION_DAY
        val natural = mutableListOf<Year5000TieCandidate>()
        var realPairs = 0
        for (i in -16..16) {
            val a = ExactInt.of(i.toLong())
            val start = oracle.gates.get(a)
            for (width in 6..12) {
                val b = a + width.toLong()
                natural.add(Year5000TieCandidate(a,b,start,oracle.gates.get(b)))
                realPairs++
            }
        }
        val correctReal = reference(foundation,natural)
        val oldReal = adapter.order(foundation,natural)
        must("E_DISCOVERY20_REAL_CANDIDATES",
            realPairs == 231 && correctReal.isNotEmpty() &&
            oldReal.size == correctReal.size &&
            oldReal.toSet() == correctReal.toSet() &&
            oldReal.zipWithNext().all { (x,y) -> x.length <= y.length })
        val sortedByNormative = correctReal.sortedWith(
            compareBy<Year5000TieCandidate> { it.length }
                .thenBy { it.openGateDay })
        must("E_DISCOVERY20_REAL_ORACLE",correctReal == sortedByNormative)
        val oracleSelected = oracle.year5000(foundation)
        must("E_DISCOVERY20_YEAR5000_ORACLE",
            oracleSelected.openGateDay < foundation &&
            foundation <= oracleSelected.closeGateDay)
        println("STAGE40_REAL_GATE_ORACLE_231_PAIRS_GREEN")

        var tiedRed=0; var untiedMatch=0
        for (i in 1..64) {
            val gate=ExactInt.of((i*100).toLong())
            val start=ExactInt.of((i*100000L))
            val length=252L + (i*37L)%5527L
            val low = candidate(gate,start,length)
            val high = candidate(gate+10L,start+7L,length)
            val day=start+12L
            val tied=listOf(high,low)
            val correct=reference(day,tied)
            val historical=adapter.order(day,tied)
            must("E_DISCOVERY20_TIED_$i",
                correct==listOf(low,high) &&
                historical==listOf(high,low) &&
                adapter.chooseAtRank(day,tied,ExactInt.ONE)==high &&
                adapter.chooseAtRank(day,tied,ExactInt.of(2))==low &&
                adapter.order(day,tied.reversed())==historical)
            tiedRed++
            val untied=listOf(
                low,
                candidate(gate+10L,start+7L,length+1L)
            )
            val correctUntied=reference(day,untied)
            val oldUntied=adapter.order(day,untied)
            must("E_DISCOVERY20_UNTIED_$i",
                correctUntied==oldUntied &&
                correctUntied==listOf(low,untied[1]))
            untiedMatch++
        }
        must("E_DISCOVERY20_SYNTH_COUNTS",tiedRed==64 && untiedMatch==64)
        println("STAGE40_SYNTHETIC_64_EXPECTED_RED_64_MATCH")

        val huge=ExactInt.parse("1844674407370955161600000000000000000000000000")
        val far=ExactInt.parse("-1000000000000000000000000000000000000000000")
        var widePair=0;var wideRankRed=0
        for (i in 1..128) {
            val gate=huge+(i*100L)
            val start=far+(i*20000L)
            val length=252L+(i*31L)%5527L
            val low=candidate(gate,start,length)
            val high=candidate(gate+10L,start+8L,length)
            val day=start+15L
            val input=listOf(low,high)
            val ordered=reference(day,input)
            val old=adapter.order(day,input)
            must("E_DISCOVERY20_BIG_SORT_$i",
                ordered==listOf(low,high) && old==listOf(high,low))
            for (rank in 1..2) {
                val r=ExactInt.of(rank.toLong())
                val actual=adapter.chooseAtRank(day,input,r)
                val expected=ordered[rank-1]
                must("E_DISCOVERY20_BIG_RANK_$i-$rank",actual!=expected)
                wideRankRed++
            }
            widePair++
        }
        must("E_DISCOVERY20_BIG_COUNTS",widePair==128 && wideRankRed==256)
        println("STAGE40_BIGINT_128_PAIRS_256_EXPECTED_RED")

        val g=ExactInt.ZERO
        val day=ExactInt.of(10)
        val valid=candidate(g,g,252)
        rejects { adapter.order(day,emptyList()) }
        rejects { adapter.order(day,listOf(
            Year5000TieCandidate(g,g,g,g+252L))) }
        rejects { adapter.order(day,listOf(
            Year5000TieCandidate(g,g+6L,g+252L,g))) }
        rejects { adapter.order(day,listOf(candidate(g,g,251))) }
        rejects { adapter.order(day,listOf(candidate(g,g,5779))) }
        rejects { adapter.chooseAtRank(day,listOf(valid),g) }
        rejects { adapter.chooseAtRank(day,listOf(valid),ExactInt.of(2)) }
        println("STAGE40_INPUT_GUARDS_GREEN")
        println("STAGE40_DISCOVERY_EXPECTED_RED_PASS")
    }
}
