package pastafari

/** Cam 6 / DISCOVERY 03: mae'r oracl yn y profion yn unig. */
object Stage06Tests {
    private fun insist(code: String, yes: Boolean) { check(yes) { code } }
    private fun errorCode(block: () -> Unit): String = try {
        block()
        "NO_ERROR"
    } catch (error: MonsterValidationException) { error.machineCode }

    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY03_ARGUMENTS" }
        val foundation = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        data class Witness(val name: String, val from: ExactInt, val to: ExactInt, val legacy: Long, val normative: Long)
        val witnesses = listOf(
            Witness("BEFORE_LEFT", foundation - 2L, foundation - 1L, 2L, 2L),
            Witness("AFTER_RIGHT", foundation + 1L, foundation + 2L, 2L, 2L),
            Witness("BEFORE_LEFT_SECOND", foundation - 3L, foundation - 2L, 2L, 2L),
            Witness("SAME_BEFORE", foundation - 1L, foundation - 1L, 0L, 1L),
            Witness("SAME_FOUNDATION", foundation, foundation, 0L, 1L),
            Witness("CROSS_FOUNDATION", foundation - 1L, foundation, 1L, 2L),
            Witness("CROSS_TWO", foundation - 1L, foundation + 1L, 1L, 3L),
            Witness("CROSS_FOUR", foundation - 2L, foundation + 2L, 1L, 5L)
        )
        var red = 0
        var match = 0
        val histories = ArrayList<BaseMonsterContext>()
        for (witness in witnesses) {
            val result = manager.observeLegacyDistance(witness.from, witness.to)
            histories.add(result)
            val actual = result.discovery03Output ?: error("E_DISCOVERY03_OUTPUT_NULL")
            val normative = (witness.to - witness.from).abs() + ExactInt.ONE
            insist("E_DISCOVERY03_LEGACY_${witness.name}", actual == ExactInt.of(witness.legacy))
            insist("E_DISCOVERY03_NORMATIVE_${witness.name}", normative == ExactInt.of(witness.normative))
            insist("E_DISCOVERY03_ORACLE_${witness.name}", normative == NormativeCore.workCounts(witness.from, witness.to).distance)
            insist("E_DISCOVERY03_CONTEXT_${witness.name}", result.calculationDay == witness.from &&
                result.targetDay == witness.to && result.discovery03CalculationDay == witness.from &&
                result.discovery03TargetDay == witness.to && result.discovery03Output == actual &&
                result.status == "LEGACY_DISTANCE_OBSERVED" && result.phase == "DISCOVERY_03" &&
                result.branchTrace == listOf("BOOT", "DISCOVERY_03") &&
                result.diagnostics == listOf("DISCOVERY_03_LEGACY_TAG_DISTANCE") &&
                result.patch01Output == null && result.patch02Output == null &&
                result.discovery01Output == null && result.discovery02Output == null)
            val isRed = actual != normative
            if (isRed) red++ else match++
            println("STAGE06_CASE_${witness.name}_${if (isRed) "EXPECTED_RED" else "MATCH"}")
        }
        insist("E_DISCOVERY03_EXACT_COUNTS", red == 5 && match == 3)
        println("STAGE06_EXPECTED_RED_5")
        println("STAGE06_MATCH_3")

        // Yr hen gyfrifiad yn dal yn alwadadwy; yr un canlyniad yn y ddau gyfeiriad.
        val adapter = LegacyDistanceAdapter()
        for (a in -10..10) for (b in -10..10) {
            val c = foundation + a.toLong()
            val t = foundation + b.toLong()
            val direct = adapter.oldDistance(c, t)
            val routed = manager.observeLegacyDistance(c, t).discovery03Output
            insist("E_DISCOVERY03_MATRIX_${a}_${b}", routed == direct)
            insist("E_DISCOVERY03_SYMMETRY_${a}_${b}", direct == adapter.oldDistance(t, c))
            insist("E_DISCOVERY03_NOT_NEGATIVE_${a}_${b}", direct >= ExactInt.ZERO)
            if (a == b) insist("E_DISCOVERY03_DIAGONAL_${a}", direct == ExactInt.ZERO)
        }
        println("STAGE06_MATRIX_PASS_441")

        // Rheoli perchnogaeth a gwiriadau cyn addasu unrhyw gyflwr.
        val saved = histories.first()
        val priorState = saved.discovery03Output
        val priorTrace = saved.branchTrace.toList()
        val priorDiagnostics = saved.diagnostics.toList()
        val previousMetrics = manager.metrics.snapshot()
        insist("E_DISCOVERY03_REPLAY", errorCode { manager.dispatcher.dispatch(saved) } ==
            "E_DISCOVERY03_CONTEXT_NOT_READY" && saved.discovery03Output == priorState &&
            saved.branchTrace == priorTrace && saved.diagnostics == priorDiagnostics &&
            manager.metrics.snapshot() == previousMetrics)
        val notReady = BaseMonsterContext(foundation, foundation, phase = "DISCOVERY_03",
            discovery03CalculationDay = foundation, discovery03TargetDay = foundation)
        insist("E_DISCOVERY03_BOOT_GUARD", errorCode { manager.dispatcher.dispatch(notReady) } ==
            "E_DISCOVERY03_CONTEXT_NOT_READY" && notReady.discovery03Output == null &&
            manager.metrics.snapshot() == previousMetrics)
        val missingCalc = manager.prepare(foundation, foundation)
        missingCalc.phase = "DISCOVERY_03"
        insist("E_DISCOVERY03_MISSING_CALC", errorCode { manager.dispatcher.dispatch(missingCalc) } ==
            "E_DISCOVERY03_NO_CALCULATION_DAY" && missingCalc.branchTrace == listOf("BOOT"))
        val missingTarget = manager.prepare(foundation, foundation)
        missingTarget.phase = "DISCOVERY_03"
        missingTarget.discovery03CalculationDay = foundation
        insist("E_DISCOVERY03_MISSING_TARGET", errorCode { manager.dispatcher.dispatch(missingTarget) } ==
            "E_DISCOVERY03_NO_TARGET_DAY")
        val mismatch = manager.prepare(foundation, foundation)
        mismatch.phase = "DISCOVERY_03"
        mismatch.discovery03CalculationDay = foundation
        mismatch.discovery03TargetDay = foundation + 1L
        insist("E_DISCOVERY03_WRONG_CONTEXT", errorCode { manager.dispatcher.dispatch(mismatch) } ==
            "E_DISCOVERY03_CONTEXT_MISMATCH" && mismatch.discovery03Output == null &&
            mismatch.branchTrace == listOf("BOOT"))
        insist("E_DISCOVERY03_METRIC_NO_PARTIAL_COMMIT", manager.metrics.snapshot()["discovery03.legacy"] ==
            8L + 441L)
        insist("E_DISCOVERY03_STABLE_HISTORY", histories.all { it.branchTrace == listOf("BOOT", "DISCOVERY_03") })
        println("STAGE06_OWNERSHIP_GUARDS_PASS")

        // Nid yw Cam 6 yn newid PATCH 02 nac unrhyw graith gynharach.
        val originalTag = manager.observeLegacyDayTag(foundation, foundation, foundation)
        val patchedTag = manager.applyDayTagPatch(foundation, foundation, foundation)
        val historicalSave = manager.observeLegacyRemainder(foundation, foundation, NormativeCore.M)
        val patchedSave = manager.applySavePatch(foundation, foundation, NormativeCore.M)
        insist("E_DISCOVERY03_HISTORY", originalTag.discovery02Output == ExactInt.ZERO &&
            patchedTag.patch02Output == ExactInt.ONE && historicalSave.discovery01Output == ExactInt.ZERO &&
            patchedSave.patch01Output == NormativeCore.M)
        println("STAGE06_EARLIER_ROUTES_PASS")
        println("STAGE06_NATIVE_EXPECTED_RED_PASS")
    }
}
