package pastafari

/** Cam 31: cywiro ffin agored 5000 gyda graith Cam 30 yn aros yn weithredol. */
object Stage31Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun rejects(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return }
        error("E_PATCH15_MISSING_INPUT_GUARD")
    }
    private fun machine(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }
    private fun expected(
        lowIndex: ExactInt, highIndex: ExactInt,
        low: ExactInt, high: ExactInt, day: ExactInt
    ): Boolean = highIndex - lowIndex >= ExactInt.of(6) &&
        high - low >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
        high - low <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
        low < day && day <= high

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val oracle = NormativeCalendar()
        val wrapper = Year5000OpeningPatchWrapper()
        val manager = Year5000OpeningPatchManager()
        var realCases = 0
        var corrected = 0
        var scarRed = 0
        var scarMatch = 0
        var initial: Year5000OpeningPatchSession? = null
        for (i in -12..12) {
            val lowIndex = ExactInt.of(i.toLong())
            val highIndex = lowIndex + 6L
            val low = oracle.gates.get(lowIndex)
            val high = oracle.gates.get(highIndex)
            val days = listOf(low - 1L, low, low + 1L, high, high + 1L)
            for ((kind,day) in days.withIndex()) {
                val value = wrapper.patch(lowIndex,highIndex,low,high,day)
                val reference = expected(lowIndex,highIndex,low,high,day)
                insist("E_PATCH15_REAL_$i-$kind",
                    value.correctedIncluded == reference &&
                    value.legacyCalls == 1 && value.correctedChecks == 1 &&
                    value.length == high - low &&
                    value.correctionApplied == (kind == 1) &&
                    value.legacyIncluded == (reference || kind == 1))
                val session = manager.applyYear5000OpeningPatch(
                    lowIndex,highIndex,low,high,day)
                insist("E_PATCH15_SESSION_$i-$kind",
                    session.outcome == value &&
                    session.branchTrace == listOf("BOOT","PATCH_15") &&
                    session.diagnostics == listOf(
                        "PATCH_15_OPEN_STRICT_CLOSE_INCLUSIVE") &&
                    session.context.branchTrace == session.branchTrace &&
                    session.context.status == "PATCHED_YEAR5000_OPENING" &&
                    session.applied && session.invocationCount == 1)
                if (initial == null) initial = session
                if (value.legacyIncluded != reference) scarRed++ else scarMatch++
                corrected++
                realCases++
            }
        }
        insist("E_PATCH15_REAL_TOTAL",
            realCases == 125 && corrected == 125 &&
            scarRed == 25 && scarMatch == 100)
        println("STAGE31_REAL_GATE_CORRECTED_GREEN_125")
        println("STAGE31_PRESERVED_LEGACY_RED_25_MATCH_100")

        var matrixCases = 0
        for (i in -4..4) {
            val lowIndex = ExactInt.of(i.toLong())
            val low = oracle.gates.get(lowIndex)
            for (width in 6..16) {
                val highIndex = lowIndex + width.toLong()
                val high = oracle.gates.get(highIndex)
                val all = listOf(low - 1L, low, low + 1L, high, high + 1L)
                for (day in all) {
                    val value = wrapper.patch(lowIndex,highIndex,low,high,day)
                    insist("E_PATCH15_MATRIX_$i-$width",
                        value.correctedIncluded ==
                            expected(lowIndex,highIndex,low,high,day) &&
                        value.correctionApplied ==
                            (value.legacyIncluded && !value.correctedIncluded))
                    matrixCases++
                }
            }
        }
        insist("E_PATCH15_MATRIX_COUNT", matrixCases == 495)
        println("STAGE31_CANDIDATE_MATRIX_GREEN_495")

        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val remote = ExactInt.parse("-1000000000000000000000000000000000000000000")
        var wideChecks = 0
        var wideLegacyRed = 0
        for (i in 1..384) {
            val lowIndex = huge + i.toLong()
            val highIndex = lowIndex + (6 + i % 11).toLong()
            val low = remote + (i * 9000L)
            val high = low + (252 + (i * 17) % 5527).toLong()
            for (day in listOf(low - 1L, low, low + 1L, high, high + 1L)) {
                val out = wrapper.patch(lowIndex,highIndex,low,high,day)
                val reference = expected(lowIndex,highIndex,low,high,day)
                insist("E_PATCH15_WIDE_$i",
                    out.correctedIncluded == reference &&
                    out.correctionApplied == (day == low) &&
                    out.legacyIncluded == (reference || day == low))
                if (out.legacyIncluded != out.correctedIncluded) wideLegacyRed++
                wideChecks++
            }
        }
        insist("E_PATCH15_BIGINT_TOTAL", wideChecks == 1920 && wideLegacyRed == 384)
        println("STAGE31_BIGINT_CORRECTED_GREEN_1920_LEGACY_RED_384")

        val origin = NormativeCore.FOUNDATION_DAY
        val actualYear = oracle.year5000(origin)
        val realOpen = oracle.gates.get(actualYear.openGateIndex)
        val realClose = oracle.gates.get(actualYear.closeGateIndex)
        for (day in listOf(realOpen-1L,realOpen,realOpen+1L,realClose,realClose+1L)) {
            val out = wrapper.patch(
                actualYear.openGateIndex, actualYear.closeGateIndex,
                realOpen, realClose, day)
            insist("E_PATCH15_YEAR5000_SELECTED",
                out.correctedIncluded ==
                    expected(actualYear.openGateIndex, actualYear.closeGateIndex,
                        realOpen, realClose, day))
        }
        println("STAGE31_REAL_SELECTED_YEAR5000_BOUNDARY_GREEN")

        val z = ExactInt.ZERO
        val six = ExactInt.of(6)
        rejects { wrapper.patch(z,six - 1L,z,ExactInt.of(252),z) }
        rejects { wrapper.patch(z,six,ExactInt.ONE,z,z) }
        val counts = manager.metrics.snapshot()
        val baseCounts = manager.bootstrap.metrics.snapshot()
        rejects { manager.applyYear5000OpeningPatch(z,six - 1L,z,ExactInt.of(252),z) }
        rejects { manager.applyYear5000OpeningPatch(z,six,ExactInt.ONE,z,z) }
        insist("E_PATCH15_COUNTERS",
            counts["patch15.legacy.calls"] == 125L &&
            counts["patch15.corrected.checks"] == 125L &&
            counts["patch15.applied"] == 125L &&
            baseCounts["bootstrap.ready"] == 125L &&
            manager.metrics.snapshot() == counts &&
            manager.bootstrap.metrics.snapshot() == baseCounts)
        val first = initial ?: error("E_PATCH15_FIRST_SESSION_MISSING")
        val fixed = first.outcome
        val state = first.branchTrace.toList()
        insist("E_PATCH15_REPLAY",
            machine { manager.rejectReplay(first) } ==
                "E_PATCH15_CONTEXT_NOT_READY" &&
            first.outcome === fixed &&
            first.branchTrace == state &&
            manager.metrics.snapshot() == counts &&
            manager.bootstrap.metrics.snapshot() == baseCounts)
        println("STAGE31_GUARDS_METRICS_REPLAY_OWNERSHIP_PASS")
        println("STAGE31_PATCH_NATIVE_GREEN")
    }
}
