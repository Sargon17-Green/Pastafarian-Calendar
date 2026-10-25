package pastafari

/** Cam 53: profi derbyn y ffin yn union yn erbyn yr oracl wreiddiol. */
object Stage53Tests {
    private fun must(code: String, condition: Boolean) { check(condition) { code } }
    private fun rejects(block: () -> Unit) {
        try { block() } catch (_: IllegalArgumentException) { return }
        error("E_PATCH26_GUARD_MISSING")
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val patch = Year5000InclusiveAcceptancePatchWrapper()
        val manager = Year5000InclusiveAcceptancePatchManager()
        val m = NormativeCore.M
        must("E_PATCH26_MODULUS", LegacyYear5000ExclusiveAcceptanceAdapter.MODULUS == m)
        val oracle = NormativeCalendar()
        val day = NormativeCore.FOUNDATION_DAY
        val pairs = mutableListOf<Year5000TieCandidate>()
        for (i in -16..16) {
            val a = ExactInt.of(i.toLong())
            val open = oracle.gates.get(a)
            for (width in 6..12) {
                val b = a + width.toLong()
                pairs.add(Year5000TieCandidate(a, b, open, oracle.gates.get(b)))
            }
        }
        val eligible = pairs.filter { c ->
            c.closeGateIndex - c.openGateIndex >= ExactInt.of(6) &&
                c.length >= ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
                c.length <= ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
                c.openGateDay < day && day <= c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate> { it.length }.thenBy { it.openGateDay })
        must("E_PATCH26_REAL_PAIRS", pairs.size == 231 && eligible.isNotEmpty())
        val stream = NormativeCore.askBowl(
            NormativeCore.sauce(day, day), 1, NormativeCore.SEAL_YEAR_5000
        )
        val actual = patch.patch(stream.first, stream.directionStep, eligible.size)
        must("E_PATCH26_REAL_ORACLE", actual.correctedRank ==
            NormativeCore.chooseRankInt(stream, eligible.size) &&
            oracle.year5000(day).openGateDay < day)
        println("STAGE53_REAL_231_GATE_PAIRS_ORACLE_GREEN")

        var corrected = 0
        var controls = 0
        var sessions = 0
        var saved: Year5000InclusiveAcceptancePatchSession? = null
        for (n in 2..65) {
            val divisor = ExactInt.of(n.toLong())
            val boundary = (m / divisor) * divisor
            val expected = NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(boundary, -1), divisor
            ).toIntExact()
            val result = patch.patch(boundary, -1, n)
            val session = manager.apply(boundary, -1, n)
            must("E_PATCH26_BOUNDARY_$n", expected == n &&
                result.correctedRank == n && result.legacyRank == n - 1 &&
                result.correctionApplied && result.rejectedAnswers == 0 &&
                session.outcome == result &&
                session.trace == listOf("BOOT", "PATCH_26") &&
                session.context.status == "PATCHED_YEAR5000_INCLUSIVE_ACCEPTANCE" &&
                session.diagnostics == listOf("PATCH_26_INCLUSIVE_ACCEPTANCE"))
            if (saved == null) saved = session
            corrected++
            sessions++
            val before = boundary - ExactInt.ONE
            val control = patch.patch(before, -1, n)
            val controlOracle = NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(before, -1), divisor
            ).toIntExact()
            must("E_PATCH26_CONTROL_$n", controlOracle == n - 1 &&
                control.correctedRank == controlOracle &&
                control.legacyRank == controlOracle &&
                !control.correctionApplied && control.rejectedAnswers == 0)
            controls++
        }
        must("E_PATCH26_SYNTH_TOTAL", corrected == 64 && controls == 64 && sessions == 64)
        println("STAGE53_SYNTHETIC_64_BOUNDARIES_CORRECTED_64_CONTROLS_GREEN")

        var giants = 0
        for (n in 1001..1128) {
            val divisor = ExactInt.of(n.toLong())
            val boundary = (m / divisor) * divisor
            val result = patch.patch(boundary, -1, n)
            val good = NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(boundary, -1), divisor
            ).toIntExact()
            val before = boundary - ExactInt.ONE
            val control = patch.patch(before, -1, n)
            must("E_PATCH26_BIGINT_$n", good == n &&
                result.correctedRank == good && result.legacyRank == n - 1 &&
                result.rejectedAnswers == 0 && result.correctionApplied &&
                control.correctedRank == n - 1 && control.legacyRank == n - 1 &&
                !control.correctionApplied)
            giants++
        }
        must("E_PATCH26_BIG_TOTAL", giants == 128)
        println("STAGE53_BIGINT_128_BOUNDARIES_CORRECTED_128_CONTROLS_GREEN")

        // Cymesuredd y ffin: prawf annibynnol i'r ddau gyfeiriad,
        // gan gynnwys rejection hyd at lapio'r modwlws a'r hen gyllideb.
        var forwardBoundaries = 0
        var forwardRejections = 0
        var backwardRejections = 0
        for (n in 2..65) {
            val divisor = ExactInt.of(n.toLong())
            val limit = (m / divisor) * divisor
            val tail = (m - limit).toIntExact()
            must("E_PATCH26_TAIL_RANGE_$n", tail in 1 until n)
            val forward = patch.patch(limit, 1, n)
            val oracleForward = NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(limit, 1), divisor
            ).toIntExact()
            must("E_PATCH26_FORWARD_BOUNDARY_$n",
                forward.correctedRank == n && oracleForward == n &&
                forward.rejectedAnswers == 0 &&
                forward.legacyRank != n && forward.correctionApplied)
            forwardBoundaries++

            val after = limit + ExactInt.ONE
            val plus = patch.patch(after, 1, n)
            val minus = patch.patch(after, -1, n)
            val oraclePlus = NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(after, 1), divisor
            ).toIntExact()
            val oracleMinus = NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(after, -1), divisor
            ).toIntExact()
            must("E_PATCH26_FORWARD_REJECTION_$n",
                plus.correctedRank == 1 && oraclePlus == 1 &&
                plus.rejectedAnswers == tail &&
                plus.legacyRank == 1 && !plus.correctionApplied)
            must("E_PATCH26_BACKWARD_REJECTION_$n",
                minus.correctedRank == n && oracleMinus == n &&
                minus.rejectedAnswers == 1 &&
                minus.legacyRank != n && minus.correctionApplied)
            forwardRejections++
            backwardRejections++
        }
        must("E_PATCH26_SYMMETRY_TOTALS",
            forwardBoundaries == 64 && forwardRejections == 64 &&
            backwardRejections == 64)
        println("STAGE53_FORWARD_64_BOUNDARIES_AND_128_DIRECTIONAL_REJECTIONS_GREEN")

        val three = ExactInt.of(3)
        val boundary = (m / three) * three
        val forward = patch.patch(boundary, 1, 3)
        must("E_PATCH26_FORWARD_EDGE", forward.correctedRank == 3 &&
            forward.legacyRank == 1 && forward.correctionApplied &&
            forward.rejectedAnswers == 0 &&
            NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(boundary, 1), three
            ).toIntExact() == 3)
        val wrapped = patch.patch(m, 1, 3)
        must("E_PATCH26_MODULUS_WRAP", wrapped.correctedRank == 1 &&
            wrapped.rejectedAnswers == 1 &&
            wrapped.correctedRank == NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m, 1), three
            ).toIntExact())
        must("E_PATCH26_SINGLETON", patch.patch(m, -1, 1).correctedRank == 1)
        rejects { patch.patch(ExactInt.ZERO, -1, 3) }
        rejects { patch.patch(m + 1L, -1, 3) }
        rejects { patch.patch(m, 0, 3) }
        rejects { patch.patch(m, 2, 3) }
        rejects { patch.patch(m, -1, 0) }
        rejects { patch.patch(m, -1, -3) }
        val metricBefore = manager.metrics.snapshot()
        val bootBefore = manager.bootstrap.metrics.snapshot()
        rejects { manager.apply(m, 0, 3) }
        rejects { manager.apply(m, -1, 0) }
        must("E_PATCH26_METRICS", metricBefore["patch26.applied"] == 64L &&
            metricBefore["patch26.historical.calls"] == 64L &&
            metricBefore["patch26.corrected.checks"] == 64L &&
            bootBefore["bootstrap.ready"] == 64L &&
            manager.metrics.snapshot() == metricBefore &&
            manager.bootstrap.metrics.snapshot() == bootBefore)
        val session = saved ?: error("E_PATCH26_SESSION_MISSING")
        val code = try { manager.rejectReplay(session); "NO_ERROR" }
            catch (e: MonsterValidationException) { e.machineCode }
        must("E_PATCH26_REPLAY", code == "E_PATCH26_CONTEXT_NOT_READY" &&
            manager.metrics.snapshot() == metricBefore &&
            manager.bootstrap.metrics.snapshot() == bootBefore)
        println("STAGE53_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE53_PATCH_NATIVE_GREEN")
    }
}
