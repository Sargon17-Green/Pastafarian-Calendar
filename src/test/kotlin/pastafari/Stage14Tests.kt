package pastafari

/** Cam 14: unarddeg ordinal wedi symud un slot, heb unrhyw gywiriad. */
object Stage14Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machineCode(f: () -> Unit): String = try {
        f(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    // Oracl tabl annibynnol ar y dosbarth cynhyrchu.
    private val expected = listOf(
        VisibleGrindRow(3,5,7,11,0), VisibleGrindRow(5,7,11,13,1),
        VisibleGrindRow(7,11,13,17,2), VisibleGrindRow(11,13,17,19,3),
        VisibleGrindRow(13,17,19,23,4), VisibleGrindRow(17,19,23,29,0),
        VisibleGrindRow(19,23,29,31,1), VisibleGrindRow(23,29,31,37,2),
        VisibleGrindRow(29,31,37,41,3), VisibleGrindRow(31,37,41,43,4),
        VisibleGrindRow(37,41,43,47,0)
    )

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY07_ARGUMENTS" }
        val adapter = LegacyGrindTableAdapter()
        val physical = adapter.physicalRows()
        insist("E_DISCOVERY07_NO_SENTINEL", physical.size == 11 &&
            physical[0] == expected[0] && physical[10] == expected[10])
        insist("E_DISCOVERY07_ALL_PHYSICAL_ROWS", physical == expected)
        println("STAGE14_PHYSICAL_ROWS_GREEN_11")
        println("STAGE14_SENTINEL_ABSENT_PASS")

        var red = 0
        var match = 0
        for (grind in 1..11) {
            val wrong = adapter.legacyGrindRow(grind)
            val normative = expected[grind - 1]
            insist("E_DISCOVERY07_RAW_INDEX_${grind}", wrong.requestedGrind == grind &&
                wrong.directIndex == grind && wrong.undefined == (grind == 11))
            if (wrong.row == normative) match++ else red++
            if (grind <= 10) {
                insist("E_DISCOVERY07_SHIFTED_${grind}",
                    wrong.row == expected[grind] && wrong.row != normative)
            } else insist("E_DISCOVERY07_UNDEFINED_11", wrong.row == null)
            println("STAGE14_GRIND${grind}_EXPECTED_RED")
        }
        insist("E_DISCOVERY07_ALL_RED", red == 11 && match == 0)
        println("STAGE14_EXPECTED_RED_11")
        println("STAGE14_MATCH_0")
        println("STAGE14_GRIND1_IS_ROW2_PASS")
        println("STAGE14_GRIND10_IS_ROW11_PASS")
        println("STAGE14_GRIND11_UNDEFINED_PASS")

        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val context = manager.observeLegacyGrind(f, f)
        val stored = context.discovery07PhysicalRows ?: error("E_DISCOVERY07_NO_ROWS")
        insist("E_DISCOVERY07_PRODUCTION_G1", context.phase == "DISCOVERY_07" &&
            context.status == "LEGACY_GRIND_OBSERVED" &&
            context.branchTrace == listOf("BOOT", "DISCOVERY_07") &&
            context.diagnostics == listOf("DISCOVERY_07_ZERO_BASED_ORDINAL_INDEX") &&
            context.discovery07RequestedGrind == 1 && context.discovery07DirectIndex == 1 &&
            context.discovery07LegacyRow == expected[1] &&
            context.discovery07Undefined == false &&
            context.discovery07InvocationCount == 1 &&
            stored == expected)
        val last = manager.observeLegacyGrind(f, f, 11)
        insist("E_DISCOVERY07_PRODUCTION_G11", last.discovery07RequestedGrind == 11 &&
            last.discovery07DirectIndex == 11 && last.discovery07LegacyRow == null &&
            last.discovery07Undefined == true && last.discovery07InvocationCount == 1 &&
            last.discovery07PhysicalRows == expected)
        insist("E_DISCOVERY07_COUNTER", manager.metrics.snapshot()["discovery07.legacy.grind.calls"] == 2L)
        println("STAGE14_PRODUCTION_PROBE_G1_PASS")
        println("STAGE14_PRODUCTION_UNDEFINED_G11_PASS")
        println("STAGE14_PRODUCTION_REAL_ADAPTER_PASS")

        insist("E_DISCOVERY07_RANGE_ZERO", try { adapter.legacyGrindRow(0);false }
            catch (e: IllegalArgumentException) { true })
        insist("E_DISCOVERY07_RANGE_TWELVE", try { adapter.legacyGrindRow(12);false }
            catch (e: IllegalArgumentException) { true })
        insist("E_DISCOVERY07_PREP_RANGE", try { manager.observeLegacyGrind(f, f, 0);false }
            catch (e: IllegalArgumentException) { true })
        val snapshot = manager.metrics.snapshot()
        val trace = context.branchTrace.toList()
        val diag = context.diagnostics.toList()
        insist("E_DISCOVERY07_REPLAY", machineCode { manager.dispatcher.dispatch(context) } ==
            "E_DISCOVERY07_CONTEXT_NOT_READY" && context.discovery07InvocationCount == 1 &&
            context.discovery07LegacyRow == expected[1] && context.discovery07PhysicalRows === stored &&
            context.branchTrace == trace && context.diagnostics == diag &&
            manager.metrics.snapshot() == snapshot)
        val unbootstrapped = BaseMonsterContext(f, f, phase="DISCOVERY_07",
            discovery07RequestedGrind = 1)
        insist("E_DISCOVERY07_BOOT", machineCode { manager.dispatcher.dispatch(unbootstrapped) } ==
            "E_DISCOVERY07_CONTEXT_NOT_READY" &&
            unbootstrapped.discovery07LegacyRow == null &&
            unbootstrapped.discovery07PhysicalRows == null &&
            unbootstrapped.discovery07InvocationCount == 0 &&
            manager.metrics.snapshot() == snapshot)
        val different = manager.observeLegacyGrind(f - 99L, f + 201L, 10)
        insist("E_DISCOVERY07_OWNERSHIP", different !== context &&
            different.discovery07PhysicalRows !== stored &&
            different.discovery07LegacyRow == expected[10] &&
            context.discovery07LegacyRow == expected[1])
        println("STAGE14_GUARDS_REPLAY_PASS")
        println("STAGE14_CONTEXT_OWNERSHIP_PASS")

        val oracle = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f,f))
        insist("E_DISCOVERY07_PRESERVE_PATCH01", manager.applySavePatch(f,f,NormativeCore.M)
            .patch01Output == NormativeCore.M)
        insist("E_DISCOVERY07_PRESERVE_PATCH02", manager.applyDayTagPatch(f,f,f)
            .patch02Output == ExactInt.ONE)
        insist("E_DISCOVERY07_PRESERVE_PATCH03", manager.applyDistancePatch(f,f)
            .patch03Output == ExactInt.ONE)
        insist("E_DISCOVERY07_PRESERVE_PATCH04", manager.applyStonePatch(f,f)
            .patch04StoneRows?.get(46)?.components() == NormativeCore.STONES[46].toList())
        insist("E_DISCOVERY07_PRESERVE_PATCH05", manager.applyHiddenNearnessPatch(f,f,7)
            .patch05CorrectedValue == oracle[7])
        insist("E_DISCOVERY07_PRESERVE_PATCH06", manager.applyPriorPatch(f,f,1,7)
            .patch06Output == oracle[7])
        insist("E_DISCOVERY07_PRESERVE_DISCOVERY06", manager.observeLegacyPrior(f,f,1,1)
            .discovery06PriorValue == null)
        println("STAGE14_EARLIER_ROUTES_PASS")
        println("STAGE14_COMPLETE_EXPECTED_RED")
    }
}
