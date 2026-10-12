package pastafari

/** Cam 12: darganfod nad yw legacyPrior yn gallu gweld yr hanes cudd. */
object Stage12Tests {
    private fun insist(code: String, yes: Boolean) { check(yes) { code } }
    private fun machineCode(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY06_ARGUMENTS" }
        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val adapter = LegacyPriorAdapter()
        val oracle = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f, f))
        val correctedHidden = manager.applyHiddenNearnessPatch(f, f, 1).patch05CorrectedValue
            ?: error("E_DISCOVERY06_PATCH05_HIDDEN")
        insist("E_DISCOVERY06_CORRECTED_HIDDEN", correctedHidden == oracle[1])
        val visible = listOf<ExactInt?>(null, correctedHidden)
        val proper = adapter.legacyPrior(visible, 2, 1)
        insist("E_DISCOVERY06_VISIBLE_PROBE", proper.visibleIndex == 2 && proper.back == 1 &&
            proper.slot == 1 && proper.value == oracle[1])
        val longer = listOf<ExactInt?>(null, ExactInt.of(101), ExactInt.of(202), ExactInt.of(303))
        insist("E_DISCOVERY06_VISIBLE_SLOT_1", adapter.legacyPrior(longer, 4, 3).value == ExactInt.of(101))
        insist("E_DISCOVERY06_VISIBLE_SLOT_3", adapter.legacyPrior(longer, 4, 1).value == ExactInt.of(303))
        println("STAGE12_VISIBLE_PROBE_MATCH_1")
        println("STAGE12_VISIBLE_LEGACY_VALID_PASS")

        var red = 0
        val hiddenCases = listOf(1 to 0, 3 to -2, 7 to -6)
        for ((back, wantedSlot) in hiddenCases) {
            val raw = adapter.legacyPrior(visible, 1, back)
            val expectedHiddenK = 1 - wantedSlot
            insist("E_DISCOVERY06_CORRECT_SLOT_${back}", raw.visibleIndex == 1 &&
                raw.back == back && raw.slot == wantedSlot)
            insist("E_DISCOVERY06_HIDDEN_MISSING_${back}", raw.value == null &&
                oracle[expectedHiddenK] != ExactInt.ZERO)
            println("STAGE12_HIDDEN_SLOT_${wantedSlot}_EXPECTED_RED")
            red++
        }
        insist("E_DISCOVERY06_RED_COUNT", red == 3)
        println("STAGE12_EXPECTED_RED_3")
        println("STAGE12_MISSING_HISTORY_MATCH_0")

        val production = manager.observeLegacyPrior(f, f)
        val prodVisible = production.discovery06VisibleStore ?: error("E_DISCOVERY06_NO_VISIBLE")
        val prodHidden = production.discovery06HiddenStorage ?: error("E_DISCOVERY06_NO_HIDDEN")
        insist("E_DISCOVERY06_REAL_PROBE", production.phase == "DISCOVERY_06" &&
            production.status == "LEGACY_PRIOR_OBSERVED" &&
            production.branchTrace == listOf("BOOT", "DISCOVERY_06") &&
            production.diagnostics == listOf("DISCOVERY_06_VISIBLE_ONLY_LEGACY_PRIOR") &&
            production.discovery06PriorI == 2 && production.discovery06PriorBack == 1 &&
            production.discovery06PriorSlot == 1 &&
            production.discovery06PriorValue == oracle[1] &&
            production.discovery06Patch05HiddenOne == oracle[1] &&
            production.discovery06ErrorId == null &&
            production.discovery06InvocationCount == 1 &&
            prodVisible == visible && prodHidden.size == 8 &&
            (1..7).all { k -> prodHidden[8-k] == oracle[k] })
        println("STAGE12_PRODUCTION_VISIBLE_PROBE_PASS")

        for ((back,slot) in hiddenCases) {
            val ctx = manager.observeLegacyPrior(f, f, 1, back)
            insist("E_DISCOVERY06_CTX_MISSING_${back}", ctx.discovery06PriorSlot == slot &&
                ctx.discovery06PriorValue == null &&
                ctx.discovery06ErrorId == "E_DISCOVERY06_MISSING_HIDDEN_HISTORY" &&
                ctx.discovery06InvocationCount == 1 &&
                ctx.discovery06Patch05HiddenOne == oracle[1])
        }
        insist("E_DISCOVERY06_PRODUCTION_CALLS", manager.metrics.snapshot()["discovery06.legacy.prior.calls"] == 4L)
        println("STAGE12_PRODUCTION_HIDDEN_RED_3")
        println("STAGE12_CONTEXT_OWNER_PASS")

        insist("E_DISCOVERY06_INVALID_I", try { adapter.legacyPrior(visible, 0, 1); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_DISCOVERY06_INVALID_BACK", try { adapter.legacyPrior(visible, 2, 8); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_DISCOVERY06_BAD_SENTINEL", try { adapter.legacyPrior(listOf(ExactInt.ONE), 2, 1); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_DISCOVERY06_BAD_PREP", try { manager.observeLegacyPrior(f, f, 0, 1);false }
            catch (e: IllegalArgumentException) { true })
        val snapshot = manager.metrics.snapshot()
        val trace = production.branchTrace.toList()
        val diagnostics = production.diagnostics.toList()
        insist("E_DISCOVERY06_REPLAY", machineCode { manager.dispatcher.dispatch(production) } ==
            "E_DISCOVERY06_CONTEXT_NOT_READY" &&
            production.branchTrace == trace && production.diagnostics == diagnostics &&
            snapshot == manager.metrics.snapshot())
        val bypass = BaseMonsterContext(f, f, phase="DISCOVERY_06", discovery06PriorI=2,
            discovery06PriorBack=1)
        insist("E_DISCOVERY06_BOOT_GUARD", machineCode { manager.dispatcher.dispatch(bypass) } ==
            "E_DISCOVERY06_CONTEXT_NOT_READY" && bypass.discovery06VisibleStore == null &&
            bypass.discovery06PriorValue == null && snapshot == manager.metrics.snapshot())
        println("STAGE12_GUARDS_REPLAY_PASS")

        val other = manager.observeLegacyPrior(f - 99L, f + 201L)
        insist("E_DISCOVERY06_INVOCATION_ISOLATION", other !== production &&
            other.discovery06VisibleStore !== prodVisible &&
            other.discovery06HiddenStorage !== prodHidden &&
            other.discovery06Patch05HiddenOne != production.discovery06Patch05HiddenOne &&
            production.discovery06PriorValue == oracle[1])
        println("STAGE12_DIFFERENT_DAYS_OWNERSHIP_PASS")
        insist("E_DISCOVERY06_PATCH01", manager.applySavePatch(f, f, NormativeCore.M)
            .patch01Output == NormativeCore.M)
        insist("E_DISCOVERY06_PATCH02", manager.applyDayTagPatch(f, f, f)
            .patch02Output == ExactInt.ONE)
        insist("E_DISCOVERY06_PATCH03", manager.applyDistancePatch(f, f)
            .patch03Output == ExactInt.ONE)
        insist("E_DISCOVERY06_PATCH04", manager.applyStonePatch(f, f)
            .patch04StoneRows?.get(46)?.components() == NormativeCore.STONES[46].toList())
        insist("E_DISCOVERY06_PATCH05", manager.applyHiddenNearnessPatch(f, f)
            .patch05CorrectedValue == oracle[1])
        insist("E_DISCOVERY06_PRESERVE_DISCOVERY05", manager.observeLegacyHiddenDrop(f, f)
            .discovery05Actual == oracle[7])
        println("STAGE12_EARLIER_ROUTES_PASS")
        println("STAGE12_COMPLETE_EXPECTED_RED")
    }
}
