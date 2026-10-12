package pastafari

/** Cam 22: 12 stir, y savedBowlSum o stir 1 yn sownd. */
object Stage22Tests {
    private fun insist(code: String, ok: Boolean) { check(ok) { code } }
    private fun machine(action: () -> Unit): String = try {
        action(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }

    /** Oracl prawf: y cymysgiad cywir â saved sum a roddwyd yn benodol. */
    private fun mixingWithSum(
        old: List<ExactInt>, stir: Int, used: ExactInt
    ): Pair<List<Int>,List<ExactInt>> {
        val order=NormativeCore.bowlOrderFromDrop(used).toList()
        val next=MutableList(7){ExactInt.ZERO}
        for(p in 1..6){
            val id=order[p-1]
            val prev=order[if(p==1)5 else p-2]
            val following=order[if(p==6)0 else p]
            val s=old[id]+old[prev].multiplyByInt(3)+
                old[following].multiplyByInt(5)+used+
                ExactInt.of(stir.toLong())+
                ExactInt.of((p*p).toLong())
            next[id]=NormativeCore.save(
                s.square()+(old[prev]*old[following]).multiplyByInt(7))
        }
        return order to next.toList()
    }

    private fun savedFresh(bowls:List<ExactInt>,stir:Int):ExactInt {
        var total=ExactInt.ZERO
        for(id in 1..6)total+=bowls[id]
        return NormativeCore.save(total+ExactInt.of(149L*stir))
    }

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY11_ARGS"}
        val adapter=LegacyCachedStirAdapter()
        var firstGreen=0
        var secondRed=0
        var finalRed=0
        var distinctCache=0
        var fullStaleTrace=0
        for(n in 1..720){
            val base=ExactInt.of(n.toLong())
            val initial=listOf(ExactInt.ZERO,
                ExactInt.of(101L)+base,
                ExactInt.of(211L)+base.multiplyByInt(2),
                ExactInt.of(307L)+base.multiplyByInt(3),
                ExactInt.of(401L)+base.multiplyByInt(4),
                ExactInt.of(503L)+base.multiplyByInt(5),
                ExactInt.of(607L)+base.multiplyByInt(6))
            val original=initial.toList()
            val run=adapter.oldCachedPostStir12(initial)
            val normative=NormativeCore.postStir12(initial.toTypedArray()).toList()
            insist("E_DISCOVERY11_SHAPE_$n",
                run.steps.size==12 && run.totalStirs==12 &&
                run.permutationPatchCalls==12 &&
                run.cachedSumComputations==1 &&
                run.finalBowls.size==7 &&
                run.finalBowls[0]==ExactInt.ZERO &&
                run.steps.map{it.stir}==(1..12).toList() &&
                run.steps.all {
                    it.savedSumUsed==run.originalCachedSum &&
                    it.sumCacheOriginStir==1 &&
                    it.correctedPermutationOrder.sorted()==listOf(1,2,3,4,5,6) &&
                    it.patchedPermutationCalls==1
                } && initial==original)
            insist("E_DISCOVERY11_CACHE_FIRST_$n",
                run.originalCachedSum==savedFresh(initial,1) &&
                run.steps[0].oldSnapshot==initial)
            var staleCurrent=initial.toList()
            var freshCurrent=initial.toList()
            for(stir in 1..12){
                val index=stir-1
                val step=run.steps[index]
                val (orderWrong,wrongNext)=mixingWithSum(
                    staleCurrent,stir,run.originalCachedSum)
                val freshSum=savedFresh(freshCurrent,stir)
                val (_,normativeNext)=mixingWithSum(freshCurrent,stir,freshSum)
                insist("E_DISCOVERY11_STALE_ONLY_$n-$stir",
                    step.oldSnapshot==staleCurrent &&
                    step.correctedPermutationOrder==orderWrong &&
                    step.newBowls==wrongNext &&
                    step.savedSumUsed==run.originalCachedSum)
                if(stir==1){
                    insist("E_DISCOVERY11_FIRST_GREEN_$n",
                        wrongNext==normativeNext &&
                        run.originalCachedSum==freshSum)
                    firstGreen++
                }
                if(stir==2){
                    insist("E_DISCOVERY11_SECOND_RED_$n",
                        wrongNext!=normativeNext &&
                        run.originalCachedSum!=freshSum)
                    secondRed++
                    distinctCache++
                }
                staleCurrent=wrongNext
                freshCurrent=normativeNext
            }
            insist("E_DISCOVERY11_FINAL_RED_$n",
                run.finalBowls==staleCurrent &&
                normative==freshCurrent &&
                run.finalBowls!=normative)
            finalRed++
            fullStaleTrace++
        }
        insist("E_DISCOVERY11_720_CARDINALITY",
            firstGreen==720 && secondRed==720 && finalRed==720 &&
            distinctCache==720 && fullStaleTrace==720)
        println("STAGE22_FIRST_STIR_GREEN_720")
        println("STAGE22_SECOND_STIR_EXPECTED_RED_720")
        println("STAGE22_FINAL12_EXPECTED_RED_720")
        println("STAGE22_MATCH_0")
        println("STAGE22_STALE_SUM_WITNESSES_720")
        println("STAGE22_MIXING_FORMULA_INDEPENDENT_8640")

        val z=ExactInt.ZERO
        val seeded=listOf(z,ExactInt.of(101L),ExactInt.of(211L),
            ExactInt.of(307L),ExactInt.of(401L),
            ExactInt.of(503L),ExactInt.of(607L))
        val special=listOf(
            seeded,
            listOf(z,ExactInt.ONE,ExactInt.ONE,ExactInt.ONE,
                ExactInt.ONE,ExactInt.ONE,ExactInt.ONE),
            listOf(z)+List(6){id->ExactInt.parse(
                "12345678901234567890123456789012345678901234567890")+
                    ExactInt.of(id.toLong())},
            listOf(z)+List(6){id->ExactInt.parse(
                "-98765432109876543210987654321098765432109876543210")-
                    ExactInt.of(id.toLong())}
        )
        for((i,initial) in special.withIndex()){
            val run=adapter.oldCachedPostStir12(initial)
            val norm=NormativeCore.postStir12(initial.toTypedArray()).toList()
            insist("E_DISCOVERY11_SPECIAL_$i",
                run.steps.size==12 &&
                run.steps[0].newBowls==mixingWithSum(
                    initial,1,savedFresh(initial,1)).second &&
                run.steps[1].savedSumUsed==run.steps[0].savedSumUsed &&
                run.steps[1].oldSnapshot==run.steps[0].newBowls &&
                run.finalBowls!=norm)
        }
        println("STAGE22_SIGNED_AND_HUGE_INPUTS_PASS")

        insist("E_DISCOVERY11_REJECT_LEN",try{
            adapter.oldCachedPostStir12(seeded.drop(1));false
        }catch(e:IllegalArgumentException){
            e.message=="E_DISCOVERY11_INITIAL_BOWL_SHAPE"
        })
        insist("E_DISCOVERY11_REJECT_SENTINEL",try{
            adapter.oldCachedPostStir12(listOf(ExactInt.ONE)+seeded.drop(1))
            false
        }catch(e:IllegalArgumentException){
            e.message=="E_DISCOVERY11_INITIAL_BOWL_SHAPE"
        })
        println("STAGE22_INPUT_GUARDS_PASS")

        val f=NormativeCore.FOUNDATION_DAY
        val manager=MonsterBootstrapManager()
        val context=manager.observeLegacyCachedStir(f,f,seeded)
        val steps=context.discovery11Steps ?: error("E_DISCOVERY11_NO_STEPS")
        val expected=adapter.oldCachedPostStir12(seeded)
        insist("E_DISCOVERY11_PRODUCTION",
            context.phase=="DISCOVERY_11" &&
            context.status=="LEGACY_CACHED_STIR_OBSERVED" &&
            context.branchTrace==listOf("BOOT","DISCOVERY_11") &&
            context.diagnostics==listOf(
                "DISCOVERY_11_STALE_STIR1_SAVED_BOWL_SUM") &&
            context.discovery11InitialBowls==seeded &&
            context.discovery11FinalBowls==expected.finalBowls &&
            context.discovery11CachedSum==expected.originalCachedSum &&
            context.discovery11CacheComputations==1 &&
            context.discovery11PermutationPatchCalls==12 &&
            context.discovery11InvocationCount==1 &&
            steps.size==12 &&
            steps[0].newBowls==expected.steps[0].newBowls)
        println("STAGE22_PRODUCTION_12_CACHED_PASS")
        val counts=manager.metrics.snapshot()
        val trace=context.branchTrace.toList()
        val diag=context.diagnostics.toList()
        insist("E_DISCOVERY11_METRIC",
            counts["discovery11.cached.poststir.runs"]==1L)
        insist("E_DISCOVERY11_REPLAY",
            machine{manager.dispatcher.dispatch(context)}==
                "E_DISCOVERY11_CONTEXT_NOT_READY" &&
            context.discovery11Steps===steps &&
            context.discovery11InvocationCount==1 &&
            context.branchTrace==trace && context.diagnostics==diag &&
            manager.metrics.snapshot()==counts)
        val unbooted=BaseMonsterContext(f,f,phase="DISCOVERY_11",
            discovery11InitialBowls=seeded)
        val noInitial=BaseMonsterContext(f,f,phase="DISCOVERY_11",
            status="READY")
        insist("E_DISCOVERY11_GUARDS",
            machine{manager.dispatcher.dispatch(unbooted)}==
                "E_DISCOVERY11_CONTEXT_NOT_READY" &&
            machine{manager.dispatcher.dispatch(noInitial)}==
                "E_DISCOVERY11_NO_INITIAL" &&
            unbooted.discovery11Steps==null &&
            noInitial.discovery11Steps==null &&
            manager.metrics.snapshot()==counts)
        val another=manager.observeLegacyCachedStir(f-123L,f+456L,special[2])
        insist("E_DISCOVERY11_OWNERSHIP",
            another!==context && another.discovery11Steps!==steps &&
            another.discovery11FinalBowls!=context.discovery11FinalBowls &&
            context.discovery11Steps===steps &&
            steps[0].oldSnapshot==seeded)
        println("STAGE22_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE22_CONTEXT_OWNERSHIP_PASS")

        val drops=listOf(z)+List(46){ExactInt.of(720L)}
        val oldBowls=manager.observeLegacyInPlaceBowls(f,f,seeded,drops)
        val fixed=manager.applyBowlSnapshotPatch(f,f,seeded,drops)
        val normativeDrops=NormativeCore.applyVisibleDropsToBowls(
            seeded.toTypedArray(),drops.toTypedArray()).first.toList()
        insist("E_DISCOVERY11_PREVIOUS",
            oldBowls.discovery10FinalBowls!=normativeDrops &&
            fixed.patch10FinalBowls==normativeDrops &&
            fixed.patch10CorrectedSnapshotCalls==46 &&
            fixed.patch10LegacyMutatorCalls==46)
        println("STAGE22_EARLIER_ROUTES_PASS")
        println("STAGE22_NATIVE_EXPECTED_RED_COMPLETE")
    }
}
