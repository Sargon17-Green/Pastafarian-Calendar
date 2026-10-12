package pastafari

/** Cam 17 — PATCH 08: cywiro'r caller heb ddileu graith DISCOVERY 08. */
object Stage17Tests {
    private fun insist(code: String, value: Boolean) { check(value) { code } }
    private fun machineCode(action: () -> Unit): String = try {
        action(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH08_ARGS" }
        val rawAdapter = LegacyPermutationOrderAdapter()
        val patch = PermutationPatchWrapper(rawAdapter)
        val distinct = linkedSetOf<List<Int>>()
        var green = 0
        var legacyRed = 0
        var legacyNumeric = 0
        var legacyUndefined = 0
        for (ordinal in 1..720) {
            val d = ExactInt.of(ordinal.toLong())
            val result = patch.patch(d)
            val normative = NormativeCore.bowlOrderFromDrop(d).toList()
            insist("E_PATCH08_ORDINAL_$ordinal",
                result.dropValue == d && result.oneBased == ordinal &&
                result.correctedRank0 == ordinal - 1 &&
                result.correctedUnrankCalls == 1 &&
                result.legacyRead.legacyCalls == 1 &&
                result.legacyRead.passedRank0 == ordinal)
            insist("E_PATCH08_CORRECT_$ordinal",
                result.correctedOrder == normative &&
                result.correctedOrder ==
                    rawAdapter.oldPermutationUnrank0(ordinal - 1) &&
                result.correctedOrder.sorted() == listOf(1,2,3,4,5,6))
            val old = result.legacyRead
            if (ordinal == 720) {
                insist("E_PATCH08_UNDEFINED_720",
                    old.undefined && old.legacyOrder == null &&
                    old.errorId == "E_DISCOVERY08_RANK0_RANGE" &&
                    result.correctedOrder == listOf(6,5,4,3,2,1))
                legacyUndefined++
            } else {
                insist("E_PATCH08_PRESERVED_RED_$ordinal",
                    !old.undefined && old.errorId == null &&
                    old.legacyOrder == rawAdapter.oldPermutationUnrank0(ordinal) &&
                    old.legacyOrder != result.correctedOrder)
                legacyNumeric++
            }
            distinct.add(result.correctedOrder)
            green++
            legacyRed++
        }
        insist("E_PATCH08_ALL_ORDINALS",
            green == 720 && distinct.size == 720 &&
            legacyRed == 720 && legacyNumeric == 719 && legacyUndefined == 1)
        println("STAGE17_PATCHED_GREEN_720")
        println("STAGE17_UNIQUE_PERMUTATIONS_720")
        println("STAGE17_PRESERVED_LEGACY_RED_720")
        println("STAGE17_LEGACY_NUMERIC_RED_719")
        println("STAGE17_LEGACY_UNDEFINED_1")

        val first = patch.patch(ExactInt.ONE)
        val last = patch.patch(ExactInt.of(720L))
        insist("E_PATCH08_BOUNDARIES",
            first.correctedRank0 == 0 &&
            first.correctedOrder == listOf(1,2,3,4,5,6) &&
            first.legacyRead.legacyOrder == listOf(1,2,3,4,6,5) &&
            last.correctedRank0 == 719 &&
            last.correctedOrder == listOf(6,5,4,3,2,1) &&
            last.legacyRead.undefined)
        for (seed in listOf(
            ExactInt.ZERO, ExactInt.of(-719L), ExactInt.of(721L),
            ExactInt.parse("12345678901234567890123456789012345678901234567890")
        )) {
            val expected = NormativeCore.bowlOrderFromDrop(seed).toList()
            val result = patch.patch(seed)
            insist("E_PATCH08_MODULAR_BOUNDARY", result.correctedOrder == expected)
            insist("E_PATCH08_PERIODICITY_PLUS",
                patch.patch(seed + 720L).correctedOrder == expected)
            insist("E_PATCH08_PERIODICITY_MINUS",
                patch.patch(seed - 720L).correctedOrder == expected)
        }
        println("STAGE17_BOUNDARY_AND_PERIODICITY_PASS")

        val f = NormativeCore.FOUNDATION_DAY
        val manager = MonsterBootstrapManager()
        val a = manager.applyPermutationPatch(f,f)
        val aOrder = a.patch08CorrectedOrder ?: error("E_PATCH08_NO_ORDER")
        insist("E_PATCH08_PRODUCTION_FIRST",
            a.phase == "PATCH_08" && a.status == "PATCHED_PERMUTATION" &&
            a.branchTrace == listOf("BOOT","PATCH_08") &&
            a.diagnostics == listOf("PATCH_08_ONE_BASED_TO_ZERO_BASED") &&
            a.patch08DropValue == ExactInt.ONE &&
            a.patch08OneBased == 1 && a.patch08LegacyPassedRank0 == 1 &&
            a.patch08CorrectedRank0 == 0 &&
            a.patch08LegacyOrder == listOf(1,2,3,4,6,5) &&
            aOrder == listOf(1,2,3,4,5,6) &&
            a.patch08LegacyUndefined == false && a.patch08LegacyErrorId == null &&
            a.patch08LegacyCalls == 1 && a.patch08CorrectedCalls == 1 &&
            a.patch08Applied && a.patch08InvocationCount == 1)
        val b = manager.applyPermutationPatch(f,f,ExactInt.of(720L))
        insist("E_PATCH08_PRODUCTION_LAST",
            b.patch08OneBased == 720 && b.patch08CorrectedRank0 == 719 &&
            b.patch08LegacyPassedRank0 == 720 &&
            b.patch08LegacyOrder == null && b.patch08LegacyUndefined == true &&
            b.patch08LegacyErrorId == "E_DISCOVERY08_RANK0_RANGE" &&
            b.patch08CorrectedOrder == listOf(6,5,4,3,2,1) &&
            b.patch08Applied && b.patch08InvocationCount == 1)
        insist("E_PATCH08_METRICS",
            manager.metrics.snapshot()["patch08.applied"] == 2L &&
            manager.metrics.snapshot()["patch08.legacy.wrong.calls"] == 2L &&
            manager.metrics.snapshot()["patch08.corrected.unrank.calls"] == 2L)
        println("STAGE17_PRODUCTION_FIRST_AND_LAST_GREEN")
        println("STAGE17_REAL_LEGACY_CALL_PRESERVED")

        val savedMetrics = manager.metrics.snapshot()
        val savedTrace = a.branchTrace.toList()
        val savedDiagnostics = a.diagnostics.toList()
        insist("E_PATCH08_REPLAY",
            machineCode { manager.dispatcher.dispatch(a) } ==
                "E_PATCH08_CONTEXT_NOT_READY" &&
            a.patch08CorrectedOrder === aOrder &&
            a.patch08InvocationCount == 1 &&
            a.branchTrace == savedTrace && a.diagnostics == savedDiagnostics &&
            manager.metrics.snapshot() == savedMetrics)
        val unbootstrapped = BaseMonsterContext(f,f,phase="PATCH_08",
            patch08DropValue=ExactInt.ONE)
        insist("E_PATCH08_NO_BOOT",
            machineCode { manager.dispatcher.dispatch(unbootstrapped) } ==
                "E_PATCH08_CONTEXT_NOT_READY" &&
            unbootstrapped.patch08CorrectedOrder == null &&
            unbootstrapped.patch08LegacyOrder == null &&
            !unbootstrapped.patch08Applied &&
            unbootstrapped.patch08InvocationCount == 0 &&
            manager.metrics.snapshot() == savedMetrics)
        val noDrop = BaseMonsterContext(f,f,phase="PATCH_08",status="READY")
        insist("E_PATCH08_MISSING_INPUT",
            machineCode { manager.dispatcher.dispatch(noDrop) } ==
                "E_PATCH08_NO_DROP" &&
            noDrop.patch08CorrectedOrder == null &&
            !noDrop.patch08Applied && noDrop.patch08InvocationCount == 0 &&
            manager.metrics.snapshot() == savedMetrics)
        val other = manager.applyPermutationPatch(f-99L,f+201L,ExactInt.of(-719L))
        insist("E_PATCH08_OWNERSHIP",
            other !== a && other.patch08CorrectedOrder !== aOrder &&
            other.patch08CorrectedOrder == listOf(1,2,3,4,5,6) &&
            other.patch08LegacyOrder == listOf(1,2,3,4,6,5) &&
            a.patch08CorrectedOrder == listOf(1,2,3,4,5,6))
        println("STAGE17_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE17_CONTEXT_OWNERSHIP_PASS")

        // Gwirio'r hen nam a holl lwybrau blaenorol (heb newidiadau).
        val discovery = manager.observeLegacyPermutation(f,f,ExactInt.of(720L))
        insist("E_PATCH08_DISCOVERY08_PRESERVED",
            discovery.discovery08Undefined == true &&
            discovery.discovery08LegacyOrder == null &&
            discovery.discovery08ErrorId == "E_DISCOVERY08_RANK0_RANGE")
        val oldGrind = manager.observeLegacyGrind(f,f,11)
        val fixedGrind = manager.applyGrindPatch(f,f,11)
        insist("E_PATCH08_DISCOVERY07_PRESERVED",
            oldGrind.discovery07Undefined == true &&
            oldGrind.discovery07LegacyRow == null)
        insist("E_PATCH08_PATCH07_PRESERVED",
            fixedGrind.patch07CorrectedRow == VisibleGrindRow(37,41,43,47,0) &&
            fixedGrind.patch07LegacyUndefined == true)
        val hidden = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f,f))
        insist("E_PATCH08_PATCH06_PRESERVED",
            manager.applyPriorPatch(f,f,1,7).patch06Output == hidden[7])
        println("STAGE17_EARLIER_ROUTES_PASS")
        println("STAGE17_NATIVE_GREEN")
    }
}
