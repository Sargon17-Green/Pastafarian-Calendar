package pastafari

/** Cam 25 — PATCH 12: y cymydog cywir o order diferyn 46. */
object Stage25Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machine(run: () -> Unit): String = try {
        run(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PATCH12_ARGS" }
        val bowls = listOf(ExactInt.ZERO,ExactInt.of(101L),ExactInt.of(211L),
            ExactInt.of(307L),ExactInt.of(401L),ExactInt.of(503L),
            ExactInt.of(607L))
        val wrapper = PositionalNeighborPatchWrapper()
        var corrected = 0
        var legacyRed = 0
        var incidentalMatch = 0
        var numericCycles = 0
        for (ordinal in 1..720) {
            val drop = ExactInt.of(ordinal.toLong())
            val order = NormativeCore.bowlOrderFromDrop(drop).toList()
            for (seal in listOf(21,31)) {
                var allMatch = true
                for (queried in 1..6) {
                    val outcome = wrapper.patch(bowls,drop,queried,seal)
                    val normative = NormativeCore.askBowl(
                        NormativeCore.SauceResult(
                            bowls.toTypedArray(),order.toIntArray()),queried,seal)
                    val expected = order[(order.indexOf(queried)+1)%6]
                    val numeric = if (queried == 6) 1 else queried + 1
                    insist("E_PATCH12_ORACLE_$ordinal-$seal-$queried",
                        outcome.drop46 == drop &&
                        outcome.drop46Order == order &&
                        outcome.seal == seal &&
                        outcome.queriedBowlId == queried &&
                        outcome.correctedNeighborId == expected &&
                        outcome.correctedFirstAnswer == normative.first &&
                        outcome.correctedDirectionStep == normative.directionStep &&
                        outcome.correctedDirectionNumber.modInt(2) ==
                            (if (normative.directionStep == 1) 1 else 0) &&
                        outcome.legacyRead.actualNeighborIdWrong == numeric &&
                        outcome.legacyRead.positionalNeighborIdExpected == expected &&
                        outcome.legacyNumericNeighborCalls == 1 &&
                        outcome.correctedNeighborCalls == 1 &&
                        outcome.patchedPermutationCalls == 1)
                    if (numeric == expected) {
                        insist("E_PATCH12_INCIDENTAL_$ordinal-$queried",
                            outcome.legacyRead.firstAnswer ==
                                outcome.correctedFirstAnswer &&
                            outcome.legacyRead.directionStep ==
                                outcome.correctedDirectionStep)
                        incidentalMatch++
                    } else {
                        insist("E_PATCH12_LEGACY_RED_$ordinal-$queried",
                            outcome.legacyRead.firstAnswer !=
                                outcome.correctedFirstAnswer)
                        legacyRed++
                        allMatch = false
                    }
                    corrected++
                }
                if (allMatch) numericCycles++
            }
        }
        insist("E_PATCH12_COUNTS",corrected==8640 &&
            legacyRed==6912 && incidentalMatch==1728 && numericCycles==12)
        println("STAGE25_CORRECTED_QUERIES_GREEN_8640")
        println("STAGE25_PRESERVED_LEGACY_RED_6912")
        println("STAGE25_PRESERVED_INCIDENTAL_MATCH_1728")
        println("STAGE25_PRESERVED_NUMERIC_CYCLES_12")
        println("STAGE25_DIRECTION_STEPS_NORMATIVE_PASS")

        val reverse=wrapper.patch(bowls,ExactInt.of(720L),6,31)
        insist("E_PATCH12_REVERSE_WRAP",reverse.drop46Order==
            listOf(6,5,4,3,2,1) && reverse.correctedNeighborId==5 &&
            reverse.legacyRead.actualNeighborIdWrong==1 &&
            reverse.correctedFirstAnswer!=reverse.legacyRead.firstAnswer)
        println("STAGE25_REVERSE_AND_WRAPAROUND_GREEN")
        for (invalid in listOf(0,7)) {
            insist("E_PATCH12_INVALID_QUERY_$invalid",try {
                wrapper.patch(bowls,ExactInt.ONE,invalid,21);false
            }catch(e:IllegalArgumentException){
                e.message=="E_PATCH12_QUERY_BOWL_RANGE"
            })
        }
        insist("E_PATCH12_BAD_SHAPE",try {
            wrapper.patch(bowls.drop(1),ExactInt.ONE,1,21);false
        }catch(e:IllegalArgumentException){
            e.message=="E_PATCH12_FINAL_BOWL_SHAPE"
        })
        insist("E_PATCH12_BAD_SENTINEL",try {
            wrapper.patch(listOf(ExactInt.ONE)+bowls.drop(1),
                ExactInt.ONE,1,21);false
        }catch(e:IllegalArgumentException){
            e.message=="E_PATCH12_FINAL_BOWL_SHAPE"
        })
        insist("E_PATCH12_BAD_SEAL",try {
            wrapper.patch(bowls,ExactInt.ONE,1,0);false
        }catch(e:IllegalArgumentException){
            e.message=="E_PATCH12_SEAL_RANGE"
        })
        println("STAGE25_INPUT_GUARDS_PASS")

        val f=NormativeCore.FOUNDATION_DAY
        val manager=MonsterBootstrapManager()
        val context=manager.applyPositionalNeighborPatch(
            f,f,bowls,ExactInt.of(720L),6,31)
        val stored=context.patch12Outcome?:error("E_PATCH12_NO_OUTCOME")
        insist("E_PATCH12_PRODUCTION",context.phase=="PATCH_12" &&
            context.status=="PATCHED_POSITIONAL_NEIGHBOR" &&
            context.branchTrace==listOf("BOOT","PATCH_12") &&
            context.diagnostics==listOf("PATCH_12_DROP46_POSITIONAL_NEXT_BOWL") &&
            context.patch12FinalBowls==bowls &&
            context.patch12Drop46==ExactInt.of(720L) &&
            context.patch12QueryBowl==6 &&
            context.patch12Seal==31 &&
            context.patch12CorrectedNeighborId==5 &&
            context.patch12CorrectedFirstAnswer==reverse.correctedFirstAnswer &&
            context.patch12CorrectedDirectionNumber==
                reverse.correctedDirectionNumber &&
            context.patch12CorrectedDirectionStep==reverse.correctedDirectionStep &&
            context.patch12LegacyNumericNeighborCalls==1 &&
            context.patch12CorrectedNeighborCalls==1 &&
            context.patch12PermutationPatchCalls==1 &&
            context.patch12Applied && context.patch12InvocationCount==1 &&
            stored.legacyRead.actualNeighborIdWrong==1)
        val metrics=manager.metrics.snapshot()
        insist("E_PATCH12_METRICS",
            metrics["patch12.legacy.numeric.neighbor.calls"]==1L &&
            metrics["patch12.corrected.positional.neighbor.calls"]==1L &&
            metrics["patch12.applied"]==1L)
        println("STAGE25_PRODUCTION_POSITIONAL_GREEN")

        val trace=context.branchTrace.toList()
        val diagnostics=context.diagnostics.toList()
        insist("E_PATCH12_REPLAY",
            machine{manager.dispatcher.dispatch(context)}==
                "E_PATCH12_CONTEXT_NOT_READY" &&
            context.patch12Outcome===stored &&
            context.patch12InvocationCount==1 &&
            context.branchTrace==trace &&
            context.diagnostics==diagnostics &&
            manager.metrics.snapshot()==metrics)
        val unbooted=BaseMonsterContext(f,f,phase="PATCH_12",
            patch12FinalBowls=bowls,patch12Drop46=ExactInt.ONE,
            patch12QueryBowl=1,patch12Seal=21)
        val noBowls=BaseMonsterContext(f,f,phase="PATCH_12",
            status="READY",patch12Drop46=ExactInt.ONE,
            patch12QueryBowl=1,patch12Seal=21)
        val noDrop=BaseMonsterContext(f,f,phase="PATCH_12",
            status="READY",patch12FinalBowls=bowls,
            patch12QueryBowl=1,patch12Seal=21)
        val noQuery=BaseMonsterContext(f,f,phase="PATCH_12",
            status="READY",patch12FinalBowls=bowls,
            patch12Drop46=ExactInt.ONE,patch12Seal=21)
        val noSeal=BaseMonsterContext(f,f,phase="PATCH_12",
            status="READY",patch12FinalBowls=bowls,
            patch12Drop46=ExactInt.ONE,patch12QueryBowl=1)
        insist("E_PATCH12_BOOT_AND_GUARDS",
            machine{manager.dispatcher.dispatch(unbooted)}==
                "E_PATCH12_CONTEXT_NOT_READY" &&
            machine{manager.dispatcher.dispatch(noBowls)}==
                "E_PATCH12_NO_BOWLS" &&
            machine{manager.dispatcher.dispatch(noDrop)}==
                "E_PATCH12_NO_DROP46" &&
            machine{manager.dispatcher.dispatch(noQuery)}==
                "E_PATCH12_NO_QUERY" &&
            machine{manager.dispatcher.dispatch(noSeal)}==
                "E_PATCH12_NO_SEAL" &&
            listOf(unbooted,noBowls,noDrop,noQuery,noSeal).all {
                it.patch12Outcome==null && !it.patch12Applied &&
                it.patch12InvocationCount==0
            } && manager.metrics.snapshot()==metrics)
        println("STAGE25_BOOT_REPLAY_GUARDS_PASS")
        val other=manager.applyPositionalNeighborPatch(
            f-99L,f+77L,bowls,ExactInt.ONE,1,21)
        insist("E_PATCH12_ISOLATION",other!==context &&
            other.patch12Outcome!==stored &&
            other.patch12Outcome?.drop46Order==listOf(1,2,3,4,5,6) &&
            context.patch12Outcome===stored &&
            stored.drop46Order==listOf(6,5,4,3,2,1))
        println("STAGE25_CONTEXT_OWNERSHIP_PASS")

        val old=manager.observeLegacyNumericNeighbor(
            f,f,bowls,ExactInt.of(720L),6,31)
        insist("E_PATCH12_DISCOVERY12_PRESERVED",
            old.discovery12FirstAnswer==reverse.legacyRead.firstAnswer &&
            old.discovery12ActualNumericNeighbor==1 &&
            old.discovery12ExpectedPositionalNeighbor==5 &&
            old.discovery12FirstAnswer!=context.patch12CorrectedFirstAnswer)
        val counts=NormativeCore.workCounts(f,f)
        val hidden=NormativeCore.buildHiddenDrops(counts)
        val visible=NormativeCore.buildVisibleDrops(counts,NormativeCore.STONES,hidden)
        val initial=NormativeCore.initialBowls(counts)
        val afterDrops=manager.applyBowlSnapshotPatch(
            f,f,initial.toList(),visible.toList())
        val afterStir=manager.applyFreshStirPatch(
            f,f,afterDrops.patch10FinalBowls?:error("E_PATCH12_AFTER46"))
        val sauce=NormativeCore.sauce(f,f)
        val finalBowls=afterStir.patch11FinalBowls?:error("E_PATCH12_AFTER12")
        insist("E_PATCH12_PRIOR_SAUCE",
            finalBowls==sauce.bowls.toList() &&
            afterDrops.patch10OrderAt46==sauce.orderAtDrop46.toList())
        for(seal in listOf(21,31)) for(id in 1..6) {
            val result=manager.applyPositionalNeighborPatch(
                f,f,finalBowls,visible[46],id,seal)
            val normative=NormativeCore.askBowl(sauce,id,seal)
            insist("E_PATCH12_NATURAL_$seal-$id",
                result.patch12CorrectedNeighborId==
                    NormativeCore.nextBowlInDrop46Order(sauce,id) &&
                result.patch12CorrectedFirstAnswer==normative.first &&
                result.patch12CorrectedDirectionStep==normative.directionStep)
        }
        println("STAGE25_NATURAL_SAUCE_ORACLE_GREEN")
        println("STAGE25_EARLIER_ROUTES_PASS")
        println("STAGE25_NATIVE_GREEN")
    }
}
