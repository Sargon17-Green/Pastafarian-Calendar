package pastafari

/** Cam 44: methiant bwriadol o ddewis diwrnod annilys yn rheng gyntaf. */
object Stage44StrictRedTests {
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val g=ExactInt.ZERO
        val open=NormativeCore.FOUNDATION_DAY
        val invalid=Year5000TieCandidate(g,g+6L,open,open+251L)
        val valid=Year5000TieCandidate(g+10L,g+16L,open+5L,open+305L)
        val legacy=LegacyYear5000UnfilteredRankAdapter()
        val old=legacy.chooseUnfiltered(listOf(valid,invalid),ExactInt.ONE)
        val norm=listOf(valid,invalid).filter{c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
                c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
                c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
                c.openGateDay<open+20L && open+20L<=c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy{it.openGateDay})
        check(norm.size==1 && norm[0]==valid)
        check(old==norm[0]){
            "E_DISCOVERY22_STRICT_FILTER_BEFORE_RANK_RED"
        }
        error("E_DISCOVERY22_STRICT_MISSING_RED")
    }
}
