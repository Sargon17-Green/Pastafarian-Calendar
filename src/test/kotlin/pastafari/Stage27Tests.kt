package pastafari

/** Cam 27 — PATCH 13: unrank1 a rejection, gyda graith rank0. */
object Stage27Tests {
    private fun insist(code:String,ok:Boolean){check(ok){code}}
    private fun machine(block:()->Unit):String=try{
        block();"NO_ERROR"
    }catch(e:MonsterValidationException){e.machineCode}

    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_PATCH13_ARGS"}
        val patch=GateGapRankPatchWrapper()
        val m=NormativeCore.M
        val n=ExactInt.of(922L)
        val upper=(m/n)*n
        var corrected=0;var legacyRed=0
        var positive=0;var negative=0
        for(i in 1..922)for(sign in listOf(1,-1)){
            val first=ExactInt.of(i.toLong())
            val index=ExactInt.of((i*sign).toLong())
            val outcome=patch.patch(index,first,sign)
            val stream=NormativeCore.AnswerStream(first,sign)
            val trueRank=NormativeCore.chooseRankInt(stream,922)
            insist("E_PATCH13_SHORT_$i-$sign",
                outcome.gateIndex==index &&
                outcome.streamFirst==first &&
                outcome.directionStep==sign &&
                outcome.acceptedAnswer==first &&
                outcome.acceptedAnswerIndex0==0 &&
                outcome.rejectedCandidates.isEmpty() &&
                outcome.correctedRank1==trueRank &&
                outcome.correctedRank1==i &&
                outcome.correctedGateGap==41+trueRank &&
                outcome.legacyRead.rank0Wrong==i-1 &&
                outcome.legacyRead.gateGapWrong==outcome.correctedGateGap-1 &&
                outcome.legacyRead.oneShotReads==1 &&
                outcome.legacyRead.rejectedCandidatesProcessed==0 &&
                outcome.legacyRank0Calls==1 &&
                outcome.correctedRankCalls==1 &&
                outcome.acceptedAnswerReads==1 &&
                outcome.rejectionChecks==1 &&
                outcome.seal==1)
            corrected++;legacyRed++
            if(sign==1)positive++ else negative++
        }
        insist("E_PATCH13_SHORT_TOTALS",corrected==1844 &&
            legacyRed==1844 && positive==922 && negative==922)
        println("STAGE27_SHORT_CORRECTED_GREEN_1844")
        println("STAGE27_SHORT_PRESERVED_LEGACY_RED_1844")
        println("STAGE27_POSITIVE_922_NEGATIVE_922_GREEN")
        println("STAGE27_CORRECT_LOW_42_HIGH_963")

        val cases=listOf(upper,upper+1L,upper+2L,m)
        var rejectedAtStart=0;var boundaryGreen=0
        var boundaryLegacyRed=0;var boundaryLegacyMatch=0
        var totalRejected=0;var maxRejections=0
        for(first in cases)for(sign in listOf(1,-1)){
            val index=ExactInt.of((sign*13).toLong())
            val outcome=patch.patch(index,first,sign)
            val stream=NormativeCore.AnswerStream(first,sign)
            val expectedRank=NormativeCore.chooseRankInt(stream,922)
            val accepted=NormativeCore.answerAt(
                stream,outcome.acceptedAnswerIndex0)
            insist("E_PATCH13_BOUNDARY_$first-$sign",
                outcome.correctedRank1==expectedRank &&
                outcome.correctedGateGap==41+expectedRank &&
                outcome.acceptedAnswer==accepted &&
                outcome.acceptedAnswer<=upper &&
                outcome.rejectedCandidates.size==
                    outcome.acceptedAnswerIndex0 &&
                outcome.acceptedAnswerReads==
                    outcome.acceptedAnswerIndex0+1 &&
                outcome.rejectionChecks==outcome.acceptedAnswerReads &&
                outcome.legacyRead.gateGapWrong==
                    41+(first-ExactInt.ONE).euclideanMod(n).toIntExact())
            for(k in outcome.rejectedCandidates.indices){
                insist("E_PATCH13_REJECTED_VALUE_$first-$sign-$k",
                    outcome.rejectedCandidates[k]==NormativeCore.answerAt(stream,k) &&
                    outcome.rejectedCandidates[k]>upper)
            }
            if(first>upper){
                insist("E_PATCH13_AT_LEAST_ONE_REJECTED",outcome.acceptedAnswerIndex0>0)
                rejectedAtStart++
            } else {
                insist("E_PATCH13_ZERO_REJECTED",outcome.acceptedAnswerIndex0==0)
            }
            totalRejected+=outcome.rejectedCandidates.size
            maxRejections=maxOf(maxRejections,outcome.acceptedAnswerIndex0)
            if(outcome.correctedGateGap==outcome.legacyRead.gateGapWrong)
                boundaryLegacyMatch++ else boundaryLegacyRed++
            boundaryGreen++
        }
        insist("E_PATCH13_BOUNDARY_COUNTS",
            boundaryGreen==8 && rejectedAtStart==6 &&
            boundaryLegacyRed==7 && boundaryLegacyMatch==1 &&
            totalRejected>6 && maxRejections>=221)
        println("STAGE27_REJECTION_BOUNDARY_GREEN_8")
        println("STAGE27_REJECTION_STARTS_6")
        println("STAGE27_PRESERVED_BOUNDARY_LEGACY_RED_7")
        println("STAGE27_PRESERVED_BOUNDARY_INCIDENTAL_MATCH_1")
        println("STAGE27_REJECTED_ANSWER_SEQUENCE_VERIFIED_8")
        println("STAGE27_WRAPAROUND_AND_LONG_REJECTION_PASS")

        val f=NormativeCore.FOUNDATION_DAY
        val manager=MonsterBootstrapManager()
        for(sign in listOf(1,-1)){
            val sauce=NormativeCore.sauce(f,f+sign.toLong())
            val stream=NormativeCore.askBowl(
                sauce,1,NormativeCore.SEAL_GATE_GAP)
            val result=patch.patch(ExactInt.of(sign.toLong()),
                stream.first,stream.directionStep)
            val expected=41+NormativeCore.chooseRankInt(stream,922)
            val produced=manager.applyGateGapRankPatch(
                f,f+sign.toLong(),ExactInt.of(sign.toLong()),
                stream.first,stream.directionStep)
            insist("E_PATCH13_NATURAL_$sign",
                result.correctedGateGap==expected &&
                produced.patch13CorrectedGateGap==expected &&
                produced.patch13Outcome?.legacyRead?.gateGapWrong==
                    result.legacyRead.gateGapWrong)
        }
        println("STAGE27_POSITIVE_NEGATIVE_NATURAL_SAUCE_GREEN")

        val legacy=LegacyGateGapRankAdapter()
        for(index in listOf(ExactInt.ZERO)){
            insist("E_PATCH13_ZERO_INDEX",try{
                patch.patch(index,ExactInt.ONE,1);false
            }catch(e:IllegalArgumentException){
                e.message=="E_DISCOVERY13_ZERO_GATE_INDEX"
            })
        }
        for(first in listOf(ExactInt.ZERO,m+1L)){
            insist("E_PATCH13_FIRST_GUARD",try{
                patch.patch(ExactInt.ONE,first,1);false
            }catch(e:IllegalArgumentException){
                e.message=="E_DISCOVERY13_STREAM_RANGE"
            })
        }
        for(step in listOf(0,2,-2)){
            insist("E_PATCH13_STEP_GUARD",try{
                patch.patch(ExactInt.ONE,ExactInt.ONE,step);false
            }catch(e:IllegalArgumentException){
                e.message=="E_DISCOVERY13_DIRECTION_STEP"
            })
        }
        println("STAGE27_INPUT_GUARDS_PASS")

        val context=manager.applyGateGapRankPatch(
            f,f,ExactInt.of(-19L),m,-1)
        val scar=context.patch13Outcome?:error("E_PATCH13_CONTEXT_NO_OUTCOME")
        val ref=patch.patch(ExactInt.of(-19L),m,-1)
        insist("E_PATCH13_PRODUCTION",
            context.phase=="PATCH_13" &&
            context.status=="PATCHED_GATE_GAP_RANK1" &&
            context.branchTrace==listOf("BOOT","PATCH_13") &&
            context.diagnostics==
                listOf("PATCH_13_UNRANK1_AND_REJECTION") &&
            context.patch13GateIndex==ExactInt.of(-19L) &&
            context.patch13StreamFirst==m &&
            context.patch13DirectionStep==-1 &&
            context.patch13CorrectedRank1==ref.correctedRank1 &&
            context.patch13CorrectedGateGap==ref.correctedGateGap &&
            context.patch13AcceptedAnswer==ref.acceptedAnswer &&
            context.patch13RejectedCandidates==ref.rejectedCandidates &&
            context.patch13LegacyRank0Calls==1 &&
            context.patch13CorrectedRankCalls==1 &&
            context.patch13AcceptedAnswerReads==ref.acceptedAnswerReads &&
            context.patch13RejectionChecks==ref.rejectionChecks &&
            context.patch13Applied &&
            context.patch13InvocationCount==1 &&
            scar.legacyRead.gateGapWrong==ref.legacyRead.gateGapWrong)
        val metrics=manager.metrics.snapshot()
        insist("E_PATCH13_METRICS",
            metrics["patch13.legacy.gate.gap.calls"]==3L &&
            metrics["patch13.corrected.gate.gap.calls"]==3L &&
            metrics["patch13.applied"]==3L)
        println("STAGE27_PRODUCTION_REJECTION_TRACE_GREEN")

        val trace=context.branchTrace.toList()
        val diag=context.diagnostics.toList()
        insist("E_PATCH13_REPLAY",
            machine{manager.dispatcher.dispatch(context)}==
                "E_PATCH13_CONTEXT_NOT_READY" &&
            context.patch13Outcome===scar &&
            context.patch13InvocationCount==1 &&
            context.branchTrace==trace &&
            context.diagnostics==diag &&
            manager.metrics.snapshot()==metrics)
        val unbooted=BaseMonsterContext(f,f,phase="PATCH_13",
            patch13GateIndex=ExactInt.ONE,
            patch13StreamFirst=ExactInt.ONE,patch13DirectionStep=1)
        val noIndex=BaseMonsterContext(f,f,phase="PATCH_13",
            status="READY",patch13StreamFirst=ExactInt.ONE,
            patch13DirectionStep=1)
        val noFirst=BaseMonsterContext(f,f,phase="PATCH_13",
            status="READY",patch13GateIndex=ExactInt.ONE,
            patch13DirectionStep=1)
        val noStep=BaseMonsterContext(f,f,phase="PATCH_13",
            status="READY",patch13GateIndex=ExactInt.ONE,
            patch13StreamFirst=ExactInt.ONE)
        insist("E_PATCH13_GUARDS",
            machine{manager.dispatcher.dispatch(unbooted)}==
                "E_PATCH13_CONTEXT_NOT_READY" &&
            machine{manager.dispatcher.dispatch(noIndex)}==
                "E_PATCH13_NO_INDEX" &&
            machine{manager.dispatcher.dispatch(noFirst)}==
                "E_PATCH13_NO_FIRST" &&
            machine{manager.dispatcher.dispatch(noStep)}==
                "E_PATCH13_NO_DIRECTION" &&
            listOf(unbooted,noIndex,noFirst,noStep).all{
                it.patch13Outcome==null && !it.patch13Applied &&
                it.patch13InvocationCount==0
            } && manager.metrics.snapshot()==metrics)
        val another=manager.applyGateGapRankPatch(
            f-45L,f+57L,ExactInt.of(61L),ExactInt.ONE,1)
        insist("E_PATCH13_OWNERSHIP",
            another!==context &&
            another.patch13Outcome!==scar &&
            another.patch13CorrectedGateGap==42 &&
            another.patch13Outcome?.rejectedCandidates?.isEmpty()==true &&
            context.patch13Outcome===scar &&
            context.patch13RejectedCandidates==ref.rejectedCandidates)
        println("STAGE27_BOOT_REPLAY_GUARDS_PASS")
        println("STAGE27_CONTEXT_OWNERSHIP_PASS")

        val prior=manager.observeLegacyGateGapRank(
            f,f,ExactInt.of(-19L),m,-1)
        insist("E_PATCH13_OLD_ROUTE",
            prior.discovery13WrongGap==ref.legacyRead.gateGapWrong &&
            prior.discovery13WrongGap!=ref.correctedGateGap &&
            prior.discovery13RejectedCandidatesProcessed==0)
        val bowls=listOf(0L,101L,211L,307L,401L,503L,607L)
            .map(ExactInt::of)
        val neighbor=manager.applyPositionalNeighborPatch(
            f,f,bowls,ExactInt.of(720L),6,31)
        insist("E_PATCH13_PREVIOUS_ROUTES",
            neighbor.patch12CorrectedNeighborId==5 &&
            neighbor.patch12CorrectedFirstAnswer!=
                neighbor.patch12Outcome?.legacyRead?.firstAnswer)
        println("STAGE27_EARLIER_ROUTES_PASS")
        println("STAGE27_NATIVE_GREEN")
    }
}
