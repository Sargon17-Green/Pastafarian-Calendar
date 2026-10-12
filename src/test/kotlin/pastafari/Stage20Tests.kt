package pastafari

/** Cam 20: y gwir nam yw darllen bowls byw wedi eu diweddaru. */
object Stage20Tests {
    private fun assertThat(code: String, condition: Boolean) {
        check(condition) { code }
    }
    private fun errorCode(action: () -> Unit): String = try {
        action(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    private fun referenceStep(
        drop: ExactInt, iteration: Int, old: List<ExactInt>,
        stones: MutableStoneRow
    ): Pair<List<ExactInt>, List<ExactInt>> {
        val order = NormativeCore.bowlOrderFromDrop(drop).toList()
        val row = stones.components()
        val byPosition = intArrayOf(0,1,2,3,4,0)
        val pours = MutableList(7) { ExactInt.ZERO }
        for (p in 1..3) {
            pours[p] = NormativeCore.save(
                drop.square() + row[p-1] * old[order[p-1]] +
                    ExactInt.of(((2*p+1)*iteration).toLong())
            )
        }
        val newBowls = MutableList(7) { ExactInt.ZERO }
        for (p in 1..6) {
            val id = order[p-1]
            val prev = order[if (p == 1) 5 else p-2]
            val next = order[if (p == 6) 0 else p]
            val mixed = old[id] + old[prev].multiplyByInt(2) +
                old[next].multiplyByInt(3) + pours[p] +
                drop + row[byPosition[p-1]]
            newBowls[id] = NormativeCore.save(
                mixed.square() + (old[prev]*old[next]).multiplyByInt(5) +
                    ExactInt.of((iteration*p).toLong())
            )
        }
        return pours.toList() to newBowls.toList()
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY10_ARGS" }
        val z = ExactInt.ZERO
        val one = ExactInt.ONE
        val old = listOf(z,ExactInt.of(101),ExactInt.of(211),
            ExactInt.of(307),ExactInt.of(401),
            ExactInt.of(503),ExactInt.of(607))
        val stones = StonePatchWrapper().buildPatchedRows().rows
        assertThat("E_DISCOVERY10_STONES",
            stones.size == 47 && stones[1].components() ==
                listOf(ExactInt.of(17),ExactInt.of(29),
                    ExactInt.of(43),ExactInt.of(71),ExactInt.of(101)))
        val legacy = LegacyInPlaceBowlAdapter()
        var expectedRed = 0
        var exactMatches = 0
        var wrongPositions = 0
        var firstGreen = 0
        for (ordinal in 1..720) {
            val drop = ExactInt.of(ordinal.toLong())
            val result = legacy.mutateBowlsWrong(drop,1,old,stones[1])
            val order = NormativeCore.bowlOrderFromDrop(drop).toList()
            val (pours,reference) = referenceStep(drop,1,old,stones[1])
            assertThat("E_DISCOVERY10_POUR_PATCH_$ordinal",
                result.iteration == 1 && result.oldSnapshot == old &&
                result.pourPatch.order == order &&
                result.pourPatch.sourceIdsByPosition == order.take(3) &&
                result.pourPatch.correctedPours == pours &&
                result.pourPatch.correctedPourCalls == 1 &&
                result.pourPatch.legacyRead.fixedPourCalls == 1 &&
                result.pourPatch.legacyRead.sourceIdsWrong == listOf(1,2,3) &&
                result.writes.size == 6 &&
                result.writes.map { it.bowlId } == order &&
                result.writes.map { it.position } == (1..6).toList() &&
                result.newBowls.size == 7 && result.newBowls[0] == z &&
                old == listOf(z,ExactInt.of(101),ExactInt.of(211),
                    ExactInt.of(307),ExactInt.of(401),
                    ExactInt.of(503),ExactInt.of(607)))
            assertThat("E_DISCOVERY10_FIRST_WRITE_GREEN_$ordinal",
                result.writes[0].newValue == reference[order[0]] &&
                result.writes[0].previousLiveRead == old[order[5]] &&
                result.writes[0].nextLiveRead == old[order[1]])
            firstGreen++
            assertThat("E_DISCOVERY10_FEEDBACK_READ_$ordinal",
                result.writes[1].previousId == order[0] &&
                result.writes[1].previousLiveRead == result.writes[0].newValue &&
                result.writes[1].previousLiveRead != old[order[0]] &&
                result.writes[5].nextId == order[0] &&
                result.writes[5].nextLiveRead == result.writes[0].newValue)
            var mismatch = false
            for (p in 1..6) {
                val id = order[p-1]
                assertThat("E_DISCOVERY10_WRITE_RESULT_$ordinal-$p",
                    result.writes[p-1].newValue == result.newBowls[id])
                if (result.newBowls[id] != reference[id]) {
                    assertThat("E_DISCOVERY10_FIRST_STILL_GREEN_$ordinal",
                        p != 1)
                    mismatch = true
                    wrongPositions++
                }
            }
            if (mismatch) expectedRed++ else exactMatches++
        }
        assertThat("E_DISCOVERY10_SINGLE_CARDINALITY",
            expectedRed == 720 && exactMatches == 0 &&
            firstGreen == 720 && wrongPositions == 3600)
        println("STAGE20_SINGLE_EXPECTED_RED_720")
        println("STAGE20_SINGLE_MATCH_0")
        println("STAGE20_SINGLE_FIRST_WRITE_GREEN_720")
        println("STAGE20_SINGLE_WRONG_POSITIONS_3600")
        println("STAGE20_LIVE_NEIGHBOR_READ_WITNESSES_720")

        for (invalid in listOf(0,47)) {
            assertThat("E_DISCOVERY10_INVALID_ITERATION_$invalid", try {
                legacy.mutateBowlsWrong(one,invalid,old,stones[1]); false
            } catch (e: IllegalArgumentException) {
                e.message == "E_DISCOVERY10_ITERATION_RANGE"
            })
        }
        assertThat("E_DISCOVERY10_INVALID_BOWLS",try {
            legacy.mutateBowlsWrong(one,1,old.drop(1),stones[1]); false
        } catch (e: IllegalArgumentException) {
            e.message == "E_DISCOVERY10_BOWL_SHAPE"
        })
        assertThat("E_DISCOVERY10_INVALID_TABLE",try {
            legacy.runWrongInPlace(old,List(46){one},stones); false
        } catch (e: IllegalArgumentException) {
            e.message == "E_DISCOVERY10_TABLE_SHAPE"
        })
        println("STAGE20_INPUT_GUARDS_PASS")

        val identity = listOf(z) + List(46) { one }
        val reverse = listOf(z) + List(46) { ExactInt.of(720L) }
        val identityOld = legacy.runWrongInPlace(old,identity,stones)
        val reverseOld = legacy.runWrongInPlace(old,reverse,stones)
        val patch09 = PourPatchWrapper()
        val identityGood = patch09.runPatchedPours(old,identity,stones)
        val reverseGood = patch09.runPatchedPours(old,reverse,stones)
        val (expectedIdentity,identityOrder) =
            NormativeCore.applyVisibleDropsToBowls(
                old.toTypedArray(),identity.toTypedArray())
        val (expectedReverse,reverseOrder) =
            NormativeCore.applyVisibleDropsToBowls(
                old.toTypedArray(),reverse.toTypedArray())
        assertThat("E_DISCOVERY10_46_IDENTITY",
            identityOld.steps.size == 46 &&
            identityOld.finalBowls != identityGood.finalBowls &&
            identityGood.finalBowls == expectedIdentity.toList() &&
            identityOld.orderAt46 == identityOrder.toList() &&
            identityOld.inPlaceWrites == 276 &&
            identityOld.patchedPourCalls == 46 &&
            identityOld.preservedLegacyPourCalls == 46 &&
            identityOld.permutationPatchCalls == 46)
        assertThat("E_DISCOVERY10_46_REVERSE",
            reverseOld.steps.size == 46 &&
            reverseOld.finalBowls != reverseGood.finalBowls &&
            reverseGood.finalBowls == expectedReverse.toList() &&
            reverseOld.orderAt46 == reverseOrder.toList() &&
            reverseOld.inPlaceWrites == 276 &&
            reverseOld.patchedPourCalls == 46 &&
            reverseOld.preservedLegacyPourCalls == 46 &&
            reverseOld.permutationPatchCalls == 46 &&
            reverseOld.steps.all {
                it.writes.size == 6 &&
                it.pourPatch.order == listOf(6,5,4,3,2,1) &&
                it.pourPatch.sourceIdsByPosition == listOf(6,5,4) &&
                it.writes[1].previousLiveRead == it.writes[0].newValue
            })
        assertThat("E_DISCOVERY10_46_SNAPSHOT_ROWS",
            reverseOld.steps[0].oldSnapshot == old &&
            reverseOld.steps[1].oldSnapshot == reverseOld.steps[0].newBowls &&
            reverseOld.steps[45].newBowls == reverseOld.finalBowls &&
            reverseOld.steps.map { it.iteration } == (1..46).toList())
        println("STAGE20_46_IDENTITY_EXPECTED_RED")
        println("STAGE20_46_REVERSE_EXPECTED_RED")
        println("STAGE20_46_SNAPSHOTS_ISOLATED_PASS")

        // Mae'r oracl prawf yn CYFLENWI'r diferion; nid yw cynhyrchu'n ei alw.
        val f = NormativeCore.FOUNDATION_DAY
        val counts = NormativeCore.workCounts(f,f)
        val hidden = NormativeCore.buildHiddenDrops(counts)
        val visible = NormativeCore.buildVisibleDrops(counts,NormativeCore.STONES,hidden)
        val initial = NormativeCore.initialBowls(counts)
        val naturalOld = legacy.runWrongInPlace(initial.toList(),visible.toList(),stones)
        val naturalGood = patch09.runPatchedPours(initial.toList(),visible.toList(),stones)
        val (naturalNormative,naturalOrder) =
            NormativeCore.applyVisibleDropsToBowls(initial,visible)
        assertThat("E_DISCOVERY10_NATURAL_46",
            naturalGood.finalBowls == naturalNormative.toList() &&
            naturalOld.finalBowls != naturalNormative.toList() &&
            naturalOld.orderAt46 == naturalOrder.toList() &&
            naturalOld.inPlaceWrites == 276)
        println("STAGE20_NATURAL_46_ORACLE_EXPECTED_RED")

        val manager = MonsterBootstrapManager()
        val context = manager.observeLegacyInPlaceBowls(f,f,old,reverse)
        val stored = context.discovery10Steps ?: error("E_DISCOVERY10_NO_STEPS")
        assertThat("E_DISCOVERY10_PRODUCTION",
            context.phase == "DISCOVERY_10" &&
            context.status == "LEGACY_IN_PLACE_BOWLS_OBSERVED" &&
            context.branchTrace == listOf("BOOT","DISCOVERY_10") &&
            context.diagnostics ==
                listOf("DISCOVERY_10_IN_PLACE_LIVE_BOWL_READS") &&
            context.discovery10InitialBowls == old &&
            context.discovery10VisibleDrops == reverse &&
            context.discovery10FinalBowls == reverseOld.finalBowls &&
            context.discovery10OrderAt46 == reverseOld.orderAt46 &&
            context.discovery10PatchedPourCalls == 46 &&
            context.discovery10LegacyPourCalls == 46 &&
            context.discovery10PermutationPatchCalls == 46 &&
            context.discovery10InPlaceWrites == 276 &&
            context.discovery10InvocationCount == 1 &&
            stored.size == 46)
        println("STAGE20_PRODUCTION_46_INPLACE_PASS")
        val before = manager.metrics.snapshot()
        val trace = context.branchTrace.toList()
        val diagnostics = context.diagnostics.toList()
        assertThat("E_DISCOVERY10_REPLAY",
            errorCode { manager.dispatcher.dispatch(context) } ==
                "E_DISCOVERY10_CONTEXT_NOT_READY" &&
            context.discovery10Steps === stored &&
            context.discovery10InvocationCount == 1 &&
            context.branchTrace == trace &&
            context.diagnostics == diagnostics &&
            manager.metrics.snapshot() == before)
        val unbooted = BaseMonsterContext(f,f,phase="DISCOVERY_10",
            discovery10InitialBowls=old,discovery10VisibleDrops=reverse)
        assertThat("E_DISCOVERY10_NOT_READY",
            errorCode { manager.dispatcher.dispatch(unbooted) } ==
                "E_DISCOVERY10_CONTEXT_NOT_READY" &&
            unbooted.discovery10Steps == null &&
            unbooted.discovery10InvocationCount == 0 &&
            manager.metrics.snapshot() == before)
        val noInitial = BaseMonsterContext(f,f,phase="DISCOVERY_10",
            status="READY",discovery10VisibleDrops=reverse)
        val noVisible = BaseMonsterContext(f,f,phase="DISCOVERY_10",
            status="READY",discovery10InitialBowls=old)
        assertThat("E_DISCOVERY10_MISSING_INPUTS",
            errorCode { manager.dispatcher.dispatch(noInitial) } ==
                "E_DISCOVERY10_NO_INITIAL" &&
            errorCode { manager.dispatcher.dispatch(noVisible) } ==
                "E_DISCOVERY10_NO_VISIBLE" &&
            noInitial.discovery10Steps == null &&
            noVisible.discovery10Steps == null &&
            manager.metrics.snapshot() == before)
        val another = manager.observeLegacyInPlaceBowls(f-71L,f+91L,old,identity)
        assertThat("E_DISCOVERY10_OWNERSHIP",
            another !== context && another.discovery10Steps !== stored &&
            another.discovery10FinalBowls == identityOld.finalBowls &&
            another.discovery10FinalBowls != reverseOld.finalBowls &&
            stored[0].pourPatch.order == listOf(6,5,4,3,2,1) &&
            another.discovery10Steps?.get(0)?.pourPatch?.order ==
                listOf(1,2,3,4,5,6))
        println("STAGE20_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE20_CONTEXT_OWNERSHIP_PASS")

        val fixed = manager.applyPourPatch(f,f,old,reverse)
        val scar = manager.observeLegacyFixedPours(f,f,old,reverse)
        assertThat("E_DISCOVERY10_PATCH09_UNCHANGED",
            fixed.patch09FinalBowls == reverseGood.finalBowls &&
            fixed.patch09FinalBowls != reverseOld.finalBowls &&
            fixed.patch09CorrectedPourCalls == 46)
        assertThat("E_DISCOVERY10_DISCOVERY09_UNCHANGED",
            scar.discovery09FinalBowls != fixed.patch09FinalBowls &&
            scar.discovery09Steps?.get(0)?.fixedPour?.sourceIdsWrong ==
                listOf(1,2,3))
        val earlier = manager.applyPermutationPatch(f,f,ExactInt.of(720L))
        assertThat("E_DISCOVERY10_PATCH08_UNCHANGED",
            earlier.patch08CorrectedOrder == listOf(6,5,4,3,2,1) &&
            earlier.patch08LegacyUndefined == true)
        println("STAGE20_EARLIER_ROUTES_PASS")
        println("STAGE20_NATIVE_EXPECTED_RED_COMPLETE")
    }
}
