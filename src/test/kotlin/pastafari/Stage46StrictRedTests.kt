package pastafari

/** Cam 46: gwrthenghraifft fwriadol ar yr ail ymgeisydd. */
object Stage46StrictRedTests {
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val g=ExactInt.ZERO
        val start=NormativeCore.FOUNDATION_DAY
        val short=Year5000TieCandidate(g,g+6L,start,start+300L)
        val long=Year5000TieCandidate(g+10L,g+16L,start+8L,start+708L)
        val target=start+30L
        val historical=LegacyYear5000RepeatedCandidateAdapter()
            .chooseAtRank(target,listOf(long,short),ExactInt.of(2))
        val canonical=listOf(long,short).sortedWith(
            compareBy<Year5000TieCandidate>{it.length}
                .thenBy{it.openGateDay})[1]
        check(historical==canonical) {
            "E_DISCOVERY23_STRICT_REPEATED_PAIR_RED"
        }
        error("E_DISCOVERY23_STRICT_RED_MISSING")
    }
}
