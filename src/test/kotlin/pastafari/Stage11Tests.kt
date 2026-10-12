package pastafari

/** Cam 11: rhaid cadw'r graith darllen uniongyrchol a chywiro agosrwydd 1..7. */
object Stage11Tests {
    private fun insist(code: String, valid: Boolean) { check(valid) { code } }
    private fun machineCode(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH05_ARGUMENTS" }
        val f = NormativeCore.FOUNDATION_DAY
        val oracle = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f, f))
        val manager = MonsterBootstrapManager()
        val wrapper = HiddenNearnessPatchWrapper()
        val legacy = LegacyHiddenDropAdapter()

        var passed = 0
        val contexts = ArrayList<BaseMonsterContext>()
        for (k in 1..7) {
            val context = manager.applyHiddenNearnessPatch(f, f, k)
            contexts.add(context)
            val storage = context.patch05BackwardStorage ?: error("E_PATCH05_NO_STORAGE")
            val rows = context.patch05PatchedStoneRows ?: error("E_PATCH05_NO_STONES")
            val corrected = context.patch05CorrectedValue ?: error("E_PATCH05_NO_RESULT")
            val old = context.patch05LegacyDirectValue ?: error("E_PATCH05_NO_SCAR")
            insist("E_PATCH05_CONTEXT_${k}", context.phase == "PATCH_05" &&
                context.status == "PATCHED_HIDDEN" && context.branchTrace == listOf("BOOT", "PATCH_05") &&
                context.diagnostics == listOf("PATCH_05_HIDDEN_NEARNESS_8_MINUS_K") &&
                context.patch05RequestedK == k && context.patch05PhysicalSlot == 8-k &&
                context.patch05Applied && context.patch05InvocationCount == 1)
            insist("E_PATCH05_STONE_COUNT_${k}", context.patch05HiddenCount == 7 &&
                context.patch05StoneLegacyCalls == 45 && rows.size == 47 &&
                rows[46].components() == NormativeCore.STONES[46].toList())
            insist("E_PATCH05_STORAGE_${k}", storage.size == 8 && storage[0] == ExactInt.ZERO &&
                (1..7).all { physical -> storage[physical] == oracle[8-physical] })
            insist("E_PATCH05_LEGACY_${k}", old == legacy.legacyHiddenDirectByAssumedNearness(storage, k) &&
                old == storage[k] && old == oracle[8-k])
            insist("E_PATCH05_CORRECTION_${k}", corrected == oracle[k] &&
                corrected == wrapper.hiddenByNearness(storage, k) &&
                corrected == storage[8-k])
            if (k == 1 || k == 2 || k == 6 || k == 7)
                insist("E_PATCH05_PRESERVED_RED_${k}", old != corrected)
            if (k == 4) insist("E_PATCH05_FIXED_POINT", old == corrected)
            passed++
            println("STAGE11_K${k}_GREEN")
        }
        insist("E_PATCH05_SEVEN_GREEN", passed == 7)
        val first = contexts[0]
        insist("E_PATCH05_PRODUCTION_K1", first.patch05RequestedK == 1 &&
            first.patch05PhysicalSlot == 7 && first.patch05LegacyDirectValue == oracle[7] &&
            first.patch05CorrectedValue == oracle[1])
        val count = manager.metrics.snapshot()
        insist("E_PATCH05_CALL_COUNT", count["patch05.legacy.direct.calls"] == 7L &&
            count["patch05.applied"] == 7L)
        println("STAGE11_PATCH_GREEN_7")
        println("STAGE11_PRESERVED_DISCOVERY05_RED_4")
        println("STAGE11_FIXED_MIDPOINT_K4_GREEN")
        println("STAGE11_WRONG_ACCESS_CALLED_7")

        val stored = first.patch05BackwardStorage ?: error("E_PATCH05_NO_STORE")
        val outcome = wrapper.patch(stored, 1)
        insist("E_PATCH05_WRAPPER_TRACE", outcome.requestedK == 1 &&
            outcome.physicalSlot == 7 && outcome.legacyDirectValue == oracle[7] &&
            outcome.correctedValue == oracle[1])
        val synthetic = listOf(0L,11L,12L,13L,14L,15L,16L,17L).map(ExactInt::of)
        for (k in 1..7) {
            val wrapped = wrapper.patch(synthetic, k)
            insist("E_PATCH05_TRANSLATE_${k}", wrapped.physicalSlot == 8-k &&
                wrapped.legacyDirectValue == ExactInt.of(10L+k) &&
                wrapped.correctedValue == ExactInt.of(18L-k))
        }
        insist("E_PATCH05_LOW_K", try { wrapper.patch(stored, 0);false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH05_HIGH_K", try { wrapper.patch(stored, 8);false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH05_TRUNCATED", try { wrapper.patch(stored.dropLast(1), 4);false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH05_DIRECT_GUARD", try { wrapper.hiddenByNearness(stored, 0);false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH05_EAGER_GUARD", try { manager.applyHiddenNearnessPatch(f, f, 8);false }
            catch (e: IllegalArgumentException) { true })
        println("STAGE11_TRANSLATOR_7_PASS")
        println("STAGE11_WRAPPER_GUARDS_PASS")

        val different = manager.applyHiddenNearnessPatch(f - 99L, f + 201L, 6)
        insist("E_PATCH05_INVOCATION_OWNER", different !== first &&
            different.patch05RequestedK == 6 && different.patch05PhysicalSlot == 2 &&
            different.patch05BackwardStorage !== stored &&
            different.patch05BackwardStorage != stored &&
            different.patch05PatchedStoneRows !== first.patch05PatchedStoneRows)
        insist("E_PATCH05_FIRST_UNCHANGED", first.patch05CorrectedValue == oracle[1] &&
            first.patch05LegacyDirectValue == oracle[7] && first.patch05BackwardStorage === stored)
        val earlier = manager.metrics.snapshot()
        val trace = first.branchTrace.toList()
        val diags = first.diagnostics.toList()
        insist("E_PATCH05_REPLAY_REJECTED", machineCode { manager.dispatcher.dispatch(first) } ==
            "E_PATCH05_CONTEXT_NOT_READY" && earlier == manager.metrics.snapshot() &&
            trace == first.branchTrace && diags == first.diagnostics &&
            first.patch05InvocationCount == 1 && first.patch05Applied)
        val bypass = BaseMonsterContext(f, f, phase = "PATCH_05", patch05RequestedK = 1)
        insist("E_PATCH05_BOOT_GUARD", machineCode { manager.dispatcher.dispatch(bypass) } ==
            "E_PATCH05_CONTEXT_NOT_READY" && !bypass.patch05Applied &&
            bypass.patch05LegacyDirectValue == null && bypass.patch05CorrectedValue == null &&
            bypass.patch05BackwardStorage == null && manager.metrics.snapshot() == earlier)
        println("STAGE11_CONTEXT_OWNERSHIP_PASS")
        println("STAGE11_BOOT_REPLAY_GUARDS_PASS")

        // Mae'r graith DISCOVERY 05 yn dal yn alwadadwy ac yn anghywir.
        val oldContext = manager.observeLegacyHiddenDrop(f, f, 1)
        insist("E_PATCH05_PRESERVE_DISCOVERY05", oldContext.discovery05Actual == oracle[7] &&
            oldContext.discovery05Actual != oracle[1] &&
            oldContext.branchTrace == listOf("BOOT", "DISCOVERY_05"))
        insist("E_PATCH05_PREVIOUS_01", manager.applySavePatch(f, f, NormativeCore.M)
            .patch01Output == NormativeCore.M)
        insist("E_PATCH05_PREVIOUS_02", manager.applyDayTagPatch(f, f, f)
            .patch02Output == ExactInt.ONE)
        insist("E_PATCH05_PREVIOUS_03", manager.applyDistancePatch(f, f)
            .patch03Output == ExactInt.ONE)
        insist("E_PATCH05_PREVIOUS_04", manager.applyStonePatch(f, f)
            .patch04StoneRows?.get(46)?.components() == NormativeCore.STONES[46].toList())
        println("STAGE11_EARLIER_ROUTES_PASS")
        println("STAGE11_COMPLETE_GREEN")
    }
}
