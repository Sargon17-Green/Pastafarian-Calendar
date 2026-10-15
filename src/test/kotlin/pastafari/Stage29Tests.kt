package pastafari

/** Cam 29: diwygio'r cyfeiriad heb ddileu'r graith arbrofol. */
object Stage29Tests {
    private fun insist(id: String, ok: Boolean) { check(ok) { id } }
    private fun rejects(action: () -> Unit) {
        try { action() } catch (_: IllegalArgumentException) { return }
        error("E_PATCH14_MISSING_INPUT_GUARD")
    }
    private fun machine(action: () -> Unit) = try {
        action(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val f = NormativeCore.FOUNDATION_DAY
        val oracle = NormativeCalendar()
        val wrapper = NegativeGateDirectionPatchWrapper()
        val manager = NegativeGateDirectionPatchManager()
        var prior = f
        var red = 0
        var match = 0
        var native = 0
        var lastContext: NegativeGateDirectionPatchSession? = null
        for (i in 1..24) {
            val n = ExactInt.of(i.toLong())
            val sauce = NormativeCore.sauce(f, f - n)
            val stream = NormativeCore.askBowl(
                sauce, 1, NormativeCore.SEAL_GATE_GAP)
            val positive = oracle.positiveGateGap(n)
            val output = wrapper.patch(n, prior, positive,
                stream.first, stream.directionStep)
            val correct = oracle.gates.get(-n)
            insist("E_PATCH14_NATURAL_$i",
                output.correctedNegativeGate == correct &&
                output.negativeGap == oracle.negativeGateGap(n) &&
                output.legacyNegativeGate == prior - ExactInt.of(positive.toLong()) &&
                output.negativeGapRank.correctedGateGap == output.negativeGap &&
                output.negativeGapRank.gateIndex == -n &&
                output.legacyCalls == 1 && output.correctedCalls == 1)
            if (output.legacyNegativeGate == correct) match++ else red++
            val ctx = manager.applyNegativeGateDirectionPatch(
                f, f - n, n, prior, positive,
                stream.first, stream.directionStep)
            insist("E_PATCH14_MANAGER_$i",
                ctx.phase == "PATCH_14" &&
                ctx.status == "PATCHED_NEGATIVE_GATE_DIRECTION" &&
                ctx.branchTrace == listOf("BOOT", "PATCH_13", "PATCH_14") &&
                ctx.diagnostics == listOf(
                    "PATCH_13_UNRANK1_AND_REJECTION",
                    "PATCH_14_NEGATIVE_SAUCE_DIRECTION") &&
                ctx.applied && ctx.invocationCount == 1 &&
                ctx.outcome.correctedNegativeGate == correct &&
                ctx.outcome.legacyNegativeGate == output.legacyNegativeGate &&
                ctx.outcome.negativeGap == output.negativeGap &&
                ctx.baseContext.patch13CorrectedGateGap == output.negativeGap)
            lastContext = ctx
            prior = correct
            native++
        }
        insist("E_PATCH14_NATURAL_TOTAL", native == 24 && red == 24 && match == 0)
        println("STAGE29_NATURAL_NEGATIVE_GATE_PATCH_GREEN_24")
        println("STAGE29_PRESERVED_EXPERIMENTAL_SCAR_RED_24")

        var synthetic = 0
        for (i in 1..922) {
            val first = ExactInt.of(i.toLong())
            val pos = if (i == 922) 42 else 42 + i
            val outcome = wrapper.patch(
                ExactInt.ONE, f, pos, first, 1)
            insist("E_PATCH14_SYNTHETIC_$i",
                outcome.correctedNegativeGate == f - ExactInt.of((41 + i).toLong()) &&
                outcome.negativeGap == 41 + i &&
                outcome.legacyNegativeGate == f - ExactInt.of(pos.toLong()) &&
                outcome.correctedNegativeGate != outcome.legacyNegativeGate &&
                outcome.negativeGapRank.legacyRead.gateGapWrong == 40 + i &&
                outcome.negativeGapRank.rejectedCandidates.isEmpty())
            synthetic++
        }
        insist("E_PATCH14_SHORT_COUNT", synthetic == 922)
        println("STAGE29_SYNTHETIC_922_PATCH_GREEN_WITH_HISTORICAL_RED")

        val m = NormativeCore.M
        val upper = (m / ExactInt.of(922)) * ExactInt.of(922)
        var boundaries = 0
        for (first in listOf(upper, upper + 1L, upper + 2L, m)) {
            for (step in listOf(-1, 1)) {
                val outcome = wrapper.patch(ExactInt.ONE, f, 42, first, step)
                val stream = NormativeCore.AnswerStream(first, step)
                val expected = 41 + NormativeCore.chooseRankInt(stream, 922)
                insist("E_PATCH14_REJECTION_$first-$step",
                    outcome.negativeGap == expected &&
                    outcome.negativeGapRank.acceptedAnswerIndex0 ==
                        outcome.negativeGapRank.rejectedCandidates.size &&
                    outcome.negativeGapRank.rejectedCandidates.all { it > upper })
                boundaries++
            }
        }
        insist("E_PATCH14_REJECTION_COUNT", boundaries == 8)
        println("STAGE29_REJECTION_BOUNDARY_GREEN_8")

        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val remoteDay = ExactInt.parse("-100000000000000000000000000000000")
        val distant = wrapper.patch(huge, remoteDay, 43, ExactInt.ONE, 1)
        insist("E_PATCH14_HUGE",
            distant.negativeGap == 42 &&
            distant.correctedNegativeGate == remoteDay - 42L &&
            distant.legacyNegativeGate == remoteDay - 43L)
        rejects { wrapper.patch(ExactInt.ZERO, f, 42, ExactInt.ONE, 1) }
        rejects { wrapper.patch(ExactInt.of(-1), f, 42, ExactInt.ONE, 1) }
        rejects { wrapper.patch(ExactInt.ONE, f, 41, ExactInt.ONE, 1) }
        rejects { wrapper.patch(ExactInt.ONE, f, 964, ExactInt.ONE, 1) }
        rejects { wrapper.patch(ExactInt.ONE, f, 42, ExactInt.ZERO, 1) }
        rejects { wrapper.patch(ExactInt.ONE, f, 42, m + 1L, 1) }
        rejects { wrapper.patch(ExactInt.ONE, f, 42, ExactInt.ONE, 0) }
        println("STAGE29_BIGINT_AND_INPUT_GUARDS_PASS")

        val ctx = lastContext ?: error("E_PATCH14_MISSING_CONTEXT")
        val originalResult = ctx.outcome
        val originalTrace = ctx.branchTrace.toList()
        val originalDiag = ctx.diagnostics.toList()
        val counts = manager.metrics.snapshot()
        val baseCounts = manager.bootstrap.metrics.snapshot()
        insist("E_PATCH14_COUNTS",
            counts["patch14.applied"] == 24L &&
            counts["patch14.experimental.legacy.calls"] == 24L &&
            counts["patch14.corrected.negative.calls"] == 24L &&
            baseCounts["patch13.applied"] == 24L)
        insist("E_PATCH14_REPLAY",
            machine {
                manager.bootstrap.dispatcher.dispatch(ctx.baseContext)
            } == "E_PATCH13_CONTEXT_NOT_READY" &&
            ctx.outcome === originalResult &&
            ctx.branchTrace == originalTrace &&
            ctx.diagnostics == originalDiag &&
            manager.metrics.snapshot() == counts &&
            manager.bootstrap.metrics.snapshot() == baseCounts)
        rejects {
            manager.applyNegativeGateDirectionPatch(
                f, f, ExactInt.ZERO, f, 42, ExactInt.ONE, 1)
        }
        rejects {
            manager.applyNegativeGateDirectionPatch(
                f, f, ExactInt.ONE, f, 42, ExactInt.ZERO, 1)
        }
        insist("E_PATCH14_ROLLBACK",
            ctx.outcome === originalResult &&
            ctx.baseContext.patch13Applied &&
            manager.metrics.snapshot() == counts &&
            manager.bootstrap.metrics.snapshot() == baseCounts)
        println("STAGE29_MANAGER_REPLAY_ROLLBACK_AND_METRICS_GREEN")
        println("STAGE29_PATCH_NATIVE_GREEN")
    }
}
