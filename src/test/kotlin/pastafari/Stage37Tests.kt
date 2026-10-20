package pastafari

/** Cam 37: prawf cyflawn o'r terfyn uchaf cynhwysol gyda'r graith yn aros. */
object Stage37Tests {
    private fun must(id: String, ok: Boolean) { check(ok) { id } }
    private fun rejects(body: () -> Unit) {
        try { body() } catch (_: IllegalArgumentException) { return }
        error("E_PATCH18_MISSING_INPUT_GUARD")
    }
    private fun normative(
        a: ExactInt, b: ExactInt, open: ExactInt,
        close: ExactInt, day: ExactInt
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
        val wrapper = Year5000MinInclusivePatchWrapper()
        val manager = Year5000MinInclusivePatchManager()
        var real = 0
        var realRed = 0
        var sessions = 0
        var first: Year5000MinInclusivePatchSession? = null

        for (i in -12..12) {
            val a = ExactInt.of(i.toLong())
            val open = oracle.gates.get(a)
            for (width in 6..11) {
                val b = a + width.toLong()
                val close = oracle.gates.get(b)
                for ((p, day) in listOf(open + 1L, close, close + 1L).withIndex()) {
                    val out = wrapper.patch(a, b, open, close, day)
                    val expected = normative(a, b, open, close, day)
                    val witness = close - open == ExactInt.of(252) &&
                        open < day && day <= close
                    must("E_PATCH18_REAL_$i-$width-$p",
                        out.correctedAccepted == expected &&
                        out.correctionApplied == witness &&
                        (out.legacyAccepted != expected) == witness &&
                        out.legacyCalls == 1 && out.correctedChecks == 1 &&
                        out.gateGaps == ExactInt.of(width.toLong()) &&
                        out.yearDays == close - open)
                    if (witness) realRed++
                    real++
                }
                val session = manager.apply(a, b, open, close, open + 1L)
                must("E_PATCH18_SESSION_$i-$width",
                    session.outcome.correctedAccepted ==
                        normative(a, b, open, close, open + 1L) &&
                    session.context.status == "PATCHED_YEAR5000_MIN_INCLUSIVE" &&
                    session.branchTrace == listOf("BOOT", "PATCH_18") &&
                    session.diagnostics == listOf("PATCH_18_MIN_252_INCLUSIVE") &&
                    session.context.branchTrace == session.branchTrace &&
                    session.applied)
                if (first == null) first = session
                sessions++
            }
        }
        must("E_PATCH18_REAL_TOTAL", real == 450 && sessions == 150)
        println("STAGE37_REAL_GATE_GREEN_450_SESSIONS_150")
        println("STAGE37_REAL_LEGACY_EXPECTED_RED_$realRed")

        var synthetic = 0
        var red = 0
        var match = 0
        for (signed in listOf(-1, 1)) {
            val open = ExactInt.of(signed.toLong() * 1000000000L)
            for (width in 6..8) {
                val a = ExactInt.of(signed.toLong() * 100L)
                val b = a + width.toLong()
                for (length in listOf(251L, 252L, 5777L, 5778L, 5779L)) {
                    val close = open + length
                    for ((p, day) in listOf(
                        open - 1L, open, open + 1L, close, close + 1L
                    ).withIndex()) {
                        val out = wrapper.patch(a, b, open, close, day)
                        val expected = normative(a, b, open, close, day)
                        val witness = length == 252L && (p == 2 || p == 3)
                        must("E_PATCH18_SYNTH_$signed-$width-$length-$p",
                            out.correctedAccepted == expected &&
                            out.correctionApplied == witness &&
                            (out.legacyAccepted != expected) == witness)
                        if (witness) red++ else match++
                        synthetic++
                    }
                }
            }
        }
        must("E_PATCH18_SYNTH_TOTAL",
            synthetic == 150 && red == 12 && match == 138)
        println("STAGE37_SYNTHETIC_GREEN_150_LEGACY_RED_12_MATCH_138")

        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val far = ExactInt.parse("-1000000000000000000000000000000000000000000")
        var wide = 0
        var wideRed = 0
        for (i in 1..256) {
            val a = huge + i.toLong()
            val b = a + (6 + i % 9).toLong()
            val open = far + (i * 10000L)
            val close = open + 252L
            for ((p, day) in listOf(open, open + 1L, close, close + 1L)
                .withIndex()) {
                val out = wrapper.patch(a, b, open, close, day)
                val expected = normative(a, b, open, close, day)
                val witness = p == 1 || p == 2
                must("E_PATCH18_BIG_$i-$p",
                    out.correctedAccepted == expected &&
                    out.correctionApplied == witness &&
                    (out.legacyAccepted != expected) == witness)
                if (witness) wideRed++
                wide++
            }
        }
        must("E_PATCH18_BIG_TOTAL", wide == 1024 && wideRed == 512)
        println("STAGE37_BIGINT_GREEN_1024_LEGACY_RED_512")

        val zero = ExactInt.ZERO
        val six = ExactInt.of(6)
        for (length in listOf(251L, 252L, 5777L, 5778L, 5779L)) {
            val out = wrapper.patch(zero, six, zero, ExactInt.of(length),
                ExactInt.ONE)
            must("E_PATCH18_BOUNDARY_$length",
                out.correctedAccepted == (length in 252L..5778L) &&
                out.correctionApplied == (length == 252L))
        }
        val foundation = NormativeCore.FOUNDATION_DAY
        val year = oracle.year5000(foundation)
        must("E_PATCH18_YEAR5000_ORACLE",
            wrapper.patch(year.openGateIndex, year.closeGateIndex,
                year.openGateDay, year.closeGateDay, foundation)
                .correctedAccepted)
        println("STAGE37_YEAR5000_BOUNDS_AND_ORACLE_GREEN")

        val counts = manager.metrics.snapshot()
        val boots = manager.bootstrap.metrics.snapshot()
        rejects { wrapper.patch(zero, zero, zero, six, ExactInt.ONE) }
        rejects { wrapper.patch(zero, six, six, zero, zero) }
        rejects { manager.apply(zero, zero, zero, six, ExactInt.ONE) }
        must("E_PATCH18_NO_SIDE_EFFECTS",
            counts["patch18.historical.calls"] == 150L &&
            counts["patch18.corrected.checks"] == 150L &&
            counts["patch18.applied"] == 150L &&
            boots["bootstrap.ready"] == 150L &&
            counts == manager.metrics.snapshot() &&
            boots == manager.bootstrap.metrics.snapshot())
        val session = first ?: error("E_PATCH18_MISSING_FIRST_SESSION")
        val saved = session.outcome
        val rejected = try {
            manager.rejectReplay(session); "NO_ERROR"
        } catch (e: MonsterValidationException) { e.machineCode }
        must("E_PATCH18_REPLAY",
            rejected == "E_PATCH18_CONTEXT_NOT_READY" &&
            saved === session.outcome &&
            session.branchTrace == listOf("BOOT", "PATCH_18") &&
            counts == manager.metrics.snapshot() &&
            boots == manager.bootstrap.metrics.snapshot())
        println("STAGE37_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE37_PATCH_NATIVE_GREEN")
    }
}
