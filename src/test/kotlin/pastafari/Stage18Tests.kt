package pastafari

/** Cam 18: tystiolaeth o nam ffynhonnell arllwys 1..3 sefydlog. */
object Stage18Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machineCode(action: () -> Unit): String = try {
        action(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY09_ARGS" }
        val adapter = LegacyFixedPourAdapter()
        val zero = ExactInt.ZERO
        val one = ExactInt.ONE
        val stones = StonePatchWrapper().buildPatchedRows().rows
        insist("E_DISCOVERY09_STONES_47", stones.size == 47)
        for (i in 1..46) {
            insist("E_DISCOVERY09_PATCH04_STONES_$i",
                stones[i].components() == NormativeCore.STONES[i].toList())
        }
        println("STAGE18_PATCH04_STONES_GREEN_46")
        val old = listOf(zero, ExactInt.of(100), ExactInt.of(200),
            ExactInt.of(300), ExactInt.of(400), ExactInt.of(500),
            ExactInt.of(600))
        var reds = 0
        var matches = 0
        var redCells = 0
        for (ordinal in 1..720) {
            val drop = ExactInt.of(ordinal.toLong())
            val data = adapter.oldFixedPour(drop, 1, old, stones[1])
            val normativeOrder = NormativeCore.bowlOrderFromDrop(drop).toList()
            insist("E_DISCOVERY09_ORDER_$ordinal",
                data.drop == drop && data.iteration == 1 &&
                data.order == normativeOrder &&
                data.sourceIdsWrong == listOf(1,2,3) &&
                data.sourceIdsByPosition == normativeOrder.take(3) &&
                data.patch08Calls == 1 && data.fixedPourCalls == 1 &&
                data.pours.size == 7 && data.pours[0] == zero &&
                data.pours.drop(4).all { it == zero })
            var mismatch = false
            for (p in 1..3) {
                val coefficient = stones[1].components()[p-1]
                val normativePour = NormativeCore.save(drop.square() +
                    coefficient * old[normativeOrder[p-1]] +
                    ExactInt.of(((2L * p + 1) * 1)))
                val physicalWrong = NormativeCore.save(drop.square() +
                    coefficient * old[p] + ExactInt.of((2L * p + 1)))
                insist("E_DISCOVERY09_ACTUAL_FIXED_$ordinal-$p",
                    data.pours[p] == physicalWrong)
                if (data.pours[p] != normativePour) {
                    mismatch = true
                    redCells++
                }
            }
            if (mismatch) reds++ else matches++
        }
        insist("E_DISCOVERY09_PERMUTATION_COUNTS",
            reds == 714 && matches == 6 && redCells == 1800)
        println("STAGE18_FIXED_POURS_EXPECTED_RED_714")
        println("STAGE18_INCIDENTAL_MATCH_6")
        println("STAGE18_WRONG_POUR_CELLS_1800")
        println("STAGE18_ORDERED_SOURCES_ZERO_PATCH_PASS")

        val reversed = adapter.oldFixedPour(ExactInt.of(720),1,old,stones[1])
        insist("E_DISCOVERY09_REVERSE_BOUNDARY",
            reversed.order == listOf(6,5,4,3,2,1) &&
            reversed.sourceIdsWrong == listOf(1,2,3) &&
            reversed.sourceIdsByPosition == listOf(6,5,4))
        insist("E_DISCOVERY09_REJECT_ITERATION", try {
            adapter.oldFixedPour(one,0,old,stones[1]); false
        } catch (e: IllegalArgumentException) {
            e.message == "E_DISCOVERY09_ITERATION_RANGE"
        })
        insist("E_DISCOVERY09_REJECT_INITIAL", try {
            adapter.oldFixedPour(one,1,old.take(6),stones[1]); false
        } catch (e: IllegalArgumentException) {
            e.message == "E_DISCOVERY09_BOWL_SHAPE"
        })
        println("STAGE18_REVERSED_ORDER_SCAR_PASS")

        val initial = old.toList()
        val reverseDrops = listOf(zero) + List(46) { ExactInt.of(720) }
        val identityDrops = listOf(zero) + List(46) { one }
        val reverse = adapter.runWrongPours(initial,reverseDrops,stones)
        val identity = adapter.runWrongPours(initial,identityDrops,stones)
        val (normativeReverse, normativeLastOrder) =
            NormativeCore.applyVisibleDropsToBowls(
                initial.toTypedArray(),reverseDrops.toTypedArray())
        val (normativeIdentity, normativeIdentityOrder) =
            NormativeCore.applyVisibleDropsToBowls(
                initial.toTypedArray(),identityDrops.toTypedArray())
        insist("E_DISCOVERY09_FULL_46_REVERSE",
            reverse.steps.size == 46 && reverse.fixedPourCalls == 46 &&
            reverse.permutationPatchCalls == 46 &&
            reverse.steps.map { it.iteration } == (1..46).toList() &&
            reverse.steps.all {
                it.fixedPour.sourceIdsWrong == listOf(1,2,3) &&
                it.fixedPour.sourceIdsByPosition == listOf(6,5,4) &&
                it.order == listOf(6,5,4,3,2,1)
            } &&
            reverse.orderAt46 == normativeLastOrder.toList() &&
            reverse.finalBowls != normativeReverse.toList() &&
            reverse.steps[0].oldBowls == initial &&
            reverse.steps[1].oldBowls == reverse.steps[0].newBowls)
        insist("E_DISCOVERY09_FULL_46_IDENTITY",
            identity.steps.size == 46 && identity.fixedPourCalls == 46 &&
            identity.orderAt46 == normativeIdentityOrder.toList() &&
            identity.finalBowls == normativeIdentity.toList())
        insist("E_DISCOVERY09_CALL_46_LAST",
            reverse.steps[45].iteration == 46 &&
            reverse.steps[45].newBowls == reverse.finalBowls)
        println("STAGE18_46_DROPS_REVERSED_RED_PASS")
        println("STAGE18_46_DROPS_IDENTITY_MATCH_PASS")
        println("STAGE18_46_SNAPSHOT_CHAIN_PASS")

        // 46 diferion o'r oracl prawf fel Mewnbwn, nid fel ffynhonnell cynhyrchu.
        val f = NormativeCore.FOUNDATION_DAY
        val counts = NormativeCore.workCounts(f,f)
        val hidden = NormativeCore.buildHiddenDrops(counts)
        val visible = NormativeCore.buildVisibleDrops(counts,NormativeCore.STONES,hidden)
        val computedInitial = NormativeCore.initialBowls(counts)
        val actualNatural = adapter.runWrongPours(computedInitial.toList(),visible.toList(),stones)
        val (expectedNatural,orderNatural) =
            NormativeCore.applyVisibleDropsToBowls(computedInitial,visible)
        insist("E_DISCOVERY09_NATURAL_46",
            actualNatural.steps.size == 46 &&
            actualNatural.orderAt46 == orderNatural.toList() &&
            actualNatural.finalBowls != expectedNatural.toList() &&
            actualNatural.steps.any {
                it.fixedPour.sourceIdsWrong != it.fixedPour.sourceIdsByPosition
            })
        println("STAGE18_NATURAL_ORACLE_46_EXPECTED_RED")

        val manager = MonsterBootstrapManager()
        val context = manager.observeLegacyFixedPours(f,f,initial,reverseDrops)
        val stored = context.discovery09Steps ?: error("E_DISCOVERY09_CONTEXT_STEPS")
        insist("E_DISCOVERY09_PRODUCTION",
            context.phase == "DISCOVERY_09" &&
            context.status == "LEGACY_FIXED_POURS_OBSERVED" &&
            context.branchTrace == listOf("BOOT","DISCOVERY_09") &&
            context.diagnostics == listOf(
                "DISCOVERY_09_FIXED_IDS_NOT_ORDER_POSITIONS") &&
            context.discovery09InitialBowls == initial &&
            context.discovery09VisibleDrops == reverseDrops &&
            stored.size == 46 && stored[0].oldBowls == initial &&
            context.discovery09FinalBowls == reverse.finalBowls &&
            context.discovery09OrderAt46 == listOf(6,5,4,3,2,1) &&
            context.discovery09FixedPourCalls == 46 &&
            context.discovery09PermutationPatchCalls == 46 &&
            context.discovery09InvocationCount == 1)
        println("STAGE18_PRODUCTION_46_POURS_PASS")
        val before = manager.metrics.snapshot()
        val beforeTrace = context.branchTrace.toList()
        val beforeDiag = context.diagnostics.toList()
        insist("E_DISCOVERY09_METRICS",
            before["discovery09.fixed.pour.calls"] == 1L)
        insist("E_DISCOVERY09_REPLAY",
            machineCode { manager.dispatcher.dispatch(context) } ==
                "E_DISCOVERY09_CONTEXT_NOT_READY" &&
            context.discovery09Steps === stored &&
            context.discovery09InvocationCount == 1 &&
            context.branchTrace == beforeTrace &&
            context.diagnostics == beforeDiag &&
            manager.metrics.snapshot() == before)
        val unbooted = BaseMonsterContext(f,f,phase="DISCOVERY_09",
            discovery09InitialBowls=initial,discovery09VisibleDrops=reverseDrops)
        insist("E_DISCOVERY09_BOOT",
            machineCode { manager.dispatcher.dispatch(unbooted) } ==
                "E_DISCOVERY09_CONTEXT_NOT_READY" &&
            unbooted.discovery09Steps == null &&
            unbooted.discovery09InvocationCount == 0 &&
            manager.metrics.snapshot() == before)
        val withoutInitial = BaseMonsterContext(f,f,status="READY",
            phase="DISCOVERY_09",discovery09VisibleDrops=reverseDrops)
        insist("E_DISCOVERY09_NO_INITIAL",
            machineCode { manager.dispatcher.dispatch(withoutInitial) } ==
                "E_DISCOVERY09_NO_INITIAL" &&
            withoutInitial.discovery09Steps == null &&
            manager.metrics.snapshot() == before)
        val withoutVisible = BaseMonsterContext(f,f,status="READY",
            phase="DISCOVERY_09",discovery09InitialBowls=initial)
        insist("E_DISCOVERY09_NO_VISIBLE",
            machineCode { manager.dispatcher.dispatch(withoutVisible) } ==
                "E_DISCOVERY09_NO_VISIBLE" &&
            withoutVisible.discovery09Steps == null &&
            manager.metrics.snapshot() == before)
        val second = manager.observeLegacyFixedPours(f-11L,f+71L,initial,identityDrops)
        insist("E_DISCOVERY09_OWNERSHIP",
            second !== context && second.discovery09Steps !== stored &&
            second.discovery09FinalBowls == identity.finalBowls &&
            second.discovery09FinalBowls != context.discovery09FinalBowls &&
            stored[0].fixedPour.sourceIdsByPosition == listOf(6,5,4) &&
            second.discovery09Steps?.get(0)?.fixedPour?.sourceIdsByPosition ==
                listOf(1,2,3))
        println("STAGE18_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE18_CONTEXT_OWNERSHIP_PASS")

        val previous = manager.applyPermutationPatch(f,f,ExactInt.of(720))
        insist("E_DISCOVERY09_PATCH08_PRESERVED",
            previous.patch08CorrectedOrder == listOf(6,5,4,3,2,1) &&
            previous.patch08LegacyUndefined == true)
        val legacy = manager.observeLegacyPermutation(f,f,ExactInt.of(720))
        insist("E_DISCOVERY09_DISCOVERY08_PRESERVED",
            legacy.discovery08LegacyOrder == null &&
            legacy.discovery08Undefined == true)
        val fixedGrind = manager.applyGrindPatch(f,f,11)
        insist("E_DISCOVERY09_PATCH07_PRESERVED",
            fixedGrind.patch07CorrectedRow == VisibleGrindRow(37,41,43,47,0))
        println("STAGE18_EARLIER_ROUTES_PASS")
        println("STAGE18_NATIVE_EXPECTED_RED_COMPLETE")
    }
}
