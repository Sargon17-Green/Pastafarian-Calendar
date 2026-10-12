package pastafari

/** Cam 13 — PATCH 06: hanes positif drwy legacyPrior, hanes cudd drwy hiddenByNearness. */
object Stage13Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machineCode(f: () -> Unit): String = try {
        f(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH06_ARGUMENTS" }
        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val raw = LegacyPriorAdapter()
        val wrapper = PriorPatchWrapper()
        val oracle = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f, f))

        // Mae'r gangen weledig yn galw'r helper raw ac nid oes angen hanes cudd.
        val positive = manager.applyPriorPatch(f, f)
        val visible = positive.patch06VisibleStore ?: error("E_PATCH06_NO_VISIBLE")
        val physical = positive.patch06HiddenStorage ?: error("E_PATCH06_NO_HIDDEN")
        insist("E_PATCH06_POSITIVE_CONTEXT", positive.phase == "PATCH_06" &&
            positive.status == "PATCHED_PRIOR" &&
            positive.branchTrace == listOf("BOOT", "PATCH_06") &&
            positive.diagnostics == listOf("PATCH_06_PRIOR_VISIBLE_OR_HIDDEN") &&
            positive.patch06PriorI == 2 && positive.patch06PriorBack == 1 &&
            positive.patch06Slot == 1 && positive.patch06HiddenK == null &&
            positive.patch06LegacyPriorCalled == true &&
            positive.patch06Source == "VISIBLE_LEGACY" &&
            positive.patch06Applied && positive.patch06InvocationCount == 1)
        insist("E_PATCH06_POSITIVE_VALUE", positive.patch06Output == oracle[1] &&
            positive.patch06Patch05HiddenOne == oracle[1] &&
            raw.legacyPrior(visible, 2, 1).value == oracle[1] &&
            physical.size == 8 && positive.patch06StoneLegacyCalls == 45)
        insist("E_PATCH06_HIDDEN_LAYOUT", (1..7).all { k -> physical[8-k] == oracle[k] })
        val synthetic = listOf<ExactInt?>(null, ExactInt.of(101), ExactInt.of(202), ExactInt.of(303))
        val positiveThree = wrapper.priorPatch(synthetic, emptyList(), 4, 1)
        val positiveOne = wrapper.priorPatch(synthetic, emptyList(), 4, 3)
        insist("E_PATCH06_SYNTHETIC_POSITIVE", positiveThree.correctedValue == ExactInt.of(303) &&
            positiveThree.slot == 3 && positiveThree.hiddenK == null &&
            positiveThree.legacyPriorCalled && positiveThree.source == "VISIBLE_LEGACY" &&
            positiveOne.correctedValue == ExactInt.of(101) && positiveOne.slot == 1 &&
            positiveOne.legacyPriorCalled)
        println("STAGE13_POSITIVE_LEGACY_CALLED_PASS")
        println("STAGE13_POSITIVE_NO_HIDDEN_STORE_REQUIRED_PASS")

        var green = 0
        for (back in 1..7) {
            val ctx = manager.applyPriorPatch(f, f, 1, back)
            val old = manager.observeLegacyPrior(f, f, 1, back)
            val storage = ctx.patch06HiddenStorage ?: error("E_PATCH06_NO_STORAGE")
            insist("E_PATCH06_CORRECTED_${back}", ctx.patch06PriorI == 1 &&
                ctx.patch06PriorBack == back && ctx.patch06Slot == 1-back &&
                ctx.patch06HiddenK == back && ctx.patch06Source == "HIDDEN_PATCH05" &&
                ctx.patch06LegacyPriorCalled == false &&
                ctx.patch06Output == oracle[back] && storage[8-back] == oracle[back] &&
                ctx.patch06Applied && ctx.patch06InvocationCount == 1 &&
                ctx.patch06Patch05HiddenOne == oracle[1] &&
                ctx.patch06StoneLegacyCalls == 45)
            insist("E_PATCH06_UNMODIFIED_RAW_${back}", old.discovery06PriorValue == null &&
                old.discovery06ErrorId == "E_DISCOVERY06_MISSING_HIDDEN_HISTORY")
            green++
            println("STAGE13_HIDDEN_K${back}_GREEN")
        }
        insist("E_PATCH06_ALL_GREEN", green == 7)
        println("STAGE13_HIDDEN_GREEN_7")
        println("STAGE13_PRESERVED_DISCOVERY06_RED_3")
        insist("E_PATCH06_PRODUCTION_METRICS", manager.metrics.snapshot()["patch06.applied"] == 8L &&
            manager.metrics.snapshot()["patch06.legacy.prior.calls"] == 1L &&
            manager.metrics.snapshot()["patch06.hidden.nearness.calls"] == 7L)
        println("STAGE13_BRANCH_DISPATCH_COUNTS_PASS")

        // Mae'r gangen gudd yn defnyddio'r cyfieithydd heb galw'r hen prior.
        for (k in 1..7) {
            val outcome = wrapper.priorPatch(listOf(null), physical, 1, k)
            insist("E_PATCH06_DIRECT_MAP_${k}", outcome.slot == 1-k &&
                outcome.hiddenK == k && !outcome.legacyPriorCalled &&
                outcome.source == "HIDDEN_PATCH05" && outcome.correctedValue == oracle[k])
        }
        insist("E_PATCH06_NO_PHYSICAL_HIDDEN", try {
            wrapper.priorPatch(listOf(null), emptyList(), 1, 1); false
        } catch (e: IllegalArgumentException) { true })
        insist("E_PATCH06_BAD_I", try { wrapper.priorPatch(visible, physical, 0, 1); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH06_BAD_BACK", try { wrapper.priorPatch(visible, physical, 1, 8); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH06_BAD_SENTINEL", try {
            wrapper.priorPatch(listOf(ExactInt.ONE), physical, 2, 1); false
        } catch (e: IllegalArgumentException) { true })
        insist("E_PATCH06_MISSING_VISIBLE", try {
            wrapper.priorPatch(visible, physical, 4, 1); false
        } catch (e: IllegalArgumentException) { true })
        insist("E_PATCH06_INVALID_MANAGER", try {
            manager.applyPriorPatch(f, f, 1, 0); false
        } catch (e: IllegalArgumentException) { true })
        println("STAGE13_HIDDEN_TRANSLATOR_GREEN_7")
        println("STAGE13_BOUNDARY_GUARDS_PASS")

        val snapshot = manager.metrics.snapshot()
        val oldTrace = positive.branchTrace.toList()
        val oldDiag = positive.diagnostics.toList()
        insist("E_PATCH06_REPLAY", machineCode { manager.dispatcher.dispatch(positive) } ==
            "E_PATCH06_CONTEXT_NOT_READY" && manager.metrics.snapshot() == snapshot &&
            positive.branchTrace == oldTrace && positive.diagnostics == oldDiag &&
            positive.patch06InvocationCount == 1 && positive.patch06Applied)
        val bypass = BaseMonsterContext(f, f, phase = "PATCH_06", patch06PriorI = 1, patch06PriorBack = 1)
        insist("E_PATCH06_NO_BOOT", machineCode { manager.dispatcher.dispatch(bypass) } ==
            "E_PATCH06_CONTEXT_NOT_READY" && bypass.patch06Output == null &&
            bypass.patch06VisibleStore == null && !bypass.patch06Applied &&
            snapshot == manager.metrics.snapshot())
        println("STAGE13_BOOT_REPLAY_GUARDS_PASS")

        val other = manager.applyPriorPatch(f - 99L, f + 201L, 1, 7)
        insist("E_PATCH06_DIFFERENT_OWNER", other !== positive &&
            other.patch06VisibleStore !== positive.patch06VisibleStore &&
            other.patch06HiddenStorage !== positive.patch06HiddenStorage &&
            other.patch06Output != positive.patch06Output &&
            other.patch06HiddenK == 7 && positive.patch06Output == oracle[1] &&
            positive.patch06HiddenStorage === physical)
        println("STAGE13_INVOCATION_OWNERSHIP_PASS")

        insist("E_PATCH06_EARLIER_01", manager.applySavePatch(f, f, NormativeCore.M)
            .patch01Output == NormativeCore.M)
        insist("E_PATCH06_EARLIER_02", manager.applyDayTagPatch(f, f, f)
            .patch02Output == ExactInt.ONE)
        insist("E_PATCH06_EARLIER_03", manager.applyDistancePatch(f, f)
            .patch03Output == ExactInt.ONE)
        insist("E_PATCH06_EARLIER_04", manager.applyStonePatch(f, f)
            .patch04StoneRows?.get(46)?.components() == NormativeCore.STONES[46].toList())
        insist("E_PATCH06_EARLIER_05", manager.applyHiddenNearnessPatch(f, f, 7)
            .patch05CorrectedValue == oracle[7])
        insist("E_PATCH06_PREVIOUS_SCAR", manager.observeLegacyPrior(f, f, 1, 1)
            .discovery06PriorValue == null)
        println("STAGE13_EARLIER_ROUTES_PASS")
        println("STAGE13_COMPLETE_GREEN")
    }
}
