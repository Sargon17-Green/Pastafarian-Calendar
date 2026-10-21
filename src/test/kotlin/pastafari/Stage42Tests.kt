package pastafari

/** Cam 42: gwirio bod y rheng yn cael ei gymhwyso ar ôl y trefnu. */
object Stage42Tests {
    private fun insist(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try { block() } catch(_:IllegalArgumentException){return}
        error("E_DISCOVERY21_MISSING_GUARD")
    }
    private fun candidate(
        gate:ExactInt, start:ExactInt, length:Long
    )=Year5000TieCandidate(gate,gate+6L,start,start+length)
    private fun reference(
        day:ExactInt, input:List<Year5000TieCandidate>
    ):List<Year5000TieCandidate> = input.filter { c ->
        c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
    }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
        .thenBy{it.openGateDay})

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val historical=LegacyYear5000PreSortRankAdapter()
        val original=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        // Ymchwil ar giatiau go iawn. Nid oes rhaid i'r enghreifftiau hyn
        // gynnwys cyfartaledd: daw'r gwrthenghreifftiau gwarantedig isod.
        val natural=mutableListOf<Year5000TieCandidate>()
        val year=original.year5000(day)
        insist("E_DISCOVERY21_SELECTED_YEAR5000",year.openGateDay<day &&
            day<=year.closeGateDay)
        for(i in -16..16){
            val g=ExactInt.of(i.toLong())
            val open=original.gates.get(g)
            for(width in 6..12){
                val b=g+width.toLong()
                natural.add(Year5000TieCandidate(g,b,open,original.gates.get(b)))
            }
        }
        val before=natural.toList()
        val realSorted=reference(day,natural)
        val realEncounter=historical.eligibleInEncounterOrder(day,natural)
        insist("E_DISCOVERY21_REAL_ELIGIBLE",
            natural.size==231 && natural==before &&
            realSorted.isNotEmpty() &&
            realSorted.toSet()==realEncounter.toSet() &&
            realSorted.size==realEncounter.size)
        for(rank in 1..minOf(8,realEncounter.size)){
            val actual=historical.chooseAtRank(day,natural,ExactInt.of(rank.toLong()))
            insist("E_DISCOVERY21_REAL_RANK_$rank",
                actual==realEncounter[rank-1])
        }
        if(realSorted.size>1){
            val reversed=realSorted.reversed()
            insist("E_DISCOVERY21_REAL_REVERSE_WITNESS",
                historical.chooseAtRank(day,reversed,ExactInt.ONE)==reversed.first() &&
                reversed.first()!=realSorted.first())
        }
        println("STAGE42_REAL_GATE_231_PAIRS_ORACLE_GREEN")

        var redCases=0;var redRanks=0;var matchCases=0;var matchRanks=0
        for(i in 1..64){
            val g=ExactInt.of(i*100L)
            val open=ExactInt.of(i*100000L)
            val dayAt=open+20L
            val long=candidate(g,open,600L+(i%11))
            val short=candidate(g+10L,open+5L,300L+(i%11))
            val unsorted=listOf(long,short)
            val canon=reference(dayAt,unsorted)
            insist("E_DISCOVERY21_UNSORTED_$i",canon==listOf(short,long))
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                val old=historical.chooseAtRank(dayAt,unsorted,r)
                insist("E_DISCOVERY21_RED_$i-$rank",old!=canon[rank-1])
                redRanks++
            }
            redCases++
            val sorted=listOf(short,long)
            insist("E_DISCOVERY21_ALREADY_SORTED_$i",
                reference(dayAt,sorted)==sorted)
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                insist("E_DISCOVERY21_MATCH_$i-$rank",
                    historical.chooseAtRank(dayAt,sorted,r)==sorted[rank-1])
                matchRanks++
            }
            matchCases++
        }
        insist("E_DISCOVERY21_SYNTH_COUNTS",
            redCases==64 && redRanks==128 &&
            matchCases==64 && matchRanks==128)
        println("STAGE42_SYNTHETIC_RED_64_CASES_128_RANKS_MATCH_64_CASES_128_RANKS")

        val huge=ExactInt.parse("1844674407370955161600000000000000000000000000")
        val far=ExactInt.parse("-1000000000000000000000000000000000000000000")
        var bigCases=0;var red=0;var middleMatch=0
        for(i in 1..128){
            val g=huge+(i*100L)
            val start=far+(i*20000L)
            val target=start+35L
            val long=candidate(g,start,750L)
            val middle=candidate(g+10L,start+5L,500L)
            val short=candidate(g+20L,start+10L,252L)
            val input=listOf(long,middle,short)
            val correct=reference(target,input)
            insist("E_DISCOVERY21_BIG_CANON_$i",
                correct==listOf(short,middle,long))
            for(rank in 1..3){
                val chosen=historical.chooseAtRank(
                    target,input,ExactInt.of(rank.toLong()))
                if(rank==2){
                    insist("E_DISCOVERY21_BIG_MIDDLE_$i",chosen==middle)
                    middleMatch++
                } else {
                    insist("E_DISCOVERY21_BIG_RED_$i-$rank",
                        chosen!=correct[rank-1])
                    red++
                }
            }
            bigCases++
        }
        insist("E_DISCOVERY21_BIG_COUNTS",
            bigCases==128 && red==256 && middleMatch==128)
        println("STAGE42_BIGINT_128_TRIPLES_256_RED_128_MIDDLE_MATCH")

        val zero=ExactInt.ZERO
        val ten=ExactInt.of(10)
        val good=candidate(zero,zero,252L)
        rejects{historical.eligibleInEncounterOrder(ten,emptyList())}
        rejects{historical.eligibleInEncounterOrder(ten,listOf(
            Year5000TieCandidate(zero,zero,zero,zero+252L)))}
        rejects{historical.eligibleInEncounterOrder(ten,listOf(
            Year5000TieCandidate(zero,zero+6L,zero+252L,zero)))}
        rejects{historical.eligibleInEncounterOrder(ten,listOf(
            candidate(zero,zero,251L)))}
        rejects{historical.eligibleInEncounterOrder(ten,listOf(
            candidate(zero,zero,5779L)))}
        rejects{historical.chooseAtRank(ten,listOf(good),zero)}
        rejects{historical.chooseAtRank(ten,listOf(good),ExactInt.of(2))}
        // Anamlwg: nid yw'r hen gyflwr yn newid y rhestr wreiddiol.
        insist("E_DISCOVERY21_INPUT_NOT_MUTATED",natural==before)
        println("STAGE42_INPUT_GUARDS_AND_OWNERSHIP_PASS")
        println("STAGE42_DISCOVERY_EXPECTED_RED_PASS")
    }
}
