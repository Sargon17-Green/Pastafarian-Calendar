package pastafari

/** Cam 7: profi'r patch a chadw'r nam Cam 6 yn annibynnol. */
object Stage07Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }

    private fun machineError(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    data class Witness(
        val name: String,
        val calculationOffset: Long,
        val targetOffset: Long,
        val legacy: Long,
        val corrected: Long,
        val replaced: Boolean
    )

    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH03_ARGUMENTS" }
        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val adapter = LegacyDistanceAdapter()
        val wrapper = DistancePatchWrapper()
        val witnesses = listOf(
            Witness("BEFORE_LEFT", -2, -1, 2, 2, true),
            Witness("AFTER_RIGHT", 1, 2, 2, 2, true),
            Witness("BEFORE_LEFT_SECOND", -3, -2, 2, 2, true),
            Witness("SAME_BEFORE", -1, -1, 0, 1, false),
            Witness("SAME_FOUNDATION", 0, 0, 0, 1, false),
            Witness("CROSS_FOUNDATION", -1, 0, 1, 2, false),
            Witness("CROSS_TWO", -1, 1, 1, 3, true),
            Witness("CROSS_FOUR", -2, 2, 1, 5, true)
        )
        val observed = ArrayList<BaseMonsterContext>()
        var red = 0
        var changedBase = 0
        for (w in witnesses) {
            val c = f + w.calculationOffset
            val t = f + w.targetOffset
            val oldRoute = manager.observeLegacyDistance(c, t)
            val patch = manager.applyDistancePatch(c, t)
            observed.add(patch)
            val normative = NormativeCore.workCounts(c, t).distance
            insist("E_PATCH03_WITNESS_${w.name}", patch.patch03Output == ExactInt.of(w.corrected) &&
                patch.patch03Output == normative && patch.patch03LegacyOutput == ExactInt.of(w.legacy) &&
                patch.patch03LegacyOutput == oldRoute.discovery03Output &&
                patch.patch03ChronologicalBase == (t - c).abs() &&
                patch.patch03SelectedBase == (t - c).abs() &&
                patch.patch03ReplacementApplied == w.replaced &&
                patch.patch03CalculationDay == c && patch.patch03TargetDay == t &&
                patch.calculationDay == c && patch.targetDay == t &&
                patch.status == "PATCHED_DISTANCE" && patch.phase == "PATCH_03" &&
                patch.branchTrace == listOf("BOOT", "PATCH_03") &&
                patch.diagnostics == listOf("PATCH_03_CHRONOLOGICAL_INCLUSIVE_SCAR") &&
                patch.discovery03Output == null && patch.patch02Output == null &&
                patch.patch01Output == null)
            if (oldRoute.discovery03Output != normative) red++
            if (w.replaced) changedBase++
            println("STAGE07_WITNESS_${w.name}_PATCH_GREEN")
        }
        insist("E_PATCH03_LEGACY_RED_COUNT", red == 5)
        insist("E_PATCH03_BASE_REPLACED_COUNT", changedBase == 5)
        insist("E_PATCH03_METRICS_8", manager.metrics.snapshot()["patch03.legacy.calls"] == 8L &&
            manager.metrics.snapshot()["patch03.applied"] == 8L &&
            manager.metrics.snapshot()["patch03.replaced"] == 5L)
        println("STAGE07_WITNESSES_GREEN_8")
        println("STAGE07_PRESERVED_DISCOVERY03_RED_5")

        // Mae'r rhaglen yn cywiro pellter ar ddwy ochr y Sylfaen a phob llinell groes.
        var matrix = 0
        var expectedReplacements = 5L
        for (a in -10..10) for (b in -10..10) {
            val c = f + a.toLong()
            val t = f + b.toLong()
            val legacy = adapter.oldDistance(c, t)
            val chronological = (t - c).abs()
            val patch = manager.applyDistancePatch(c, t)
            insist("E_PATCH03_MATRIX_${a}_${b}", patch.patch03LegacyOutput == legacy &&
                patch.patch03ChronologicalBase == chronological &&
                patch.patch03SelectedBase == chronological &&
                patch.patch03ReplacementApplied == (legacy != chronological) &&
                patch.patch03Output == chronological + ExactInt.ONE &&
                patch.patch03Output == NormativeCore.workCounts(c, t).distance)
            if (legacy != chronological) expectedReplacements++
            matrix++
        }
        insist("E_PATCH03_MATRIX_COUNT", matrix == 441)
        insist("E_PATCH03_MATRIX_METRICS", manager.metrics.snapshot()["patch03.applied"] == 449L &&
            manager.metrics.snapshot()["patch03.legacy.calls"] == 449L &&
            manager.metrics.snapshot()["patch03.replaced"] == expectedReplacements)
        println("STAGE07_MATRIX_GREEN_441")

        // Yr hen gyfrifiad yw'r un a elwir yn wirioneddol, nid rhyw oracl.
        val same = wrapper.patchDistance(f, f, ExactInt.ZERO)
        val different = wrapper.patchDistance(f - 2L, f + 2L, ExactInt.ONE)
        insist("E_PATCH03_CONDITIONAL", !same.replacedLegacyBase &&
            same.chronologicalBase == ExactInt.ZERO && same.selectedBase == ExactInt.ZERO &&
            same.inclusiveDistance == ExactInt.ONE && different.replacedLegacyBase &&
            different.chronologicalBase == ExactInt.of(4) && different.selectedBase == ExactInt.of(4) &&
            different.inclusiveDistance == ExactInt.of(5))
        insist("E_PATCH03_NEGATIVE_INPUT", try {
            wrapper.patchDistance(f, f, ExactInt.of(-1)); false
        } catch (e: IllegalArgumentException) { true })
        println("STAGE07_CONDITIONAL_WRAPPER_PASS")

        val history = observed.first()
        val originalOutput = history.patch03Output
        val originalLegacy = history.patch03LegacyOutput
        val originalTrace = history.branchTrace.toList()
        val originalDiagnostics = history.diagnostics.toList()
        val metricsBefore = manager.metrics.snapshot()
        insist("E_PATCH03_REPLAY", machineError { manager.dispatcher.dispatch(history) } ==
            "E_PATCH03_CONTEXT_NOT_READY" && history.patch03Output == originalOutput &&
            history.patch03LegacyOutput == originalLegacy && history.branchTrace == originalTrace &&
            history.diagnostics == originalDiagnostics && manager.metrics.snapshot() == metricsBefore)
        val unprepared = BaseMonsterContext(f, f, phase="PATCH_03", patch03CalculationDay=f, patch03TargetDay=f)
        insist("E_PATCH03_BOOT", machineError { manager.dispatcher.dispatch(unprepared) } ==
            "E_PATCH03_CONTEXT_NOT_READY" && unprepared.patch03Output == null)
        val missingCalc = manager.prepare(f, f)
        missingCalc.phase = "PATCH_03"
        insist("E_PATCH03_MISSING_CALC", machineError { manager.dispatcher.dispatch(missingCalc) } ==
            "E_PATCH03_NO_CALCULATION_DAY")
        val missingTarget = manager.prepare(f, f)
        missingTarget.phase = "PATCH_03"
        missingTarget.patch03CalculationDay = f
        insist("E_PATCH03_MISSING_TARGET", machineError { manager.dispatcher.dispatch(missingTarget) } ==
            "E_PATCH03_NO_TARGET_DAY")
        val invalid = manager.prepare(f, f)
        invalid.phase = "PATCH_03"
        invalid.patch03CalculationDay = f
        invalid.patch03TargetDay = f + 1L
        insist("E_PATCH03_WRONG_CONTEXT", machineError { manager.dispatcher.dispatch(invalid) } ==
            "E_PATCH03_CONTEXT_MISMATCH" && invalid.patch03Output == null &&
            invalid.patch03LegacyOutput == null && invalid.branchTrace == listOf("BOOT"))
        insist("E_PATCH03_METRICS_NO_PARTIAL", manager.metrics.snapshot()["patch03.applied"] == 449L &&
            manager.metrics.snapshot()["patch03.legacy.calls"] == 449L)
        insist("E_PATCH03_PRIOR_CONTEXT_STABLE", observed.all { it.branchTrace == listOf("BOOT", "PATCH_03") })
        println("STAGE07_OWNERSHIP_AND_GUARDS_PASS")

        val oldDay = manager.observeLegacyDayTag(f, f, f)
        val fixedDay = manager.applyDayTagPatch(f, f, f)
        val oldSave = manager.observeLegacyRemainder(f, f, NormativeCore.M)
        val patchedSave = manager.applySavePatch(f, f, NormativeCore.M)
        val oldDist = manager.observeLegacyDistance(f, f)
        insist("E_PATCH03_PRIOR_PATHS", oldDay.discovery02Output == ExactInt.ZERO &&
            fixedDay.patch02Output == ExactInt.ONE &&
            oldSave.discovery01Output == ExactInt.ZERO &&
            patchedSave.patch01Output == NormativeCore.M &&
            oldDist.discovery03Output == ExactInt.ZERO)
        println("STAGE07_EARLIER_ROUTES_PASS")
        println("STAGE07_PATCH_GREEN_0")
    }
}
