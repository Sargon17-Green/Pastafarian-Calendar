package pastafari

/** Cam 32: canfod colli ymgeiswyr chwe bwlch giât. */
object Stage32Tests {
    private fun insist(code: String, checkValue: Boolean) { check(checkValue) { code } }
    private fun rejects(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return }
        error("E_DISCOVERY16_MISSING_GUARD")
    }
    private fun normative(
        a: ExactInt, b: ExactInt, open: ExactInt, close: ExactInt, day: ExactInt
    ): Boolean {
        val length = close - open
        return b - a >= ExactInt.of(6) &&
            length >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            length <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            open < day && day <= close
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val oracle = NormativeCalendar()
        val old = LegacyYear5000MinSevenAdapter()
        var pairs = 0
        var positives = 0
        var negatives = 0
        var tested = 0
        var red = 0
        var match = 0
        for (i in -20..20) {
            val a = ExactInt.of(i.toLong())
            val open = oracle.gates.get(a)
            if (i < 0) negatives++ else positives++
            for (width in 5..8) {
                val b = a + width.toLong()
                val close = oracle.gates.get(b)
                val probes = listOf(open, open + 1L, close + 1L)
                for ((k, day) in probes.withIndex()) {
                    val actual = old.acceptsCandidate(a,b,open,close,day)
                    val correct = normative(a,b,open,close,day)
                    if (actual != correct) {
                        insist("E_DISCOVERY16_ONLY_SIX_$i-$width-$k",
                            width == 6 && k == 1 && !actual && correct)
                        red++
                    } else {
                        insist("E_DISCOVERY16_OTHER_MATCH_$i-$width-$k",
                            actual == correct)
                        match++
                    }
                    tested++
                }
                pairs++
            }
        }
        insist("E_DISCOVERY16_COUNTS",
            pairs == 164 && tested == 492 &&
            negatives == 20 && positives == 21 &&
            red == 41 && match == 451)
        println("STAGE32_REAL_PAIRS_164_PROBES_492")
        println("STAGE32_EXPECTED_MIN_SEVEN_RED_41")
        println("STAGE32_OTHER_BOUNDARIES_MATCH_451")
        println("STAGE32_BOTH_GATE_SIGNS_GREEN")

        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val remote = ExactInt.parse("-1000000000000000000000000000000000000000000")
        var wide = 0
        var wideRed = 0
        var wideMatch = 0
        for (i in 1..128) {
            val a = huge + i.toLong()
            val open = remote + (i * 10000L)
            val close = open + (252 + (i * 11) % 5527).toLong()
            for (width in 5..8) {
                val b = a + width.toLong()
                val day = open + 1L
                val actual = old.acceptsCandidate(a,b,open,close,day)
                val correct = normative(a,b,open,close,day)
                if (actual != correct) {
                    insist("E_DISCOVERY16_WIDE_RED_$i-$width",
                        width == 6 && !actual && correct)
                    wideRed++
                } else wideMatch++
                wide++
            }
        }
        insist("E_DISCOVERY16_WIDE_TOTALS",
            wide == 512 && wideRed == 128 && wideMatch == 384)
        println("STAGE32_BIGINT_PROBES_512_RED_128_MATCH_384")
        val f = NormativeCore.FOUNDATION_DAY
        val year = oracle.year5000(f)
        insist("E_DISCOVERY16_REAL_YEAR5000",
            year.number == ExactInt.of(5000) &&
            year.closeGateIndex - year.openGateIndex >= ExactInt.of(6))
        rejects { old.acceptsCandidate(ExactInt.ONE,ExactInt.ONE,f,f+252L,f+1L) }
        rejects { old.acceptsCandidate(ExactInt.ZERO,ExactInt.ONE,f,f,f) }
        println("STAGE32_YEAR5000_ORACLE_AND_INPUT_GUARDS_PASS")
        println("STAGE32_DISCOVERY_EXPECTED_RED_PASS")
    }
}
