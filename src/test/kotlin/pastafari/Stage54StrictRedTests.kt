package pastafari

/** Bwriadol RED: rhaid i'r prawf hwn fethu ar yr un achos pendant. */
object Stage54StrictRedTests {
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val day=ExactInt.of(30)
        val a=Year5000TieCandidate(ExactInt.ZERO,ExactInt.of(6),
            ExactInt.ZERO,ExactInt.of(300))
        val b=Year5000TieCandidate(ExactInt.of(10),ExactInt.of(16),
            ExactInt.ONE,ExactInt.of(501))
        val sorted=listOf(a,b)
        val observed=LegacyYear5000RankAsIndexAdapter()
            .oldChoose(day,sorted,ExactInt.ONE)
        check(observed.wrongChosen==sorted[0]) {
            "E_DISCOVERY27_STRICT_RANK_AS_INDEX_RED"
        }
    }
}
