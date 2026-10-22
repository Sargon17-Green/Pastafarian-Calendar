package pastafari

/** Cam 44: gorfodi hidlo cymhwysedd cyn trefnu a defnyddio rheng y flwyddyn. */
object Stage44Tests {
    private fun insist(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try {block()} catch(_:IllegalArgumentException){return}
        error("E_DISCOVERY22_GUARD_MISSING")
    }
    private fun candidate(
        gate:ExactInt,first:ExactInt,length:Long,
        width:Long=6L
    ):Year5000TieCandidate = Year5000TieCandidate(
        gate,gate+width,first,first+length
    )
    private fun normative(
        day:ExactInt,candidates:List<Year5000TieCandidate>
    ):List<Year5000TieCandidate> = candidates.filter { c ->
        c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
    }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
        .thenBy{it.openGateDay})

    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val legacy=LegacyYear5000UnfilteredRankAdapter()
        val oracle=NormativeCalendar()
        val origin=NormativeCore.FOUNDATION_DAY
        val natural=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val g=ExactInt.of(i.toLong())
            val open=oracle.gates.get(g)
            for(width in 1..12){
                val b=g+width.toLong()
                natural.add(Year5000TieCandidate(
                    g,b,open,oracle.gates.get(b)))
            }
        }
        val snapshot=natural.toList()
        val norm=normative(origin,natural)
        val all=legacy.allCandidatesSorted(natural)
        insist("E_DISCOVERY22_REAL_COUNTS",
            natural.size==396 && norm.isNotEmpty() &&
            norm.size<all.size && natural==snapshot &&
            all.size==396 && all==all.sortedWith(
                compareBy<Year5000TieCandidate>{it.length}
                    .thenBy{it.openGateDay}) &&
            norm.all{legacy.accepts(origin,it)})
        for(rank in listOf(1,(norm.size+1)/2,norm.size).distinct()){
            val r=ExactInt.of(rank.toLong())
            insist("E_DISCOVERY22_REAL_RANK_$rank",
                legacy.chooseUnfiltered(natural,r)==all[rank-1] &&
                norm[rank-1] in all)
        }
        val chosen=oracle.year5000(origin)
        insist("E_DISCOVERY22_YEAR5000_ORACLE",
            chosen.openGateDay<origin && origin<=chosen.closeGateDay)
        println("STAGE44_REAL_GATE_396_PAIRS_ORACLE_GREEN")

        var red=0;var matched=0;var scenarios=0
        for(i in 1..64){
            val g=ExactInt.of(i*100L)
            val start=ExactInt.of(i*100000L)
            val day=start+20L
            val invalidShort=candidate(g,start,251L)
            val validShort=candidate(g+10L,start+3L,300L)
            val validLong=candidate(g+20L,start+7L,500L)
            val invalidLong=candidate(g+30L,start+11L,5779L)
            val mixed=listOf(validLong,invalidLong,validShort,invalidShort)
            val correct=normative(day,mixed)
            insist("E_DISCOVERY22_SYNTH_CANON_$i",
                correct==listOf(validShort,validLong))
            val old=legacy.allCandidatesSorted(mixed)
            insist("E_DISCOVERY22_SYNTH_OLD_$i",
                old==listOf(invalidShort,validShort,validLong,invalidLong))
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                val chosenOld=legacy.chooseUnfiltered(mixed,r)
                insist("E_DISCOVERY22_SYNTH_DIFF_$i-$rank",
                    chosenOld!=correct[rank-1])
                red++
            }
            val onlyValid=listOf(validLong,validShort)
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                insist("E_DISCOVERY22_SYNTH_MATCH_$i-$rank",
                    legacy.chooseUnfiltered(onlyValid,r)==correct[rank-1])
                matched++
            }
            insist("E_DISCOVERY22_INPUT_STABLE_$i",
                mixed==listOf(validLong,invalidLong,validShort,invalidShort))
            scenarios++
        }
        insist("E_DISCOVERY22_SYNTH_COUNTS",
            scenarios==64 && red==128 && matched==128)
        println("STAGE44_SYNTHETIC_64_CASES_128_EXPECTED_RED_128_MATCH")

        val huge=ExactInt.parse("184467440737095516160000000000000000000000")
        val far=ExactInt.parse("-100000000000000000000000000000000000000000")
        var big=0;var bigRed=0;var invalidThird=0
        for(i in 1..128){
            val g=huge+i*100L
            val start=far+i*20000L
            val day=start+30L
            val invalid=candidate(g,start,251L)
            val good1=candidate(g+10L,start+5L,252L)
            val good2=candidate(g+20L,start+10L,500L)
            val allInput=listOf(good2,invalid,good1)
            val sorted=normative(day,allInput)
            insist("E_DISCOVERY22_BIG_REFERENCE_$i",
                sorted==listOf(good1,good2))
            for(rank in 1..2){
                val r=ExactInt.of(rank.toLong())
                insist("E_DISCOVERY22_BIG_DIFF_$i-$rank",
                    legacy.chooseUnfiltered(allInput,r)!=sorted[rank-1])
                bigRed++
            }
            insist("E_DISCOVERY22_BIG_LAST_$i",
                legacy.chooseUnfiltered(allInput,ExactInt.of(3))==good2 &&
                legacy.allCandidatesSorted(allInput).size==3 &&
                sorted.size==2)
            invalidThird++
            big++
        }
        insist("E_DISCOVERY22_BIG_COUNTS",
            big==128 && bigRed==256 && invalidThird==128)
        println("STAGE44_BIGINT_128_CASES_256_EXPECTED_RED_128_INVALID_THIRD_RANK")

        val g=ExactInt.ZERO
        val day=ExactInt.of(20)
        val below=candidate(g,g,251L)
        val lower=candidate(g,g,252L)
        val upper=candidate(g,g,5778L)
        val above=candidate(g,g,5779L)
        val five=candidate(g,g,500L,5L)
        val onOpening=candidate(g,day,252L)
        val alreadyClosed=candidate(g,day-300L,252L)
        insist("E_DISCOVERY22_ELIGIBILITY_BOUNDS",
            !legacy.accepts(day,below) && legacy.accepts(day,lower) &&
            legacy.accepts(day,upper) && !legacy.accepts(day,above) &&
            !legacy.accepts(day,five) &&
            !legacy.accepts(day,onOpening) &&
            !legacy.accepts(day,alreadyClosed) &&
            normative(day,listOf(below,lower,upper,above,five,
                onOpening,alreadyClosed))==listOf(lower,upper))
        println("STAGE44_ELIGIBILITY_BOUNDARIES_GREEN")

        rejects {legacy.allCandidatesSorted(emptyList())}
        rejects {legacy.allCandidatesSorted(listOf(
            Year5000TieCandidate(g,g,g,g+252L)))}
        rejects {legacy.allCandidatesSorted(listOf(
            Year5000TieCandidate(g,g+6L,g+252L,g)))}
        rejects {legacy.chooseUnfiltered(listOf(lower),g)}
        rejects {legacy.chooseUnfiltered(listOf(lower),ExactInt.of(2))}
        val original=listOf(lower,upper)
        insist("E_DISCOVERY22_NO_MUTATION",
            legacy.allCandidatesSorted(original)==original &&
            original==listOf(lower,upper))
        println("STAGE44_GUARDS_AND_IMMUTABILITY_GREEN")
        println("STAGE44_DISCOVERY_EXPECTED_RED_PASS")
    }
}
