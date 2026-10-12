package pastafari

/** Cam 15: ni ddylid dileu graith DISCOVERY 07. */
object Stage15Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machineCode(f: () -> Unit): String = try {
        f(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }
    private val expected = listOf(
        VisibleGrindRow(3,5,7,11,0), VisibleGrindRow(5,7,11,13,1),
        VisibleGrindRow(7,11,13,17,2), VisibleGrindRow(11,13,17,19,3),
        VisibleGrindRow(13,17,19,23,4), VisibleGrindRow(17,19,23,29,0),
        VisibleGrindRow(19,23,29,31,1), VisibleGrindRow(23,29,31,37,2),
        VisibleGrindRow(29,31,37,41,3), VisibleGrindRow(31,37,41,43,4),
        VisibleGrindRow(37,41,43,47,0)
    )
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH07_ARGS" }
        val adapter = LegacyGrindTableAdapter()
        val wrapper = GrindPatchWrapper(adapter)
        var legacyRed = 0
        for (k in 1..11) {
            val result = wrapper.patch(k)
            insist("E_PATCH07_SENTINEL_$k", result.sentinelRows.size == 12 &&
                result.sentinelRows[0] == null &&
                result.sentinelRows.subList(1,12) == expected)
            insist("E_PATCH07_GREEN_$k", result.correctedRow == expected[k-1] &&
                result.translatedIndex == k &&
                result.physicalRows == expected &&
                result.requestedGrind == k &&
                result.legacyRead.requestedGrind == k &&
                result.legacyRead.directIndex == k)
            val old = result.legacyRead
            insist("E_PATCH07_SCAR_$k", old.row != result.correctedRow &&
                old.row == expected.getOrNull(k) &&
                old.undefined == (k == 11))
            legacyRed++
            println("STAGE15_GRIND${k}_GREEN")
        }
        insist("E_PATCH07_ALL_GREEN", legacyRed == 11)
        println("STAGE15_TRANSLATED_ROWS_GREEN_11")
        println("STAGE15_LEGACY_SCAR_RED_11")
        println("STAGE15_SENTINEL_SLOT_ZERO_PASS")
        println("STAGE15_GRIND11_UNDEFINED_RECOVERED_PASS")
        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val a = manager.applyGrindPatch(f,f)
        val aRows = a.patch07SentinelRows ?: error("E_PATCH07_NO_SENTINEL")
        insist("E_PATCH07_PRODUCTION", a.phase == "PATCH_07" &&
            a.status == "PATCHED_GRIND" &&
            a.branchTrace == listOf("BOOT","PATCH_07") &&
            a.diagnostics == listOf("PATCH_07_SENTINEL_TRANSLATOR") &&
            a.patch07RequestedGrind == 1 &&
            a.patch07LegacyDirectIndex == 1 &&
            a.patch07LegacyRow == expected[1] &&
            a.patch07LegacyUndefined == false &&
            a.patch07CorrectedRow == expected[0] &&
            a.patch07TranslatedIndex == 1 &&
            a.patch07Applied && a.patch07InvocationCount == 1 &&
            aRows.size == 12 && aRows[0] == null &&
            aRows[11] == expected[10])
        val b = manager.applyGrindPatch(f,f,11)
        insist("E_PATCH07_PRODUCTION_11", b.patch07RequestedGrind == 11 &&
            b.patch07LegacyRow == null && b.patch07LegacyUndefined == true &&
            b.patch07CorrectedRow == expected[10] &&
            b.patch07SentinelRows?.get(11) == expected[10] &&
            b.patch07Applied && b.patch07InvocationCount == 1)
        insist("E_PATCH07_METRICS", manager.metrics.snapshot()["patch07.applied"] == 2L &&
            manager.metrics.snapshot()["patch07.legacy.grind.calls"] == 2L)
        println("STAGE15_PRODUCTION_ROUTE_PASS")
        println("STAGE15_PRODUCTION_LAST_ROW_PASS")
        println("STAGE15_REAL_LEGACY_CALLED_PASS")
        val beforeMetrics = manager.metrics.snapshot()
        val beforeTrace = a.branchTrace.toList()
        val beforeDiag = a.diagnostics.toList()
        insist("E_PATCH07_REPLAY", machineCode { manager.dispatcher.dispatch(a) } ==
            "E_PATCH07_CONTEXT_NOT_READY" &&
            a.patch07SentinelRows === aRows &&
            a.patch07InvocationCount == 1 &&
            a.branchTrace == beforeTrace &&
            a.diagnostics == beforeDiag &&
            manager.metrics.snapshot() == beforeMetrics)
        val unbooted = BaseMonsterContext(f,f,phase="PATCH_07",
            patch07RequestedGrind=1)
        insist("E_PATCH07_UNBOOTED", machineCode { manager.dispatcher.dispatch(unbooted) } ==
            "E_PATCH07_CONTEXT_NOT_READY" &&
            unbooted.patch07SentinelRows == null &&
            unbooted.patch07CorrectedRow == null &&
            !unbooted.patch07Applied && unbooted.patch07InvocationCount == 0 &&
            manager.metrics.snapshot() == beforeMetrics)
        for (invalid in listOf(0,12,-1)) {
            insist("E_PATCH07_INVALID_$invalid", try {
                manager.applyGrindPatch(f,f,invalid); false
            } catch (e: IllegalArgumentException) { true })
            insist("E_PATCH07_WRAPPER_INVALID_$invalid", try {
                wrapper.patch(invalid); false
            } catch (e: IllegalArgumentException) { true })
        }
        insist("E_PATCH07_PREP_FAIL_NO_MUTATION", manager.metrics.snapshot() == beforeMetrics)
        val different = manager.applyGrindPatch(f-99L,f+201L,7)
        insist("E_PATCH07_CONTEXT_ISOLATION", different !== a &&
            different.patch07SentinelRows !== aRows &&
            different.patch07CorrectedRow == expected[6] &&
            a.patch07CorrectedRow == expected[0])
        println("STAGE15_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE15_CONTEXT_OWNERSHIP_PASS")
        val old1 = adapter.legacyGrindRow(1)
        val old11 = adapter.legacyGrindRow(11)
        insist("E_PATCH07_PRESERVE_OLD", old1.row == expected[1] &&
            old11.row == null && old11.undefined)
        val oldRoute = manager.observeLegacyGrind(f,f,11)
        insist("E_PATCH07_PRESERVE_DISCOVERY_07",
            oldRoute.discovery07LegacyRow == null &&
            oldRoute.discovery07Undefined == true)
        val hidden = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f,f))
        insist("E_PATCH07_PRESERVE_PATCH06", manager.applyPriorPatch(f,f,1,7)
            .patch06Output == hidden[7])
        insist("E_PATCH07_PRESERVE_PATCH05", manager.applyHiddenNearnessPatch(f,f,7)
            .patch05CorrectedValue == hidden[7])
        insist("E_PATCH07_PRESERVE_PATCH04", manager.applyStonePatch(f,f)
            .patch04StoneRows?.get(46)?.components() == NormativeCore.STONES[46].toList())
        println("STAGE15_EARLIER_ROUTES_PASS")
        println("STAGE15_NATIVE_GREEN")
    }
}
