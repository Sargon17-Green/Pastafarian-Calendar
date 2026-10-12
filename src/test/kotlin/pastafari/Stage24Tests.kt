package pastafari

/** Cam 24: DISCOVERY 12 — cymydog rhifol anghywir. */
object Stage24Tests {
    private fun insist(code: String, good: Boolean) { check(good) { code } }
    private fun errorCode(block: () -> Unit): String = try {
        block(); "NO_ERROR"
    } catch (e: MonsterValidationException) { e.machineCode }
    private val bowls=listOf(ExactInt.ZERO,ExactInt.of(101L),
        ExactInt.of(211L),ExactInt.of(307L),ExactInt.of(401L),
        ExactInt.of(503L),ExactInt.of(607L))

    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY12_ARGS" }
        val adapter=LegacyNumericNeighborAdapter()
        var legacyRed=0;var coincidentGreen=0
        var allSixMatch=0;var allSixMismatch=0
        var wrongSeals=0;var correctPositional=0
        for(ordinal in 1..720){
            val drop=ExactInt.of(ordinal.toLong())
            val order=NormativeCore.bowlOrderFromDrop(drop).toList()
            for(seal in listOf(21,31)){
                var matched=0
                for(queried in 1..6){
                    val reading=adapter.oldNumericNeighborQuestion(
                        bowls,drop,queried,seal)
                    val normative=NormativeCore.askBowl(
                        NormativeCore.SauceResult(bowls.toTypedArray(),
                            order.toIntArray()),queried,seal)
                    val next=order[(order.indexOf(queried)+1)%6]
                    val numeric=if(queried==6)1 else queried+1
                    insist("E_DISCOVERY12_SHAPE_$ordinal-$queried-$seal",
                        reading.drop46==drop &&
                        reading.seal==seal &&
                        reading.queriedBowlId==queried &&
                        reading.drop46Order==order &&
                        reading.actualNeighborIdWrong==numeric &&
                        reading.positionalNeighborIdExpected==next &&
                        reading.permutationPatchCalls==1 &&
                        reading.numericNeighborCalls==1 &&
                        reading.directionStep in listOf(-1,1))
                    val base=bowls[queried]+seal.toLong()+181L
                    val wrongFirst=NormativeCore.save(
                        base.square()+bowls[numeric].multiplyByInt(179)+
                        seal.toLong())
                    val directionBase=wrongFirst+seal.toLong()+1L+193L
                    val direction=NormativeCore.save(
                        directionBase.square()+
                        wrongFirst.multiplyByInt(193)+
                        bowls[6].multiplyByInt(197))
                    insist("E_DISCOVERY12_ONLY_NEIGHBOR_$ordinal-$queried-$seal",
                        reading.firstAnswer==wrongFirst &&
                        reading.directionNumber==direction &&
                        reading.directionStep==
                            (if(direction.modInt(2)==1)1 else -1))
                    if(next==numeric){
                        insist("E_DISCOVERY12_INCIDENTAL_MATCH_$ordinal",
                            reading.firstAnswer==normative.first &&
                            reading.directionStep==normative.directionStep)
                        coincidentGreen++;matched++;correctPositional++
                    }else{
                        insist("E_DISCOVERY12_NUMERIC_RED_$ordinal",
                            reading.firstAnswer!=normative.first)
                        legacyRed++;wrongSeals++
                    }
                }
                if(matched==6)allSixMatch++ else allSixMismatch++
            }
        }
        insist("E_DISCOVERY12_720_COUNTS",
            legacyRed==6912 && coincidentGreen==1728 &&
            allSixMatch==12 && allSixMismatch==1428 &&
            correctPositional==1728 && wrongSeals==6912)
        println("STAGE24_8640_NUMERIC_QUERIES_VERIFIED")
        println("STAGE24_EXPECTED_RED_6912")
        println("STAGE24_INCIDENTAL_MATCH_1728")
        println("STAGE24_ALL_SIX_NUMERIC_CYCLES_12")
        println("STAGE24_NONCYCLIC_ORDER_SEAL_PAIRS_1428")
        println("STAGE24_FIRST_AND_DIRECTION_FORMULA_PASS")

        val reverse=adapter.oldNumericNeighborQuestion(
            bowls,ExactInt.of(720L),6,31)
        insist("E_DISCOVERY12_WRAP_AND_REVERSE",
            reverse.drop46Order==listOf(6,5,4,3,2,1) &&
            reverse.queriedBowlId==6 &&
            reverse.actualNeighborIdWrong==1 &&
            reverse.positionalNeighborIdExpected==5 &&
            reverse.firstAnswer!=NormativeCore.askBowl(
                NormativeCore.SauceResult(bowls.toTypedArray(),
                    intArrayOf(6,5,4,3,2,1)),6,31).first)
        println("STAGE24_REVERSE_AND_WRAPAROUND_RED_PASS")

        for(invalid in listOf(0,7)){
            insist("E_DISCOVERY12_QUERY_GUARD_$invalid",try {
                adapter.oldNumericNeighborQuestion(bowls,ExactInt.ONE,invalid,21)
                false
            }catch(e:IllegalArgumentException) {
                e.message=="E_DISCOVERY12_QUERY_BOWL_RANGE"
            })
        }
        insist("E_DISCOVERY12_BOWL_SHAPE",try {
            adapter.oldNumericNeighborQuestion(bowls.drop(1),ExactInt.ONE,1,21)
            false
        }catch(e:IllegalArgumentException) {
            e.message=="E_DISCOVERY12_FINAL_BOWL_SHAPE"
        })
        insist("E_DISCOVERY12_BOWL_SENTINEL",try {
            adapter.oldNumericNeighborQuestion(
                listOf(ExactInt.ONE)+bowls.drop(1),ExactInt.ONE,1,21)
            false
        }catch(e:IllegalArgumentException) {
            e.message=="E_DISCOVERY12_FINAL_BOWL_SHAPE"
        })
        insist("E_DISCOVERY12_SEAL_GUARD",try {
            adapter.oldNumericNeighborQuestion(bowls,ExactInt.ONE,1,0)
            false
        }catch(e:IllegalArgumentException) {
            e.message=="E_DISCOVERY12_SEAL_RANGE"
        })
        println("STAGE24_INPUT_GUARDS_PASS")

        // BOOT → DISCOVERY_12: mae'r source final bowls wedi'i gywiro o'r blaen.
        val f=NormativeCore.FOUNDATION_DAY
        val manager=MonsterBootstrapManager()
        val ctx=manager.observeLegacyNumericNeighbor(
            f,f,bowls,ExactInt.of(720L),6,31)
        val read=ctx.discovery12Read?:error("E_DISCOVERY12_CONTEXT_NO_READ")
        insist("E_DISCOVERY12_PRODUCTION",
            ctx.phase=="DISCOVERY_12" &&
            ctx.status=="LEGACY_NUMERIC_NEIGHBOR_OBSERVED" &&
            ctx.branchTrace==listOf("BOOT","DISCOVERY_12") &&
            ctx.diagnostics==listOf(
                "DISCOVERY_12_NUMERIC_ID_NOT_DROP46_NEXT") &&
            ctx.discovery12FinalBowls==bowls &&
            ctx.discovery12Drop46==ExactInt.of(720L) &&
            ctx.discovery12QueryBowl==6 &&
            ctx.discovery12Seal==31 &&
            ctx.discovery12ActualNumericNeighbor==1 &&
            ctx.discovery12ExpectedPositionalNeighbor==5 &&
            ctx.discovery12FirstAnswer==reverse.firstAnswer &&
            ctx.discovery12DirectionStep==reverse.directionStep &&
            ctx.discovery12PermutationCalls==1 &&
            ctx.discovery12NumericNeighborCalls==1 &&
            ctx.discovery12InvocationCount==1 &&
            read.drop46Order==listOf(6,5,4,3,2,1))
        println("STAGE24_PRODUCTION_NUMERIC_SCAR_PASS")

        val metrics=manager.metrics.snapshot()
        val trace=ctx.branchTrace.toList()
        val diagnostics=ctx.diagnostics.toList()
        insist("E_DISCOVERY12_METRIC",
            metrics["discovery12.numeric.neighbor.calls"]==1L)
        insist("E_DISCOVERY12_REPLAY",
            errorCode{manager.dispatcher.dispatch(ctx)}==
                "E_DISCOVERY12_CONTEXT_NOT_READY" &&
            ctx.discovery12Read===read &&
            ctx.discovery12InvocationCount==1 &&
            ctx.branchTrace==trace &&
            ctx.diagnostics==diagnostics &&
            manager.metrics.snapshot()==metrics)
        val unbooted=BaseMonsterContext(f,f,phase="DISCOVERY_12",
            discovery12FinalBowls=bowls,
            discovery12Drop46=ExactInt.ONE,
            discovery12QueryBowl=1,
            discovery12Seal=21)
        insist("E_DISCOVERY12_BOOT",
            errorCode{manager.dispatcher.dispatch(unbooted)}==
                "E_DISCOVERY12_CONTEXT_NOT_READY" &&
            unbooted.discovery12Read==null &&
            unbooted.discovery12InvocationCount==0 &&
            manager.metrics.snapshot()==metrics)
        val noBowls=BaseMonsterContext(f,f,phase="DISCOVERY_12",
            status="READY",discovery12Drop46=ExactInt.ONE,
            discovery12QueryBowl=1,discovery12Seal=21)
        val noDrop=BaseMonsterContext(f,f,phase="DISCOVERY_12",
            status="READY",discovery12FinalBowls=bowls,
            discovery12QueryBowl=1,discovery12Seal=21)
        val noQuery=BaseMonsterContext(f,f,phase="DISCOVERY_12",
            status="READY",discovery12FinalBowls=bowls,
            discovery12Drop46=ExactInt.ONE,discovery12Seal=21)
        val noSeal=BaseMonsterContext(f,f,phase="DISCOVERY_12",
            status="READY",discovery12FinalBowls=bowls,
            discovery12Drop46=ExactInt.ONE,discovery12QueryBowl=1)
        insist("E_DISCOVERY12_MISSING_INPUTS",
            errorCode{manager.dispatcher.dispatch(noBowls)}==
                "E_DISCOVERY12_NO_BOWLS" &&
            errorCode{manager.dispatcher.dispatch(noDrop)}==
                "E_DISCOVERY12_NO_DROP46" &&
            errorCode{manager.dispatcher.dispatch(noQuery)}==
                "E_DISCOVERY12_NO_QUERY" &&
            errorCode{manager.dispatcher.dispatch(noSeal)}==
                "E_DISCOVERY12_NO_SEAL" &&
            listOf(noBowls,noDrop,noQuery,noSeal).all {
                it.discovery12Read==null && it.discovery12InvocationCount==0
            } && manager.metrics.snapshot()==metrics)
        println("STAGE24_BOOT_REPLAY_GUARDS_PASS")
        val other=manager.observeLegacyNumericNeighbor(
            f-123L,f+456L,bowls,ExactInt.ONE,1,21)
        insist("E_DISCOVERY12_OWNERSHIP",
            other!==ctx && other.discovery12Read!==read &&
            other.discovery12Read?.drop46Order==listOf(1,2,3,4,5,6) &&
            ctx.discovery12Read===read &&
            read.drop46Order==listOf(6,5,4,3,2,1))
        println("STAGE24_CONTEXT_OWNERSHIP_PASS")

        // Gwirio cysylltiad gwirioneddol â chynnyrch PATCH 10 a PATCH 11.
        val counts=NormativeCore.workCounts(f,f)
        val hidden=NormativeCore.buildHiddenDrops(counts)
        val visible=NormativeCore.buildVisibleDrops(
            counts,NormativeCore.STONES,hidden)
        val initial=NormativeCore.initialBowls(counts)
        val afterDrops=manager.applyBowlSnapshotPatch(
            f,f,initial.toList(),visible.toList())
        val afterStir=manager.applyFreshStirPatch(
            f,f,afterDrops.patch10FinalBowls?:error("E_DISCOVERY12_AFTER46"))
        val normativeSauce=NormativeCore.sauce(f,f)
        insist("E_DISCOVERY12_PREVIOUS_CORRECT",
            afterStir.patch11FinalBowls==normativeSauce.bowls.toList() &&
            afterDrops.patch10OrderAt46==normativeSauce.orderAtDrop46.toList())
        val natural=manager.observeLegacyNumericNeighbor(
            f,f,afterStir.patch11FinalBowls?:error("E_DISCOVERY12_AFTER12"),
            visible[46],1,21)
        val normNatural=NormativeCore.askBowl(normativeSauce,1,21)
        val neighbor=NormativeCore.nextBowlInDrop46Order(normativeSauce,1)
        insist("E_DISCOVERY12_NATURAL_INTEGRATION",
            natural.discovery12Read?.drop46Order==
                normativeSauce.orderAtDrop46.toList() &&
            natural.discovery12Read?.positionalNeighborIdExpected==neighbor &&
            (natural.discovery12FirstAnswer==normNatural.first)==
                (neighbor==2))
        println("STAGE24_NATURAL_SAUCE_INPUTS_PASS")
        println("STAGE24_EARLIER_ROUTES_PASS")
        println("STAGE24_NATIVE_EXPECTED_RED_COMPLETE")
    }
}
