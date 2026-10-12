package pastafari

/** Cam 23 — PATCH 11: prawf cynhyrchu ac oracl gwreiddiol. */
object Stage23Tests {
    private fun insist(code: String, yes: Boolean) { check(yes) { code } }
    private fun machine(run: () -> Unit): String = try {
        run(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    private fun fresh(old: List<ExactInt>, stir: Int): ExactInt {
        var total = ExactInt.ZERO
        for (id in 1..6) total += old[id]
        return NormativeCore.save(total + ExactInt.of(149L*stir))
    }
    private fun independentStep(
        old: List<ExactInt>, stir: Int, sum: ExactInt
    ): Pair<List<Int>,List<ExactInt>> {
        val order=NormativeCore.bowlOrderFromDrop(sum).toList()
        val output=MutableList(7){ExactInt.ZERO}
        for(p in 1..6){
            val id=order[p-1]
            val prev=order[if(p==1)5 else p-2]
            val next=order[if(p==6)0 else p]
            val mixed=old[id]+old[prev].multiplyByInt(3)+
                old[next].multiplyByInt(5)+sum+
                ExactInt.of((stir+p*p).toLong())
            output[id]=NormativeCore.save(
                mixed.square()+(old[prev]*old[next]).multiplyByInt(7))
        }
        return order to output.toList()
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_PATCH11_ARGS"}
        val patch=FreshStirPatchWrapper()
        var good=0;var preservedRed=0;var firstGreen=0
        var staleAt2=0;var verifiedSteps=0
        for(n in 1..720){
            val value=ExactInt.of(n.toLong())
            val input=listOf(ExactInt.ZERO,
                ExactInt.of(101L)+value,
                ExactInt.of(211L)+value.multiplyByInt(2),
                ExactInt.of(307L)+value.multiplyByInt(3),
                ExactInt.of(401L)+value.multiplyByInt(4),
                ExactInt.of(503L)+value.multiplyByInt(5),
                ExactInt.of(607L)+value.multiplyByInt(6))
            val unchanged=input.toList()
            val result=patch.patch(input)
            val normative=NormativeCore.postStir12(input.toTypedArray()).toList()
            insist("E_PATCH11_RESULT_SHAPE_$n",
                result.steps.size==12 && result.finalBowls.size==7 &&
                result.legacyRun.steps.size==12 &&
                result.legacyRuns==1 &&
                result.legacyCacheComputations==1 &&
                result.correctedSumComputations==12 &&
                result.legacyPermutationCalls==12 &&
                result.correctedPermutationCalls==12 &&
                result.steps.map{it.stir}==(1..12).toList() &&
                result.legacyRun.steps.all{
                    it.savedSumUsed==result.legacyRun.originalCachedSum &&
                    it.sumCacheOriginStir==1
                } && input==unchanged)
            var current=input.toList()
            for(stir in 1..12){
                val step=result.steps[stir-1]
                val saved=fresh(current,stir)
                val (order,next)=independentStep(current,stir,saved)
                insist("E_PATCH11_STEP_$n-$stir",
                    step.oldSnapshot==current &&
                    step.freshSavedSum==saved &&
                    step.correctedPermutationOrder==order &&
                    step.newBowls==next && step.permutationPatchCalls==1)
                if(stir==1){
                    insist("E_PATCH11_FIRST_GREEN_$n",
                        step.newBowls==result.legacyRun.steps[0].newBowls &&
                        step.freshSavedSum==result.legacyRun.originalCachedSum)
                    firstGreen++
                }
                if(stir==2){
                    insist("E_PATCH11_STALE_SCAR_$n",
                        step.freshSavedSum != result.legacyRun.originalCachedSum &&
                        step.newBowls != result.legacyRun.steps[1].newBowls)
                    staleAt2++
                }
                current=next
                verifiedSteps++
            }
            insist("E_PATCH11_FINAL_GREEN_$n",
                result.finalBowls==normative &&
                result.finalBowls==current &&
                result.legacyRun.finalBowls!=normative)
            good++;preservedRed++
        }
        insist("E_PATCH11_720_COUNTS",
            good==720 && preservedRed==720 && firstGreen==720 &&
            staleAt2==720 && verifiedSteps==8640)
        println("STAGE23_PATCHED_FINAL_GREEN_720")
        println("STAGE23_PRESERVED_LEGACY_RED_720")
        println("STAGE23_FIRST_STIR_BOTH_GREEN_720")
        println("STAGE23_STIR2_FRESH_SUM_GREEN_720")
        println("STAGE23_INDEPENDENT_STIR_STEPS_8640")

        val z=ExactInt.ZERO
        val seeded=listOf(z,ExactInt.of(101L),ExactInt.of(211L),
            ExactInt.of(307L),ExactInt.of(401L),
            ExactInt.of(503L),ExactInt.of(607L))
        val specials=listOf(
            seeded,
            listOf(z)+List(6){ExactInt.ONE},
            listOf(z)+List(6){k->ExactInt.parse(
                "12345678901234567890123456789012345678901234567890")+
                    ExactInt.of(k.toLong())},
            listOf(z)+List(6){k->ExactInt.parse(
                "-98765432109876543210987654321098765432109876543210")-
                    ExactInt.of(k.toLong())})
        for((i,input)in specials.withIndex()){
            val result=patch.patch(input)
            insist("E_PATCH11_SIGNED_$i",
                result.finalBowls==NormativeCore.postStir12(input.toTypedArray()).toList() &&
                result.legacyRun.finalBowls!=result.finalBowls)
        }
        println("STAGE23_SIGNED_AND_HUGE_INPUTS_GREEN")
        for(invalid in listOf(seeded.drop(1),
            listOf(ExactInt.ONE)+seeded.drop(1))){
            insist("E_PATCH11_INVALID_INPUT",try{
                patch.patch(invalid);false
            }catch(e:IllegalArgumentException){
                e.message=="E_PATCH11_INITIAL_BOWL_SHAPE"
            })
        }
        println("STAGE23_INPUT_GUARDS_PASS")

        val f=NormativeCore.FOUNDATION_DAY
        val manager=MonsterBootstrapManager()
        val context=manager.applyFreshStirPatch(f,f,seeded)
        val steps=context.patch11Steps?:error("E_PATCH11_NO_STEPS")
        insist("E_PATCH11_PRODUCTION",
            context.phase=="PATCH_11" &&
            context.status=="PATCHED_FRESH_STIR_SUM" &&
            context.branchTrace==listOf("BOOT","PATCH_11") &&
            context.diagnostics==listOf("PATCH_11_FRESH_SUM_EACH_STIR") &&
            context.patch11InitialBowls==seeded &&
            context.patch11FinalBowls==NormativeCore.postStir12(
                seeded.toTypedArray()).toList() &&
            context.patch11LegacyRun?.cachedSumComputations==1 &&
            context.patch11LegacyRun?.finalBowls!=context.patch11FinalBowls &&
            context.patch11LegacyCacheComputations==1 &&
            context.patch11FreshSumComputations==12 &&
            context.patch11LegacyPermutationCalls==12 &&
            context.patch11CorrectedPermutationCalls==12 &&
            context.patch11Applied && context.patch11InvocationCount==1 &&
            steps.size==12)
        val metrics=manager.metrics.snapshot()
        insist("E_PATCH11_METRICS",
            metrics["patch11.legacy.cached.stir.runs"]==1L &&
            metrics["patch11.corrected.fresh.stir.runs"]==1L &&
            metrics["patch11.applied"]==1L)
        println("STAGE23_PRODUCTION_12_FRESH_STIRS_GREEN")
        val trace=context.branchTrace.toList()
        val diag=context.diagnostics.toList()
        insist("E_PATCH11_REPLAY",
            machine{manager.dispatcher.dispatch(context)}==
                "E_PATCH11_CONTEXT_NOT_READY" &&
            context.patch11Steps===steps &&
            context.patch11InvocationCount==1 &&
            context.branchTrace==trace && context.diagnostics==diag &&
            manager.metrics.snapshot()==metrics)
        val unbooted=BaseMonsterContext(f,f,phase="PATCH_11",
            patch11InitialBowls=seeded)
        val noInput=BaseMonsterContext(f,f,phase="PATCH_11",status="READY")
        insist("E_PATCH11_GUARDS",
            machine{manager.dispatcher.dispatch(unbooted)}==
                "E_PATCH11_CONTEXT_NOT_READY" &&
            machine{manager.dispatcher.dispatch(noInput)}==
                "E_PATCH11_NO_INITIAL" &&
            unbooted.patch11Steps==null && !unbooted.patch11Applied &&
            noInput.patch11Steps==null && !noInput.patch11Applied &&
            manager.metrics.snapshot()==metrics)
        val another=manager.applyFreshStirPatch(f-121L,f+99L,specials[2])
        insist("E_PATCH11_OWNERSHIP",
            another!==context && another.patch11Steps!==steps &&
            another.patch11FinalBowls!=context.patch11FinalBowls &&
            steps[0].oldSnapshot==seeded)
        println("STAGE23_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE23_CONTEXT_OWNERSHIP_PASS")

        val discovery=manager.observeLegacyCachedStir(f,f,seeded)
        val drops=listOf(z)+List(46){ExactInt.of(720L)}
        val patchedBowls=manager.applyBowlSnapshotPatch(f,f,seeded,drops)
        val normativeBowls=NormativeCore.applyVisibleDropsToBowls(
            seeded.toTypedArray(),drops.toTypedArray()).first.toList()
        insist("E_PATCH11_PREVIOUS_ROUTES",
            discovery.discovery11FinalBowls==context.patch11LegacyRun?.finalBowls &&
            discovery.discovery11CacheComputations==1 &&
            patchedBowls.patch10FinalBowls==normativeBowls &&
            patchedBowls.patch10CorrectedSnapshotCalls==46)
        println("STAGE23_EARLIER_ROUTES_PASS")
        println("STAGE23_NATIVE_GREEN")
    }
}
