package pastafari

/** Cam 10: dim ond yr oracl prawf sy'n diffinio'r disgwyl. */
object Stage10Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun errorCode(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY05_ARGUMENTS" }
        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val original = manager.observeLegacyHiddenDrop(f, f)
        val storage = original.discovery05BackwardStorage ?: error("E_DISCOVERY05_NO_STORAGE")
        val stones = original.discovery05PatchedStoneRows ?: error("E_DISCOVERY05_NO_PATCH04_STONES")
        val oracle = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f, f))
        insist("E_DISCOVERY05_CONTEXT", original.status == "LEGACY_HIDDEN_OBSERVED" &&
            original.phase == "DISCOVERY_05" && original.branchTrace == listOf("BOOT", "DISCOVERY_05") &&
            original.diagnostics == listOf("DISCOVERY_05_BACKWARD_HIDDEN_DIRECT_ACCESS"))
        insist("E_DISCOVERY05_COUNT", original.discovery05HiddenCount == 7 && storage.size == 8 &&
            storage[0] == ExactInt.ZERO && original.discovery05Patch04LegacyCalls == 45 && stones.size == 47)
        insist("E_DISCOVERY05_CORRECT_STONES", (1..46).all { i ->
            stones[i].components() == NormativeCore.STONES[i].toList()
        })
        for (k in 1..7) {
            insist("E_DISCOVERY05_PHYSICAL_${k}", storage[k] == oracle[8 - k])
        }
        insist("E_DISCOVERY05_REAL_WRONG_CALL", original.discovery05RequestedK == 1 &&
            original.discovery05Actual == storage[1] && original.discovery05Actual != oracle[1])
        println("STAGE10_BACKWARD_STORAGE_PASS_7")
        println("STAGE10_PATCH04_ROWS_GREEN_230")
        println("STAGE10_PRODUCTION_WRONG_K1_PASS")

        val adapter = LegacyHiddenDropAdapter()
        var red = 0
        var match = 0
        for (k in listOf(1, 2, 4, 6, 7)) {
            val got = adapter.legacyHiddenDirectByAssumedNearness(storage, k)
            val correct = oracle[k]
            val expectedRed = k != 4
            insist("E_DISCOVERY05_EXPECTED_CLASS_${k}", (got != correct) == expectedRed)
            if (got == correct) match++ else red++
            println("STAGE10_K${k}_${if (expectedRed) "EXPECTED_RED" else "MATCH"}")
        }
        insist("E_DISCOVERY05_FOUR_RED_ONE_MATCH", red == 4 && match == 1)
        println("STAGE10_EXPECTED_RED_4")
        println("STAGE10_MATCH_1")
        insist("E_DISCOVERY05_K0", try { adapter.legacyHiddenDirectByAssumedNearness(storage, 0); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_DISCOVERY05_K8", try { adapter.legacyHiddenDirectByAssumedNearness(storage, 8); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_DISCOVERY05_STORAGE_SHAPE", try {
            adapter.legacyHiddenDirectByAssumedNearness(storage.take(7), 4); false
        } catch (e: IllegalArgumentException) { true })
        println("STAGE10_BAD_ACCESS_GUARDS_PASS")

        val other = manager.observeLegacyHiddenDrop(f - 99L, f + 201L)
        val otherStore = other.discovery05BackwardStorage ?: error("E_DISCOVERY05_OTHER_STORAGE")
        insist("E_DISCOVERY05_CONTEXT_OWNERSHIP", other !== original && otherStore !== storage &&
            otherStore != storage && other.discovery05RequestedK == 1 &&
            original.discovery05BackwardStorage === storage && original.discovery05Actual == storage[1])
        insist("E_DISCOVERY05_COUNTS_INDEPENDENT", manager.metrics.snapshot()["discovery05.builds"] == 2L &&
            original.discovery05HiddenCount == 7 && other.discovery05HiddenCount == 7)
        val snapshot = manager.metrics.snapshot()
        val trace = original.branchTrace.toList()
        val diagnostics = original.diagnostics.toList()
        insist("E_DISCOVERY05_REPLAY", errorCode { manager.dispatcher.dispatch(original) } ==
            "E_DISCOVERY05_CONTEXT_NOT_READY" && manager.metrics.snapshot() == snapshot &&
            original.branchTrace == trace && original.diagnostics == diagnostics &&
            original.discovery05BackwardStorage === storage)
        val noBoot = BaseMonsterContext(f, f, phase = "DISCOVERY_05")
        insist("E_DISCOVERY05_NO_BOOT", errorCode { manager.dispatcher.dispatch(noBoot) } ==
            "E_DISCOVERY05_CONTEXT_NOT_READY" && noBoot.discovery05BackwardStorage == null &&
            manager.metrics.snapshot() == snapshot)
        insist("E_DISCOVERY05_INVALID_K_PREP", try { manager.observeLegacyHiddenDrop(f, f, 0); false }
            catch (e: IllegalArgumentException) { true })
        println("STAGE10_CONTEXT_GUARDS_REPLAY_PASS")

        insist("E_DISCOVERY05_PATCH01", manager.applySavePatch(f, f, NormativeCore.M).patch01Output == NormativeCore.M)
        insist("E_DISCOVERY05_PATCH02", manager.applyDayTagPatch(f, f, f).patch02Output == ExactInt.ONE)
        insist("E_DISCOVERY05_PATCH03", manager.applyDistancePatch(f, f).patch03Output == ExactInt.ONE)
        insist("E_DISCOVERY05_PATCH04", manager.applyStonePatch(f, f).patch04StoneRows?.get(46)?.components() ==
            NormativeCore.STONES[46].toList())
        insist("E_DISCOVERY05_OLD04", manager.observeLegacyStones(f, f)
            .discovery04LegacyStoneRows?.get(2)?.barley != NormativeCore.STONES[2][1])
        println("STAGE10_EARLIER_ROUTES_PASS")
        println("STAGE10_COMPLETE_EXPECTED_RED")
    }
}
