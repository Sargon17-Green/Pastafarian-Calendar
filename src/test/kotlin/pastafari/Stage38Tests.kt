package pastafari

/** Cam 38: darganfod colli diwrnod cau blwyddyn 5000 heb newid cynhyrchu. */
object Stage38Tests {
    private fun must(id: String, ok: Boolean) { check(ok) { id } }
    private fun rejects(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return }
        error("E_DISCOVERY19_MISSING_GUARD")
    }
    private fun normative(
        a: ExactInt, b: ExactInt, open: ExactInt,
        close: ExactInt, day: ExactInt
    ): Boolean {
        val days = close - open
        return b - a >= ExactInt.of(6) &&
            days >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            days <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            open < day && day <= close
    }
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val historical = LegacyYear5000ClosingExclusiveAdapter()
        val oracle = NormativeCalendar()
        var real = 0; var red = 0; var match = 0
        for (i in -12..12) {
            val a = ExactInt.of(i.toLong())
            val b = a + 6L
            val open = oracle.gates.get(a)
            val close = oracle.gates.get(b)
            must("E_DISCOVERY19_REAL_PAIR_$i",
                close-open >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
                close-open <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()))
            for ((p,day) in listOf(open-1L,open,open+1L,close,close+1L)
                .withIndex()) {
                val observed = historical.acceptsCandidate(a,b,open,close,day)
                val expected = normative(a,b,open,close,day)
                val witness = p == 3
                must("E_DISCOVERY19_REAL_$i-$p",
                    (observed != expected) == witness &&
                    (!observed || expected))
                if (witness) red++ else match++
                real++
            }
        }
        must("E_DISCOVERY19_REAL_TOTAL",
            real == 125 && red == 25 && match == 100)
        println("STAGE38_REAL_PAIRS_25_PROBES_125_EXPECTED_RED_25_MATCH_100")

        var synthetic = 0; var synthRed = 0; var synthMatch = 0
        for (sign in listOf(-1,1)) {
            val open = ExactInt.of(sign.toLong()*1000000000L)
            for (width in 6..8) {
                val a = ExactInt.of(sign.toLong()*100L)
                val b = a+width.toLong()
                for (len in listOf(251L,252L,5777L,5778L,5779L)) {
                    val close = open+len
                    for ((p,day) in listOf(
                        open-1L,open,open+1L,close,close+1L).withIndex()) {
                        val observed = historical.acceptsCandidate(a,b,open,close,day)
                        val expected = normative(a,b,open,close,day)
                        val witness = p == 3 && len in 252L..5778L
                        must("E_DISCOVERY19_SYNTH_$sign-$width-$len-$p",
                            (observed != expected) == witness &&
                            (!observed || expected))
                        if (witness) synthRed++ else synthMatch++
                        synthetic++
                    }
                }
            }
        }
        must("E_DISCOVERY19_SYNTH_TOTAL",
            synthetic == 150 && synthRed == 18 && synthMatch == 132)
        println("STAGE38_SYNTHETIC_150_EXPECTED_RED_18_MATCH_132")

        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val far = ExactInt.parse("-1000000000000000000000000000000000000000000")
        var wide = 0; var wideRed = 0
        for (i in 1..256) {
            val a=huge+i.toLong()
            val b=a+(6+i%9).toLong()
            val open=far+(i*10000L)
            val close=open+252L
            for ((p,day) in listOf(open,open+1L,close,close+1L).withIndex()) {
                val observed=historical.acceptsCandidate(a,b,open,close,day)
                val expected=normative(a,b,open,close,day)
                val witness=p==2
                must("E_DISCOVERY19_BIG_$i-$p",
                    (observed!=expected)==witness && (!observed || expected))
                if(witness)wideRed++
                wide++
            }
        }
        must("E_DISCOVERY19_BIG_TOTAL", wide==1024 && wideRed==256)
        println("STAGE38_BIGINT_1024_EXPECTED_RED_256_MATCH_768")

        val f = NormativeCore.FOUNDATION_DAY
        val year = oracle.year5000(f)
        val closed = historical.acceptsCandidate(
            year.openGateIndex, year.closeGateIndex,
            year.openGateDay, year.closeGateDay, year.closeGateDay)
        must("E_DISCOVERY19_REAL_YEAR5000_CLOSE",
            !closed && normative(
                year.openGateIndex, year.closeGateIndex,
                year.openGateDay, year.closeGateDay, year.closeGateDay))
        rejects { historical.acceptsCandidate(
            ExactInt.ZERO,ExactInt.ZERO,f,f+252L,f+1L) }
        rejects { historical.acceptsCandidate(
            ExactInt.ZERO,ExactInt.of(6),f,f,f) }
        println("STAGE38_SELECTED_YEAR5000_CLOSE_AND_GUARDS_PASS")
        println("STAGE38_DISCOVERY_EXPECTED_RED_PASS")
    }
}
