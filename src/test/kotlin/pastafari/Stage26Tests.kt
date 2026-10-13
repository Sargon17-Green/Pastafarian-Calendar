package pastafari

/** Cam 26 — DISCOVERY 13: unrank1 gap 922 a gwrthod. */
object Stage26Tests {
    private fun insist(code:String,ok:Boolean){check(ok){code}}
    private fun machine(action:()->Unit):String=try{
        action();"NO_ERROR"
    }catch(e:MonsterValidationException){e.machineCode}

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY13_ARGS"}
        val legacy=LegacyGateGapRankAdapter()
        var wrong=0;var positive=0;var negative=0
        for(n in 1..922)for(sign in listOf(1,-1)){
            val first=ExactInt.of(n.toLong())
            val index=ExactInt.of((n*sign).toLong())
            val record=legacy.oldGateGapWithoutRank1(index,first,sign)
            val rank=NormativeCore.chooseRankInt(
                NormativeCore.AnswerStream(first,sign),922)
            val correct=41+rank
            insist("E_DISCOVERY13_RANK0_$n-$sign",
                record.gateIndex==index && record.streamFirst==first &&
                record.streamDirectionStep==sign && record.seal==1 &&
                record.oneShotReads==1 &&
                record.rejectedCandidatesProcessed==0 &&
                record.rank0Wrong==n-1 &&
                record.gateGapWrong==41+n-1 &&
                correct==42+n-1 &&
                record.gateGapWrong!=correct &&
                record.gateGapWrong in 41..962 &&
                correct in 42..963)
            wrong++
            if(sign==1)positive++ else negative++
        }
        insist("E_DISCOVERY13_CARDINALITY",
            wrong==1844 && positive==922 && negative==922)
        println("STAGE26_POSITIVE_EXPECTED_RED_922")
        println("STAGE26_NEGATIVE_EXPECTED_RED_922")
        println("STAGE26_TOTAL_ONE_BASED_GAP_RED_1844")
        println("STAGE26_LEGACY_ILLEGAL_LOW_41_CONFIRMED")
        println("STAGE26_NORMATIVE_MAX_963_CONFIRMED")

        val m=NormativeCore.M
        val n=ExactInt.of(922L)
        val lastAccepted=(m/n)*n
        val samples=listOf(
            lastAccepted, lastAccepted+1L,
            lastAccepted+2L, m)
        var rejectionSamples=0;var boundaryRed=0;var incidental=0
        var selectedRejects=0
        for(first in samples)for(direction in listOf(1,-1)){
            val record=legacy.oldGateGapWithoutRank1(
                ExactInt.of((direction*5).toLong()),first,direction)
            val stream=NormativeCore.AnswerStream(first,direction)
            val correct=41+NormativeCore.chooseRankInt(stream,922)
            val expectedRank0=(first-ExactInt.ONE).euclideanMod(n).toIntExact()
            insist("E_DISCOVERY13_BOUNDARY_FORMULA",
                record.rank0Wrong==expectedRank0 &&
                record.gateGapWrong==41+expectedRank0 &&
                record.oneShotReads==1 &&
                record.rejectedCandidatesProcessed==0 &&
                correct in 42..963)
            if(first>lastAccepted){
                rejectionSamples++
                selectedRejects++
            }
            if(record.gateGapWrong==correct)incidental++ else boundaryRed++
        }
        insist("E_DISCOVERY13_BOUNDARY_COUNTS",
            lastAccepted==m-221L &&
            rejectionSamples==6 &&
            boundaryRed==7 && incidental==1 &&
            selectedRejects==6)
        println("STAGE26_REJECTION_BOUNDARY_TESTS_8")
        println("STAGE26_REJECTION_BOUNDARY_RED_7")
        println("STAGE26_REJECTION_BOUNDARY_INCIDENTAL_MATCH_1")
        println("STAGE26_IGNORED_REJECTION_CANDIDATES_6")

        val f=NormativeCore.FOUNDATION_DAY
        var naturalCases=0
        for((gateSign,offset)in listOf(1 to 1,-1 to 1)){
            val target=f+ExactInt.of((gateSign*offset).toLong())
            val sauce=NormativeCore.sauce(f,target)
            val stream=NormativeCore.askBowl(
                sauce,1,NormativeCore.SEAL_GATE_GAP)
            val correct=41+NormativeCore.chooseRankInt(stream,922)
            val record=legacy.oldGateGapWithoutRank1(
                ExactInt.of((gateSign*offset).toLong()),
                stream.first,stream.directionStep)
            insist("E_DISCOVERY13_NATURAL_$gateSign",
                record.streamFirst==stream.first &&
                record.streamDirectionStep==stream.directionStep &&
                record.gateGapWrong==41+
                    (stream.first-ExactInt.ONE).euclideanMod(n).toIntExact() &&
                record.gateGapWrong!=correct && correct in 42..963)
            naturalCases++
        }
        insist("E_DISCOVERY13_NATURAL_COUNT",naturalCases==2)
        println("STAGE26_POSITIVE_NEGATIVE_NATURAL_SAUCE_PASS")

        val one=ExactInt.ONE
        insist("E_DISCOVERY13_ZERO_INDEX",try{
            legacy.oldGateGapWithoutRank1(ExactInt.ZERO,one,1);false
        }catch(e:IllegalArgumentException){
            e.message=="E_DISCOVERY13_ZERO_GATE_INDEX"
        })
        for(first in listOf(ExactInt.ZERO,m+1L)){
            insist("E_DISCOVERY13_FIRST_RANGE",try{
                legacy.oldGateGapWithoutRank1(one,first,1);false
            }catch(e:IllegalArgumentException){
                e.message=="E_DISCOVERY13_STREAM_RANGE"
            })
        }
        for(step in listOf(0,2,-2)){
            insist("E_DISCOVERY13_STEP_RANGE",try{
                legacy.oldGateGapWithoutRank1(one,one,step);false
            }catch(e:IllegalArgumentException){
                e.message=="E_DISCOVERY13_DIRECTION_STEP"
            })
        }
        println("STAGE26_INPUT_GUARDS_PASS")

        val manager=MonsterBootstrapManager()
        val context=manager.observeLegacyGateGapRank(f,f,
            ExactInt.of(-12L),ExactInt.of(922L),-1)
        val scar=context.discovery13LegacyRead
            ?:error("E_DISCOVERY13_NO_SCAR")
        insist("E_DISCOVERY13_PRODUCTION",
            context.phase=="DISCOVERY_13" &&
            context.status=="LEGACY_GATE_GAP_RANK0_OBSERVED" &&
            context.branchTrace==listOf("BOOT","DISCOVERY_13") &&
            context.diagnostics==
                listOf("DISCOVERY_13_GATE_GAP_RANK0_NO_REJECTION") &&
            context.discovery13GateIndex==ExactInt.of(-12L) &&
            context.discovery13StreamFirst==ExactInt.of(922L) &&
            context.discovery13DirectionStep==-1 &&
            context.discovery13WrongGap==962 &&
            context.discovery13OneShotReads==1 &&
            context.discovery13RejectedCandidatesProcessed==0 &&
            context.discovery13InvocationCount==1 &&
            scar==legacy.oldGateGapWithoutRank1(
                ExactInt.of(-12L),ExactInt.of(922L),-1))
        val metrics=manager.metrics.snapshot()
        insist("E_DISCOVERY13_METRIC",
            metrics["discovery13.gate.gap.rank0.calls"]==1L)
        println("STAGE26_PRODUCTION_GATE_GAP_SCAR_PASS")

        val trace=context.branchTrace.toList()
        val diagnostics=context.diagnostics.toList()
        insist("E_DISCOVERY13_REPLAY",
            machine{manager.dispatcher.dispatch(context)}==
                "E_DISCOVERY13_CONTEXT_NOT_READY" &&
            context.discovery13LegacyRead===scar &&
            context.discovery13InvocationCount==1 &&
            context.branchTrace==trace &&
            context.diagnostics==diagnostics &&
            manager.metrics.snapshot()==metrics)
        val unbooted=BaseMonsterContext(f,f,phase="DISCOVERY_13",
            discovery13GateIndex=one,
            discovery13StreamFirst=one,discovery13DirectionStep=1)
        val noIndex=BaseMonsterContext(f,f,phase="DISCOVERY_13",
            status="READY",discovery13StreamFirst=one,
            discovery13DirectionStep=1)
        val noFirst=BaseMonsterContext(f,f,phase="DISCOVERY_13",
            status="READY",discovery13GateIndex=one,
            discovery13DirectionStep=1)
        val noStep=BaseMonsterContext(f,f,phase="DISCOVERY_13",
            status="READY",discovery13GateIndex=one,
            discovery13StreamFirst=one)
        insist("E_DISCOVERY13_GUARDS",
            machine{manager.dispatcher.dispatch(unbooted)}==
                "E_DISCOVERY13_CONTEXT_NOT_READY" &&
            machine{manager.dispatcher.dispatch(noIndex)}==
                "E_DISCOVERY13_NO_INDEX" &&
            machine{manager.dispatcher.dispatch(noFirst)}==
                "E_DISCOVERY13_NO_FIRST" &&
            machine{manager.dispatcher.dispatch(noStep)}==
                "E_DISCOVERY13_NO_DIRECTION" &&
            listOf(unbooted,noIndex,noFirst,noStep).all {
                it.discovery13LegacyRead==null &&
                it.discovery13InvocationCount==0
            } && manager.metrics.snapshot()==metrics)
        val different=manager.observeLegacyGateGapRank(
            f-17L,f+29L,ExactInt.of(71L),ExactInt.ONE,1)
        insist("E_DISCOVERY13_OWNERSHIP",
            different!==context &&
            different.discovery13LegacyRead!==scar &&
            different.discovery13WrongGap==41 &&
            context.discovery13LegacyRead===scar)
        println("STAGE26_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE26_CONTEXT_OWNERSHIP_PASS")

        val bowls=listOf(0L,101L,211L,307L,401L,503L,607L)
            .map(ExactInt::of)
        val corrected=manager.applyPositionalNeighborPatch(
            f,f,bowls,ExactInt.of(720L),6,31)
        val historical=manager.observeLegacyNumericNeighbor(
            f,f,bowls,ExactInt.of(720L),6,31)
        insist("E_DISCOVERY13_PRIOR_ROUTE",
            corrected.patch12CorrectedNeighborId==5 &&
            historical.discovery12ActualNumericNeighbor==1 &&
            corrected.patch12CorrectedFirstAnswer!=
                historical.discovery12FirstAnswer)
        println("STAGE26_EARLIER_ROUTES_PASS")
        println("STAGE26_NATIVE_EXPECTED_RED_COMPLETE")
    }
}
