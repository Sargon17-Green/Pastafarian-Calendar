package pastafari

/** Cam 34: darganfod gwaharddiad anghywir ar flwyddyn o 5778 diwrnod. */
object Stage34Tests {
    private fun must(id: String, ok: Boolean) { check(ok) { id } }
    private fun rejects(body: () -> Unit) {
        try { body() } catch (_: IllegalArgumentException) { return }
        error("E_DISCOVERY17_MISSING_GUARD")
    }
    private fun normative(
        a: ExactInt, b: ExactInt, open: ExactInt,
        close: ExactInt, day: ExactInt
    ): Boolean {
        val len = close - open
        return b-a >= ExactInt.of(6) &&
            len >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            len <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            open < day && day <= close
    }
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val legacy = LegacyYear5000MaxExclusiveAdapter()
        val oracle = NormativeCalendar()
        val f = NormativeCore.FOUNDATION_DAY
        var real = 0
        var realDiff = 0
        var maxWitnesses = 0
        for (i in -12..12) {
            val a = ExactInt.of(i.toLong())
            val open = oracle.gates.get(a)
            for (width in 6..11) {
                val b = a+width.toLong()
                val close = oracle.gates.get(b)
                for (day in listOf(open+1L,close,close+1L)) {
                    val wrong = legacy.acceptsCandidate(a,b,open,close,day)
                    val correct = normative(a,b,open,close,day)
                    val witness = close-open == ExactInt.of(5778) &&
                        open < day && day <= close
                    must("E_DISCOVERY17_REAL_$i-$width",
                        (wrong != correct) == witness &&
                        (!wrong || correct))
                    if (witness) { maxWitnesses++;realDiff++ }
                    real++
                }
            }
        }
        must("E_DISCOVERY17_REAL_TOTAL",real == 450 && realDiff==maxWitnesses)
        println("STAGE34_REAL_GATE_PROBES_450_PASS")

        var count = 0; var red = 0; var match = 0
        for (signed in listOf(-1,1)) {
            val open = ExactInt.of(signed.toLong()*1000000000L)
            for (width in 6..8) {
                val a = ExactInt.of(signed.toLong()*100L)
                val b = a+width.toLong()
                for (length in listOf(251L,252L,5777L,5778L,5779L)) {
                    val close = open+length
                    val days = listOf(open-1L,open,open+1L,close,close+1L)
                    for ((p,day) in days.withIndex()) {
                        val wrong=legacy.acceptsCandidate(a,b,open,close,day)
                        val correct=normative(a,b,open,close,day)
                        val witness=length==5778L && (p==2 || p==3)
                        must("E_DISCOVERY17_SYNTH_$signed-$width-$length-$p",
                            (wrong!=correct)==witness && (!wrong||correct))
                        if (witness) red++ else match++
                        count++
                    }
                }
            }
        }
        must("E_DISCOVERY17_SYNTH_COUNTS",
            count==150 && red==12 && match==138)
        println("STAGE34_SYNTHETIC_150_EXPECTED_RED_12_MATCH_138")

        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val remote = ExactInt.parse("-1000000000000000000000000000000000000000000")
        var big=0; var bigRed=0
        for (i in 1..256) {
            val a=huge+i.toLong()
            val b=a+(6+i%9).toLong()
            val open=remote+(i*10000L)
            val close=open+5778L
            for ((pos,day) in listOf(open,open+1L,close,close+1L).withIndex()) {
                val wrong=legacy.acceptsCandidate(a,b,open,close,day)
                val correct=normative(a,b,open,close,day)
                val witness=pos==1||pos==2
                must("E_DISCOVERY17_BIG_$i-$pos",
                    (wrong!=correct)==witness && (!wrong||correct))
                if (witness) bigRed++
                big++
            }
        }
        must("E_DISCOVERY17_BIG_COUNTS",big==1024 && bigRed==512)
        println("STAGE34_BIGINT_1024_EXPECTED_RED_512_MATCH_512")

        val selected=oracle.year5000(f)
        must("E_DISCOVERY17_ORACLE_BOUNDARY",
            selected.openGateDay < f && f <= selected.closeGateDay &&
            selected.closeGateDay - selected.openGateDay <=
                ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()))
        rejects { legacy.acceptsCandidate(ExactInt.ZERO,ExactInt.ZERO,f,f+5778L,f+1L) }
        rejects { legacy.acceptsCandidate(ExactInt.ZERO,ExactInt.of(6),f,f,f) }
        println("STAGE34_ORACLE_AND_INPUT_GUARDS_PASS")
        println("STAGE34_DISCOVERY_EXPECTED_RED_PASS")
    }
}
