package pastafari

/** Cam 40: dylai'r honiad ffug ar drefn gyfartal fethu'n fwriadol. */
object Stage40StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val old=LegacyYear5000TieBreakAdapter()
        val g=ExactInt.ZERO
        val open=NormativeCore.FOUNDATION_DAY
        val a=Year5000TieCandidate(g,g+6L,open,open+252L)
        val b=Year5000TieCandidate(g+10L,g+16L,open+7L,open+259L)
        val day=open+12L
        val originalNormativeFirst=listOf(a,b).sortedWith(
            compareBy<Year5000TieCandidate> { it.length }
                .thenBy { it.openGateDay }).first()
        val legacyFirst=old.chooseAtRank(day,listOf(b,a),ExactInt.ONE)
        check(legacyFirst==originalNormativeFirst) {
            "E_DISCOVERY20_STRICT_TIE_ORDER_RED"
        }
        error("E_DISCOVERY20_STRICT_MISSING_RED")
    }
}
