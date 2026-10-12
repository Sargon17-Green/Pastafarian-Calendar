package pastafari

/** Cam 19 — PATCH 09: y graith yn fyw, y ffynonellau yn ôl safle. */
object Stage19Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machineCode(run: () -> Unit): String = try {
        run(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH09_ARGS" }
        val adapter = LegacyFixedPourAdapter()
        val wrapper = PourPatchWrapper(adapter)
        val z = ExactInt.ZERO
        val one = ExactInt.ONE
        val seed = listOf(z, ExactInt.of(100), ExactInt.of(200),
            ExactInt.of(300), ExactInt.of(400), ExactInt.of(500), ExactInt.of(600))
        val stoneRows = StonePatchWrapper().buildPatchedRows().rows
        insist("E_PATCH09_STONES",
            stoneRows.size == 47 &&
            (1..46).all { stoneRows[it].components() ==
                NormativeCore.STONES[it].toList() })
        var corrected = 0
        var legacyRed = 0
        var legacyMatches = 0
        var wrongCells = 0
        for (ordinal in 1..720) {
            val drop = ExactInt.of(ordinal.toLong())
            val result = wrapper.patch(drop,1,seed,stoneRows[1])
            val order = NormativeCore.bowlOrderFromDrop(drop).toList()
            insist("E_PATCH09_ORDER_$ordinal",
                result.drop == drop && result.iteration == 1 &&
                result.order == order &&
                result.sourceIdsByPosition == order.take(3) &&
                result.legacyRead.sourceIdsWrong == listOf(1,2,3) &&
                result.legacyRead.sourceIdsByPosition == order.take(3) &&
                result.legacyRead.fixedPourCalls == 1 &&
                result.legacyRead.patch08Calls == 1 &&
                result.correctedPourCalls == 1 &&
                result.correctedPours.size == 7 &&
                result.correctedPours[0] == z &&
                result.correctedPours.subList(4,7).all { it == z })
            var isLegacyWrong = false
            for (p in 1..3) {
                val coef = stoneRows[1].components()[p-1]
                val oldId = order[p-1]
                val correct = NormativeCore.save(
                    drop.square() + coef * seed[oldId] +
                        ExactInt.of((2L*p+1)))
                val wrong = NormativeCore.save(
                    drop.square() + coef * seed[p] +
                        ExactInt.of((2L*p+1)))
                insist("E_PATCH09_CORRECT_$ordinal-$p",
                    result.correctedPours[p] == correct &&
                    result.legacyRead.pours[p] == wrong)
                if (correct != wrong) {
                    isLegacyWrong = true
                    wrongCells++
                }
            }
            if (isLegacyWrong) legacyRed++ else legacyMatches++
            corrected++
        }
        insist("E_PATCH09_COUNTS",
            corrected == 720 && legacyRed == 714 &&
            legacyMatches == 6 && wrongCells == 1800)
        println("STAGE19_SINGLE_CORRECTED_GREEN_720")
        println("STAGE19_SINGLE_LEGACY_RED_714")
        println("STAGE19_SINGLE_INCIDENTAL_MATCH_6")
        println("STAGE19_SINGLE_LEGACY_WRONG_CELLS_1800")

        val reversed = wrapper.patch(ExactInt.of(720L),1,seed,stoneRows[1])
        insist("E_PATCH09_REVERSE",
            reversed.order == listOf(6,5,4,3,2,1) &&
            reversed.sourceIdsByPosition == listOf(6,5,4) &&
            reversed.legacyRead.sourceIdsWrong == listOf(1,2,3) &&
            reversed.correctedPours[1] != reversed.legacyRead.pours[1])
        for (bad in listOf(0,47)) {
            insist("E_PATCH09_RANGE_$bad", try {
                wrapper.patch(one,bad,seed,stoneRows[1]); false
            } catch (e: IllegalArgumentException) {
                e.message == "E_PATCH09_ITERATION_RANGE"
            })
        }
        insist("E_PATCH09_INVALID_BOWLS", try {
            wrapper.patch(one,1,seed.drop(1),stoneRows[1]); false
        } catch (e: IllegalArgumentException) {
            e.message == "E_PATCH09_BOWL_SHAPE"
        })
        println("STAGE19_REVERSED_SOURCE_CORRECTION_PASS")
        println("STAGE19_INPUT_GUARDS_PASS")

        val reverseDrops = listOf(z) + List(46) { ExactInt.of(720L) }
        val identityDrops = listOf(z) + List(46) { one }
        val reverseRun = wrapper.runPatchedPours(seed,reverseDrops,stoneRows)
        val identityRun = wrapper.runPatchedPours(seed,identityDrops,stoneRows)
        val reversedLegacy = adapter.runWrongPours(seed,reverseDrops,stoneRows)
        val identityLegacy = adapter.runWrongPours(seed,identityDrops,stoneRows)
        val (reverseExpected,reverseOrder) = NormativeCore.applyVisibleDropsToBowls(
            seed.toTypedArray(),reverseDrops.toTypedArray())
        val (identityExpected,identityOrder) = NormativeCore.applyVisibleDropsToBowls(
            seed.toTypedArray(),identityDrops.toTypedArray())
        insist("E_PATCH09_REVERSED_RUN",
            reverseRun.steps.size == 46 &&
            reverseRun.finalBowls == reverseExpected.toList() &&
            reverseRun.orderAt46 == reverseOrder.toList() &&
            reverseRun.finalBowls != reversedLegacy.finalBowls &&
            reverseRun.legacyFixedPourCalls == 46 &&
            reverseRun.correctedPourCalls == 46 &&
            reverseRun.permutationPatchCalls == 46 &&
            reverseRun.steps.all {
                it.pourPatch.sourceIdsByPosition == listOf(6,5,4) &&
                it.pourPatch.legacyRead.sourceIdsWrong == listOf(1,2,3) &&
                it.pourPatch.correctedPours != it.pourPatch.legacyRead.pours
            })
        insist("E_PATCH09_IDENTITY_RUN",
            identityRun.finalBowls == identityExpected.toList() &&
            identityRun.finalBowls == identityLegacy.finalBowls &&
            identityRun.orderAt46 == identityOrder.toList() &&
            identityRun.steps.all {
                it.pourPatch.sourceIdsByPosition == listOf(1,2,3) &&
                it.pourPatch.correctedPours == it.pourPatch.legacyRead.pours
            })
        insist("E_PATCH09_SNAPSHOTS",
            reverseRun.steps[0].oldBowls == seed &&
            reverseRun.steps[1].oldBowls == reverseRun.steps[0].newBowls &&
            reverseRun.steps[45].newBowls == reverseRun.finalBowls &&
            reverseRun.steps.map { it.iteration } == (1..46).toList())
        println("STAGE19_46_REVERSED_GREEN_AND_LEGACY_RED")
        println("STAGE19_46_IDENTITY_BOTH_GREEN")
        println("STAGE19_46_SNAPSHOT_OWNERSHIP_PASS")

        // Dim adeiladwr diferion gweledig cynhyrchu yng Ngham 19.
        // Caiff y profion ddarparu 46 diferion o'r oracl ar wahân.
        val foundation = NormativeCore.FOUNDATION_DAY
        val counts = NormativeCore.workCounts(foundation,foundation)
        val hidden = NormativeCore.buildHiddenDrops(counts)
        val naturalDrops = NormativeCore.buildVisibleDrops(
            counts,NormativeCore.STONES,hidden)
        val naturalBowls = NormativeCore.initialBowls(counts)
        val naturalPatched = wrapper.runPatchedPours(
            naturalBowls.toList(),naturalDrops.toList(),stoneRows)
        val naturalLegacy = adapter.runWrongPours(
            naturalBowls.toList(),naturalDrops.toList(),stoneRows)
        val (naturalNormative,naturalOrder) =
            NormativeCore.applyVisibleDropsToBowls(naturalBowls,naturalDrops)
        insist("E_PATCH09_NATURAL_ORACLE",
            naturalPatched.steps.size == 46 &&
            naturalPatched.finalBowls == naturalNormative.toList() &&
            naturalPatched.orderAt46 == naturalOrder.toList() &&
            naturalPatched.finalBowls != naturalLegacy.finalBowls)
        println("STAGE19_NATURAL_46_ORACLE_GREEN")
        println("STAGE19_NATURAL_46_LEGACY_RED")

        val manager = MonsterBootstrapManager()
        val context = manager.applyPourPatch(
            foundation,foundation,seed,reverseDrops)
        val steps = context.patch09Steps ?: error("E_PATCH09_PRODUCTION_STEPS")
        insist("E_PATCH09_PRODUCTION",
            context.phase == "PATCH_09" &&
            context.status == "PATCHED_POURS" &&
            context.branchTrace == listOf("BOOT","PATCH_09") &&
            context.diagnostics == listOf("PATCH_09_ORDER_POSITION_SOURCE_IDS") &&
            context.patch09InitialBowls == seed &&
            context.patch09VisibleDrops == reverseDrops &&
            context.patch09FinalBowls == reverseExpected.toList() &&
            context.patch09OrderAt46 == reverseOrder.toList() &&
            context.patch09LegacyFixedPourCalls == 46 &&
            context.patch09CorrectedPourCalls == 46 &&
            context.patch09PermutationPatchCalls == 46 &&
            context.patch09Applied && context.patch09InvocationCount == 1 &&
            steps.size == 46 &&
            steps[0].pourPatch.legacyRead.sourceIdsWrong == listOf(1,2,3) &&
            steps[0].pourPatch.sourceIdsByPosition == listOf(6,5,4))
        val afterFirst = manager.metrics.snapshot()
        insist("E_PATCH09_METRICS",
            afterFirst["patch09.legacy.fixed.pour.calls"] == 1L &&
            afterFirst["patch09.corrected.pour.calls"] == 1L &&
            afterFirst["patch09.applied"] == 1L)
        println("STAGE19_PRODUCTION_46_GREEN")

        val savedTrace = context.branchTrace.toList()
        val savedDiag = context.diagnostics.toList()
        insist("E_PATCH09_REPLAY",
            machineCode { manager.dispatcher.dispatch(context) } ==
                "E_PATCH09_CONTEXT_NOT_READY" &&
            context.patch09Steps === steps &&
            context.patch09InvocationCount == 1 &&
            context.branchTrace == savedTrace &&
            context.diagnostics == savedDiag &&
            manager.metrics.snapshot() == afterFirst)
        val unbooted = BaseMonsterContext(foundation,foundation,
            phase="PATCH_09",patch09InitialBowls=seed,
            patch09VisibleDrops=reverseDrops)
        insist("E_PATCH09_NOT_READY",
            machineCode { manager.dispatcher.dispatch(unbooted) } ==
                "E_PATCH09_CONTEXT_NOT_READY" &&
            unbooted.patch09Steps == null && !unbooted.patch09Applied &&
            unbooted.patch09InvocationCount == 0 &&
            manager.metrics.snapshot() == afterFirst)
        val noInitial = BaseMonsterContext(foundation,foundation,
            phase="PATCH_09",status="READY",patch09VisibleDrops=reverseDrops)
        insist("E_PATCH09_NO_INITIAL",
            machineCode { manager.dispatcher.dispatch(noInitial) } ==
                "E_PATCH09_NO_INITIAL" &&
            noInitial.patch09Steps == null && !noInitial.patch09Applied &&
            manager.metrics.snapshot() == afterFirst)
        val noVisible = BaseMonsterContext(foundation,foundation,
            phase="PATCH_09",status="READY",patch09InitialBowls=seed)
        insist("E_PATCH09_NO_VISIBLE",
            machineCode { manager.dispatcher.dispatch(noVisible) } ==
                "E_PATCH09_NO_VISIBLE" &&
            noVisible.patch09Steps == null && !noVisible.patch09Applied &&
            manager.metrics.snapshot() == afterFirst)
        val others = manager.applyPourPatch(
            foundation-11L,foundation+71L,seed,identityDrops)
        insist("E_PATCH09_CONTEXT_ISOLATION",
            others !== context && others.patch09Steps !== steps &&
            others.patch09FinalBowls == identityExpected.toList() &&
            steps[0].pourPatch.sourceIdsByPosition == listOf(6,5,4) &&
            others.patch09Steps?.get(0)?.pourPatch?.sourceIdsByPosition ==
                listOf(1,2,3))
        println("STAGE19_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE19_CONTEXT_OWNERSHIP_PASS")

        val oldContext = manager.observeLegacyFixedPours(
            foundation,foundation,seed,reverseDrops)
        insist("E_PATCH09_DISCOVERY09_PRESERVED",
            oldContext.discovery09FinalBowls == reversedLegacy.finalBowls &&
            oldContext.discovery09FinalBowls != context.patch09FinalBowls &&
            oldContext.discovery09Steps?.get(0)?.fixedPour?.sourceIdsWrong ==
                listOf(1,2,3))
        val permutation = manager.applyPermutationPatch(
            foundation,foundation,ExactInt.of(720L))
        insist("E_PATCH09_PATCH08_PRESERVED",
            permutation.patch08CorrectedOrder == listOf(6,5,4,3,2,1) &&
            permutation.patch08LegacyUndefined == true)
        val grind = manager.applyGrindPatch(foundation,foundation,11)
        insist("E_PATCH09_PATCH07_PRESERVED",
            grind.patch07CorrectedRow == VisibleGrindRow(37,41,43,47,0))
        println("STAGE19_EARLIER_ROUTES_PASS")
        println("STAGE19_NATIVE_GREEN")
    }
}
