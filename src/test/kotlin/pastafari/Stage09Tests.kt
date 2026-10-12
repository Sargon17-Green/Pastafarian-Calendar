package pastafari

/** Cam 9: cadw'r nam hen ffasiwn, ond cywiro'r cerrig o'r ciplun. */
object Stage09Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun code(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH04_ARGUMENTS" }
        val foundation = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val ctx = manager.applyStonePatch(foundation, foundation)
        val rows = ctx.patch04StoneRows ?: error("E_PATCH04_NO_ROWS")
        val garbage = ctx.patch04LegacyGarbageRows ?: error("E_PATCH04_NO_GARBAGE")
        val oracle = NormativeCore.STONES
        insist("E_PATCH04_COUNTS", rows.size == 47 && garbage.size == 47 &&
            ctx.patch04BuiltRows == 46 && ctx.patch04LegacyCalls == 45)
        insist("E_PATCH04_SENTINEL", rows[0].components() == List(5) { ExactInt.ZERO } &&
            garbage[0].components() == rows[0].components())
        insist("E_PATCH04_INITIAL", rows[1].components() == oracle[1].toList() &&
            garbage[1].components() == oracle[1].toList())
        var correctedRed = 0
        var legacyRed = 0
        var garbageRed = 0
        for (i in 2..46) {
            for (k in 0..4) {
                if (rows[i].components()[k] != oracle[i][k]) correctedRed++
            }
            val preceding = rows[i - 1].copy()
            val oldResult = LegacyStoneBuilder().mutateStonesWrong(preceding, i)
            insist("E_PATCH04_GARBAGE_${i}", garbage[i] == oldResult)
            for (k in 0..4) {
                if (garbage[i].components()[k] != oracle[i][k]) garbageRed++
            }
        }
        val raw = manager.observeLegacyStones(foundation, foundation)
            .discovery04LegacyStoneRows ?: error("E_PATCH04_MISSING_LEGACY")
        for (i in 2..46) for (k in 0..4) {
            if (raw[i].components()[k] != oracle[i][k]) legacyRed++
        }
        insist("E_PATCH04_ALL_CORRECT", correctedRed == 0)
        insist("E_PATCH04_LEGACY_224", legacyRed == 224)
        insist("E_PATCH04_GARBAGE_SAVED", garbageRed > 0 && garbage[2] != rows[2])
        insist("E_PATCH04_CONTEXT", ctx.branchTrace == listOf("BOOT", "PATCH_04") &&
            ctx.diagnostics == listOf("PATCH_04_SNAPSHOT_STONE_SCAR") &&
            ctx.status == "PATCHED_STONES" && ctx.phase == "PATCH_04")
        val counters = manager.metrics.snapshot()
        insist("E_PATCH04_METRICS", counters["patch04.legacy.calls"] == 45L &&
            counters["patch04.applied"] == 1L && counters["discovery04.legacy.builds"] == 1L)
        println("STAGE09_PATCH_GREEN_0")
        println("STAGE09_PRESERVED_DISCOVERY04_RED_224")
        println("STAGE09_GARBAGE_CAPTURE_PASS")
        println("STAGE09_WHOLE_TABLE_GREEN_230")

        val wrapper = StonePatchWrapper()
        val start = MutableStoneRow(ExactInt.of(17), ExactInt.of(29), ExactInt.of(43),
            ExactInt.of(71), ExactInt.of(101))
        val oldCopy = start.copy()
        val wrapped = wrapper.stonePatch(start, 2)
        insist("E_PATCH04_NO_MUTATION_OF_INPUT", start == oldCopy &&
            wrapped.legacyGarbage !== start && wrapped.corrected !== start &&
            wrapped.legacyGarbage != wrapped.corrected && wrapped.corrected.components() == oracle[2].toList())
        insist("E_PATCH04_BAD_INDEX_LOW", try { wrapper.stonePatch(start, 1); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH04_BAD_INDEX_HIGH", try { wrapper.stonePatch(start, 47); false }
            catch (e: IllegalArgumentException) { true })
        insist("E_PATCH04_NO_ALIASES", (0..46).all { i ->
            (0..46).all { j -> i == j || rows[i] !== rows[j] } && rows[i] !== garbage[i]
        })
        println("STAGE09_SNAPSHOT_AND_CALLS_PASS")

        val second = manager.applyStonePatch(foundation - 1L, foundation + 1L)
        val secondRows = second.patch04StoneRows ?: error("E_PATCH04_NO_SECOND_ROWS")
        val secondGarbage = second.patch04LegacyGarbageRows ?: error("E_PATCH04_NO_SECOND_GARBAGE")
        insist("E_PATCH04_CONTEXT_OWNER", second !== ctx && secondRows !== rows &&
            secondGarbage !== garbage && secondRows.zip(rows).all { (a,b) -> a == b && a !== b })
        val originalRow2 = rows[2].copy()
        val originalGarbage2 = garbage[2].copy()
        secondRows[2].wheat = ExactInt.ZERO
        secondGarbage[2].barley = ExactInt.ZERO
        insist("E_PATCH04_CONTEXT_NO_LEAK", rows[2] == originalRow2 && garbage[2] == originalGarbage2)
        val previous = manager.metrics.snapshot()
        val trace = ctx.branchTrace.toList()
        val diagnostics = ctx.diagnostics.toList()
        insist("E_PATCH04_REPLAY_REJECTED", code { manager.dispatcher.dispatch(ctx) } ==
            "E_PATCH04_CONTEXT_NOT_READY" && manager.metrics.snapshot() == previous &&
            ctx.branchTrace == trace && ctx.diagnostics == diagnostics)
        val bypass = BaseMonsterContext(foundation, foundation, phase = "PATCH_04")
        insist("E_PATCH04_BOOT_GUARD", code { manager.dispatcher.dispatch(bypass) } ==
            "E_PATCH04_CONTEXT_NOT_READY" && bypass.patch04StoneRows == null &&
            bypass.patch04LegacyGarbageRows == null && manager.metrics.snapshot() == previous)
        println("STAGE09_OWNERSHIP_GUARDS_REPLAY_PASS")

        // Mae'r tri atgyweiriad a'r pedwerydd darganfyddiad yn dal yn weithredol.
        insist("E_PATCH04_PREVIOUS_01", manager.applySavePatch(foundation, foundation,
            NormativeCore.M).patch01Output == NormativeCore.M)
        insist("E_PATCH04_PREVIOUS_02", manager.applyDayTagPatch(foundation, foundation,
            foundation).patch02Output == ExactInt.ONE)
        insist("E_PATCH04_PREVIOUS_03", manager.applyDistancePatch(foundation,
            foundation).patch03Output == ExactInt.ONE)
        println("STAGE09_EARLIER_ROUTES_PASS")
        println("STAGE09_COMPLETE_GREEN")
    }
}
