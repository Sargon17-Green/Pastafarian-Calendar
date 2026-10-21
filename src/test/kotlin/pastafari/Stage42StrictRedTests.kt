package pastafari

/** Cam 42: mae rheng 1 ar restr anghywir yn wrthenghraifft fwriadol. */
object Stage42StrictRedTests {
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val original=NormativeCore.FOUNDATION_DAY
        val gate=ExactInt.ZERO
        val long=Year5000TieCandidate(gate,gate+6L,original,original+500L)
        val short=Year5000TieCandidate(gate+10L,gate+16L,
            original+5L,original+305L)
        val day=original+20L
        val old=LegacyYear5000PreSortRankAdapter()
            .chooseAtRank(day,listOf(long,short),ExactInt.ONE)
        val normativeFirst=listOf(long,short).sortedWith(
            compareBy<Year5000TieCandidate>{it.length}
                .thenBy{it.openGateDay}).first()
        check(old==normativeFirst){
            "E_DISCOVERY21_STRICT_PRE_SORT_RANK_RED"
        }
        error("E_DISCOVERY21_STRICT_MISSING_RED")
    }
}
