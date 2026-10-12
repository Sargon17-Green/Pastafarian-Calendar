package pastafari

/** Cam 21 — PATCH 10: pob darlleniad o'r un hen snapshot. */
object Stage21Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machine(action: () -> Unit): String = try {
        action(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    private fun reference(
        drop: ExactInt, iteration: Int, old: List<ExactInt>,
        stone: MutableStoneRow
    ): Pair<List<ExactInt>,List<ExactInt>> {
        val order = NormativeCore.bowlOrderFromDrop(drop).toList()
        val row = stone.components()
        val stoneByPosition = intArrayOf(0,1,2,3,4,0)
        val pour = MutableList(7) { ExactInt.ZERO }
        for (p in 1..3) {
            pour[p] = NormativeCore.save(
                drop.square() + row[p-1]*old[order[p-1]] +
                    ExactInt.of(((2*p+1)*iteration).toLong()))
        }
        val next = MutableList(7) { ExactInt.ZERO }
        for (p in 1..6) {
            val id = order[p-1]
            val prev = order[if (p==1) 5 else p-2]
            val following = order[if (p==6) 0 else p]
            val mixed = old[id] + old[prev].multiplyByInt(2) +
                old[following].multiplyByInt(3) + pour[p] +
                drop + row[stoneByPosition[p-1]]
            next[id] = NormativeCore.save(
                mixed.square() + (old[prev]*old[following]).multiplyByInt(5) +
                    ExactInt.of((iteration*p).toLong()))
        }
        return pour.toList() to next.toList()
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH10_ARGS" }
        val z=ExactInt.ZERO
        val one=ExactInt.ONE
        val old=listOf(z,ExactInt.of(101L),ExactInt.of(211L),
            ExactInt.of(307L),ExactInt.of(401L),
            ExactInt.of(503L),ExactInt.of(607L))
        val stones=StonePatchWrapper().buildPatchedRows().rows
        insist("E_PATCH10_STONES",
            stones.size==47 && (1..46).all {
                stones[it].components()==NormativeCore.STONES[it].toList()
            })
        val wrapper=BowlSnapshotPatchWrapper()
        var green=0
        var legacyRed=0
        var oldFirstGreen=0
        var wrongOldWrites=0
        for (ordinal in 1..720) {
            val drop=ExactInt.of(ordinal.toLong())
            val result=wrapper.patch(drop,1,old,stones[1])
            val order=NormativeCore.bowlOrderFromDrop(drop).toList()
            val (expectedPour,expected)=reference(drop,1,old,stones[1])
            insist("E_PATCH10_SHAPE_$ordinal",
                result.iteration==1 && result.oldSnapshot==old &&
                result.legacyStep.iteration==1 &&
                result.legacyStep.oldSnapshot==old &&
                result.legacyStep.writes.size==6 &&
                result.legacyStep.pourPatch.order==order &&
                result.legacyStep.pourPatch.correctedPours==expectedPour &&
                result.legacyStep.pourPatch.correctedPourCalls==1 &&
                result.legacyStep.pourPatch.legacyRead.fixedPourCalls==1 &&
                result.legacyStep.pourPatch.legacyRead.patch08Calls==1 &&
                result.legacyMutatorCalls==1 &&
                result.correctedSnapshotCalls==1 &&
                result.correctedWrites.size==6 &&
                result.correctedWrites.map { it.position }==(1..6).toList() &&
                result.correctedWrites.map { it.bowlId }==order &&
                result.correctedBowls.size==7 &&
                result.correctedBowls[0]==z)
            insist("E_PATCH10_GREEN_$ordinal",
                result.correctedBowls==expected)
            for (p in 1..6) {
                val id=order[p-1]
                val prev=order[if(p==1) 5 else p-2]
                val following=order[if(p==6) 0 else p]
                val write=result.correctedWrites[p-1]
                insist("E_PATCH10_SNAPSHOT_$ordinal-$p",
                    write.position==p && write.bowlId==id &&
                    write.previousId==prev && write.nextId==following &&
                    write.previousSnapshotRead==old[prev] &&
                    write.nextSnapshotRead==old[following] &&
                    write.newValue==expected[id])
                if(result.legacyStep.writes[p-1].newValue!=expected[id]) {
                    insist("E_PATCH10_LEGACY_WRONG_POSITION_$ordinal-$p",p!=1)
                    wrongOldWrites++
                }
            }
            insist("E_PATCH10_OLD_FIRST_$ordinal",
                result.legacyStep.writes[0].newValue==expected[order[0]])
            insist("E_PATCH10_LIVE_SCAR_$ordinal",
                result.legacyStep.writes[1].previousLiveRead ==
                    result.legacyStep.writes[0].newValue &&
                result.legacyStep.writes[1].previousLiveRead != old[order[0]] &&
                result.legacyStep.newBowls != expected)
            oldFirstGreen++
            legacyRed++
            green++
        }
        insist("E_PATCH10_720_CARDINALITY",
            green==720 && legacyRed==720 && oldFirstGreen==720 &&
            wrongOldWrites==3600)
        println("STAGE21_PATCHED_GREEN_720")
        println("STAGE21_PRESERVED_LEGACY_RED_720")
        println("STAGE21_PRESERVED_FIRST_WRITE_GREEN_720")
        println("STAGE21_PRESERVED_WRONG_WRITES_3600")
        println("STAGE21_ALL_SIX_SNAPSHOT_READS_GREEN_4320")

        for(invalid in listOf(0,47)) {
            insist("E_PATCH10_ITERATION_RANGE_$invalid",try {
                wrapper.patch(one,invalid,old,stones[1]); false
            }catch(e:IllegalArgumentException){
                e.message=="E_PATCH10_ITERATION_RANGE"
            })
        }
        insist("E_PATCH10_BOWL_SHAPE",try{
            wrapper.patch(one,1,old.drop(1),stones[1]);false
        }catch(e:IllegalArgumentException){
            e.message=="E_PATCH10_BOWL_SHAPE"
        })
        insist("E_PATCH10_INPUT_UNMODIFIED",
            old==listOf(z,ExactInt.of(101L),ExactInt.of(211L),
                ExactInt.of(307L),ExactInt.of(401L),
                ExactInt.of(503L),ExactInt.of(607L)))
        println("STAGE21_INPUT_GUARDS_AND_OWNERSHIP_PASS")

        val identity=listOf(z)+List(46){one}
        val reverse=listOf(z)+List(46){ExactInt.of(720L)}
        val legacy=LegacyInPlaceBowlAdapter()
        val fixedPour=PourPatchWrapper()
        for((name,drops) in listOf("IDENTITY" to identity,"REVERSE" to reverse)) {
            val corrected=wrapper.runPatchedSnapshots(old,drops,stones)
            val wrong=legacy.runWrongInPlace(old,drops,stones)
            val pourCorrect=fixedPour.runPatchedPours(old,drops,stones)
            val (normative,normativeOrder)=NormativeCore.applyVisibleDropsToBowls(
                old.toTypedArray(),drops.toTypedArray())
            insist("E_PATCH10_46_$name",
                corrected.finalBowls==normative.toList() &&
                corrected.finalBowls==pourCorrect.finalBowls &&
                corrected.finalBowls!=wrong.finalBowls &&
                corrected.orderAt46==normativeOrder.toList() &&
                corrected.steps.size==46 &&
                corrected.legacyMutatorCalls==46 &&
                corrected.correctedSnapshotCalls==46 &&
                corrected.patchedPourCalls==46 &&
                corrected.preservedFixedPourCalls==46 &&
                corrected.permutationPatchCalls==46 &&
                corrected.preservedLegacyWrites==276 &&
                corrected.correctedWrites==276 &&
                corrected.steps.map { it.iteration }==(1..46).toList() &&
                corrected.steps[0].oldSnapshot==old &&
                corrected.steps[1].oldSnapshot==corrected.steps[0].correctedBowls &&
                corrected.steps[45].correctedBowls==corrected.finalBowls &&
                corrected.steps.all {
                    it.correctedWrites.size==6 &&
                    it.legacyStep.writes.size==6 &&
                    it.legacyStep.pourPatch.sourceIdsByPosition==
                        it.legacyStep.pourPatch.order.take(3)
                })
            println("STAGE21_46_${name}_GREEN_LEGACY_RED")
        }

        val f=NormativeCore.FOUNDATION_DAY
        val counts=NormativeCore.workCounts(f,f)
        val hidden=NormativeCore.buildHiddenDrops(counts)
        val visible=NormativeCore.buildVisibleDrops(counts,NormativeCore.STONES,hidden)
        val initial=NormativeCore.initialBowls(counts)
        val natural=wrapper.runPatchedSnapshots(initial.toList(),visible.toList(),stones)
        val oldNatural=legacy.runWrongInPlace(initial.toList(),visible.toList(),stones)
        val (referenceBowls,referenceOrder)=
            NormativeCore.applyVisibleDropsToBowls(initial,visible)
        insist("E_PATCH10_NATURAL_ORACLE",
            natural.finalBowls==referenceBowls.toList() &&
            natural.orderAt46==referenceOrder.toList() &&
            natural.finalBowls!=oldNatural.finalBowls &&
            natural.legacyMutatorCalls==46)
        println("STAGE21_NATURAL_46_ORACLE_GREEN")

        val manager=MonsterBootstrapManager()
        val context=manager.applyBowlSnapshotPatch(f,f,old,reverse)
        val stored=context.patch10Steps ?: error("E_PATCH10_NO_STEPS")
        val reverseNormative=NormativeCore.applyVisibleDropsToBowls(
            old.toTypedArray(),reverse.toTypedArray())
        insist("E_PATCH10_PRODUCTION",
            context.phase=="PATCH_10" &&
            context.status=="PATCHED_BOWL_SNAPSHOT" &&
            context.branchTrace==listOf("BOOT","PATCH_10") &&
            context.diagnostics==listOf("PATCH_10_ALL_SIX_FROM_SAME_SNAPSHOT") &&
            context.patch10InitialBowls==old &&
            context.patch10VisibleDrops==reverse &&
            context.patch10FinalBowls==reverseNormative.first.toList() &&
            context.patch10OrderAt46==reverseNormative.second.toList() &&
            context.patch10LegacyMutatorCalls==46 &&
            context.patch10CorrectedSnapshotCalls==46 &&
            context.patch10PatchedPourCalls==46 &&
            context.patch10FixedPourCalls==46 &&
            context.patch10PermutationPatchCalls==46 &&
            context.patch10LegacyWrites==276 &&
            context.patch10CorrectedWrites==276 &&
            context.patch10Applied && context.patch10InvocationCount==1 &&
            stored.size==46 &&
            stored[0].legacyStep.writes[1].previousLiveRead==
                stored[0].legacyStep.writes[0].newValue)
        val metrics=manager.metrics.snapshot()
        insist("E_PATCH10_METRICS",
            metrics["patch10.applied"]==1L &&
            metrics["patch10.legacy.inplace.calls"]==1L &&
            metrics["patch10.corrected.snapshot.calls"]==1L)
        println("STAGE21_PRODUCTION_46_GREEN")

        val trace=context.branchTrace.toList()
        val diag=context.diagnostics.toList()
        insist("E_PATCH10_REPLAY",
            machine { manager.dispatcher.dispatch(context) }==
                "E_PATCH10_CONTEXT_NOT_READY" &&
            context.patch10Steps===stored &&
            context.patch10InvocationCount==1 &&
            context.branchTrace==trace &&
            context.diagnostics==diag &&
            manager.metrics.snapshot()==metrics)
        val unbooted=BaseMonsterContext(f,f,phase="PATCH_10",
            patch10InitialBowls=old,patch10VisibleDrops=reverse)
        val noInitial=BaseMonsterContext(f,f,phase="PATCH_10",status="READY",
            patch10VisibleDrops=reverse)
        val noVisible=BaseMonsterContext(f,f,phase="PATCH_10",status="READY",
            patch10InitialBowls=old)
        insist("E_PATCH10_GUARDS",
            machine { manager.dispatcher.dispatch(unbooted) }==
                "E_PATCH10_CONTEXT_NOT_READY" &&
            machine { manager.dispatcher.dispatch(noInitial) }==
                "E_PATCH10_NO_INITIAL" &&
            machine { manager.dispatcher.dispatch(noVisible) }==
                "E_PATCH10_NO_VISIBLE" &&
            unbooted.patch10Steps==null && !unbooted.patch10Applied &&
            noInitial.patch10Steps==null && !noInitial.patch10Applied &&
            noVisible.patch10Steps==null && !noVisible.patch10Applied &&
            manager.metrics.snapshot()==metrics)
        val second=manager.applyBowlSnapshotPatch(f-11L,f+71L,old,identity)
        insist("E_PATCH10_CONTEXT_ISOLATION",
            second!==context && second.patch10Steps!==stored &&
            second.patch10FinalBowls!=context.patch10FinalBowls &&
            second.patch10Steps?.get(0)?.legacyStep?.pourPatch?.order==
                listOf(1,2,3,4,5,6) &&
            stored[0].legacyStep.pourPatch.order==listOf(6,5,4,3,2,1))
        println("STAGE21_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE21_CONTEXT_OWNERSHIP_PASS")

        val historical=manager.observeLegacyInPlaceBowls(f,f,old,reverse)
        val pour=manager.applyPourPatch(f,f,old,reverse)
        val permutation=manager.applyPermutationPatch(f,f,ExactInt.of(720L))
        insist("E_PATCH10_EARLIER_ROUTES",
            historical.discovery10FinalBowls!=context.patch10FinalBowls &&
            historical.discovery10InPlaceWrites==276 &&
            pour.patch09FinalBowls==context.patch10FinalBowls &&
            pour.patch09CorrectedPourCalls==46 &&
            permutation.patch08CorrectedOrder==listOf(6,5,4,3,2,1) &&
            permutation.patch08LegacyUndefined==true)
        println("STAGE21_EARLIER_ROUTES_PASS")
        println("STAGE21_NATIVE_GREEN")
    }
}
