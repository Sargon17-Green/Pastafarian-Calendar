package pastafari

/** Cam 30: profion ar ffin chwith agored blwyddyn 5000; dim PATCH 15 eto. */
object Stage30Tests {
    private fun insist(id: String, predicate: Boolean) { check(predicate) { id } }
    private fun rejects(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return }
        error("E_DISCOVERY15_MISSING_GUARD")
    }
    private fun normative(
        openIndex: ExactInt, closeIndex: ExactInt,
        open: ExactInt, close: ExactInt, c: ExactInt
    ): Boolean = closeIndex - openIndex >= ExactInt.of(6) &&
        close - open >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
        close - open <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
        open < c && c <= close

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val calendar = NormativeCalendar()
        val old = LegacyYear5000OpeningAdapter()
        var red = 0
        var match = 0
        var pairs = 0
        var negativePairs = 0
        var positivePairs = 0
        for (i in -12..12) {
            val low = ExactInt.of(i.toLong())
            val high = low + 6L
            val open = calendar.gates.get(low)
            val close = calendar.gates.get(high)
            insist("E_DISCOVERY15_VALID_PAIR_$i",
                close > open &&
                close - open >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
                close - open <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()))
            val probes = listOf(open - 1L, open, open + 1L, close, close + 1L)
            for ((probeIndex, c) in probes.withIndex()) {
                val legacy = old.acceptsCandidate(low,high,open,close,c)
                val expected = normative(low,high,open,close,c)
                if (legacy != expected) {
                    insist("E_DISCOVERY15_ONLY_OPEN_RED_$i-$probeIndex",
                        probeIndex == 1 && legacy && !expected)
                    red++
                } else {
                    insist("E_DISCOVERY15_NEARBY_MATCH_$i-$probeIndex",
                        legacy == expected)
                    match++
                }
            }
            pairs++
            if (i < 0) negativePairs++ else positivePairs++
        }
        insist("E_DISCOVERY15_TOTALS",
            pairs == 25 && negativePairs == 12 && positivePairs == 13 &&
            red == 25 && match == 100)
        println("STAGE30_REAL_GATE_PAIRS_GREEN_25")
        println("STAGE30_OPEN_GATE_EXPECTED_RED_25")
        println("STAGE30_OTHER_BOUNDARIES_MATCH_100")
        println("STAGE30_BOTH_GATE_SIGNS_GREEN")

        val foundation = NormativeCore.FOUNDATION_DAY
        val boundary = calendar.year5000(foundation)
        insist("E_DISCOVERY15_YEAR5000_ORACLE_AT_FOUNDATION",
            boundary.openGateDay < foundation &&
            foundation <= boundary.closeGateDay &&
            boundary.number == ExactInt.of(5000))
        val found = calendar.gates.exactGateIndex(foundation)
        insist("E_DISCOVERY15_EXACT_GATE_FOUNDATION",
            found == ExactInt.ZERO)
        println("STAGE30_REAL_YEAR5000_ORACLE_BOUNDARY_GREEN")

        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val remote = ExactInt.parse("-1000000000000000000000000000000000000000000")
        val openIndex = huge
        val closeIndex = huge + 6L
        val close = remote + 252L
        insist("E_DISCOVERY15_BIGINT",
            old.acceptsCandidate(openIndex,closeIndex,remote,close,remote) &&
            !normative(openIndex,closeIndex,remote,close,remote) &&
            old.acceptsCandidate(openIndex,closeIndex,remote,close,close) &&
            !old.acceptsCandidate(openIndex,closeIndex,remote,close,remote-1L))
        rejects { old.acceptsCandidate(ExactInt.ZERO,ExactInt.of(5),remote,close,remote) }
        rejects { old.acceptsCandidate(ExactInt.ZERO,ExactInt.of(6),close,remote,remote) }
        println("STAGE30_BIGINT_AND_INPUT_GUARDS_GREEN")
        println("STAGE30_DISCOVERY_EXPECTED_RED_PASS")
    }
}
