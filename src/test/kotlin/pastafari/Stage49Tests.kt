package pastafari

/** Cam 49: prawf annibynnol ar samplu gyda gwrthodiad. */
object Stage49Tests {
    private fun must(code:String,p:Boolean){check(p){code}}
    private fun rejects(f:()->Unit){
        try{f()}catch(_:IllegalArgumentException){return}
        error("E_PATCH24_EXPECTED_GUARD")
    }
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val w=Year5000RejectionRankPatchWrapper()
        val manager=Year5000RejectionRankPatchManager()
        val historical=LegacyYear5000FirstAnswerModuloAdapter()
        val m=NormativeCore.M
        must("E_PATCH24_MODULUS_LOCK",
            LegacyYear5000FirstAnswerModuloAdapter.ANSWER_MODULUS==m)
        val calendar=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val all=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16){
            val g=ExactInt.of(i.toLong())
            val open=calendar.gates.get(g)
            for(width in 6..12){
                val end=g+width.toLong()
                all.add(Year5000TieCandidate(g,end,open,calendar.gates.get(end)))
            }
        }
        val eligible=all.filter { c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
                c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
                c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
                c.openGateDay<day && day<=c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy{it.openGateDay})
        must("E_PATCH24_REAL_INPUT", all.size==231 && eligible.isNotEmpty())
        val stream=NormativeCore.askBowl(
            NormativeCore.sauce(day,day),1,NormativeCore.SEAL_YEAR_5000)
        val chosen=w.patch(stream.first,stream.directionStep,eligible.size)
        must("E_PATCH24_REAL_RANK",
            chosen.correctedRank==NormativeCore.chooseRankInt(stream,eligible.size) &&
            chosen.legacyRank==historical.rankFromFirstAnswer(
                stream.first,eligible.size) &&
            chosen.correctionApplied==(chosen.correctedRank!=chosen.legacyRank) &&
            chosen.correctedRank in 1..eligible.size
        )
        val actualYear=calendar.year5000(day)
        must("E_PATCH24_REAL_FULL_CALENDAR",
            actualYear.openGateDay<day && day<=actualYear.closeGateDay)
        println("STAGE49_REAL_GATE_231_PAIRS_CANONICAL_RANK_GREEN")

        var red=0;var matches=0;var sessions=0
        var stored:Year5000RejectionRankPatchSession?=null
        for(i in 1..64){
            val n=i+1
            val divisor=ExactInt.of(n.toLong())
            val limit=(m/divisor)*divisor
            must("E_PATCH24_SYNTH_REMAINDER_$n",
                m.euclideanMod(divisor)>ExactInt.ZERO)
            val reject=w.patch(m,-1,n)
            val accepted=w.patch(limit,-1,n)
            val native=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,-1),divisor).toIntExact()
            val nativeAccepted=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(limit,-1),divisor).toIntExact()
            val session1=manager.apply(m,-1,n)
            val session2=manager.apply(limit,-1,n)
            must("E_PATCH24_SYNTH_RED_$n",
                reject.correctedRank==native &&
                reject.correctedRank==n &&
                reject.legacyRank!=native &&
                reject.correctionApplied &&
                reject.rejectedAnswers==m.euclideanMod(divisor).toIntExact() &&
                session1.outcome==reject)
            must("E_PATCH24_SYNTH_MATCH_$n",
                accepted.correctedRank==nativeAccepted &&
                accepted.legacyRank==nativeAccepted &&
                !accepted.correctionApplied &&
                accepted.rejectedAnswers==0 &&
                session2.outcome==accepted)
            must("E_PATCH24_SYNTH_MANAGER_$n",
                session1.branchTrace==listOf("BOOT","PATCH_24") &&
                session1.context.branchTrace==session1.branchTrace &&
                session1.context.status=="PATCHED_YEAR5000_REJECTION_RANK" &&
                session1.context.phase=="PATCH_24" &&
                session1.diagnostics==listOf("PATCH_24_REJECTION_SAMPLING") &&
                session1.applied && session1.invocationCount==1)
            if(stored==null)stored=session1
            red++;matches++;sessions+=2
        }
        must("E_PATCH24_SYNTH_COUNTS",
            red==64 && matches==64 && sessions==128)
        println("STAGE49_SYNTHETIC_64_CORRECTIONS_64_ACCEPTED_MATCH_GREEN")
        println("STAGE49_MANAGER_128_SESSIONS_GREEN")

        var giant=0;var giantMatches=0
        for(i in 1..128){
            val n=1000+i
            val divisor=ExactInt.of(n.toLong())
            must("E_PATCH24_BIG_REMAINDER_$n",
                m.euclideanMod(divisor)>ExactInt.ZERO)
            val corrected=w.patch(m,-1,n)
            val native=NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,-1),divisor).toIntExact()
            must("E_PATCH24_BIG_$n",
                corrected.correctedRank==native &&
                corrected.correctedRank==n &&
                corrected.legacyRank!=n &&
                corrected.rejectedAnswers==m.euclideanMod(divisor).toIntExact())
            giant++
            val limit=(m/divisor)*divisor
            val accepted=w.patch(limit,1,n)
            must("E_PATCH24_BIG_ACCEPT_$n",
                accepted.legacyRank==n && accepted.correctedRank==n &&
                !accepted.correctionApplied)
            giantMatches++
        }
        must("E_PATCH24_BIG_COUNTS",giant==128 && giantMatches==128)
        println("STAGE49_BIGINT_128_CORRECTIONS_128_MATCH_GREEN")

        val singleton=w.patch(m,-1,1)
        must("E_PATCH24_SINGLETON",
            singleton.correctedRank==1 && singleton.legacyRank==1 &&
            singleton.rejectedAnswers==0 && !singleton.correctionApplied)
        val three=ExactInt.of(3)
        val limit=(m/three)*three
        val positive=w.patch(m,1,3)
        must("E_PATCH24_POSITIVE_WRAP",
            positive.rejectedAnswers==1 &&
            positive.correctedRank==1 &&
            positive.correctedRank==NormativeCore.chooseRankShort(
                NormativeCore.AnswerStream(m,1),three).toIntExact())
        rejects{w.patch(ExactInt.ZERO,-1,3)}
        rejects{w.patch(m+1L,-1,3)}
        rejects{w.patch(m,-1,0)}
        rejects{w.patch(m,-1,-3)}
        rejects{w.patch(limit,0,3)}
        rejects{w.patch(limit,2,3)}
        val snapshot=manager.metrics.snapshot()
        val bootstrap=manager.bootstrap.metrics.snapshot()
        rejects{manager.apply(ExactInt.ZERO,-1,3)}
        rejects{manager.apply(m,0,3)}
        rejects{manager.apply(m,-1,0)}
        must("E_PATCH24_GUARDS_NO_SIDE_EFFECTS",
            snapshot["patch24.historical.calls"]==128L &&
            snapshot["patch24.corrected.checks"]==128L &&
            snapshot["patch24.applied"]==128L &&
            bootstrap["bootstrap.ready"]==128L &&
            manager.metrics.snapshot()==snapshot &&
            manager.bootstrap.metrics.snapshot()==bootstrap)
        val old=stored?:error("E_PATCH24_STORED_SESSION_MISSING")
        val oldResult=old.outcome
        val oldTrace=old.branchTrace.toList()
        val code=try{manager.rejectReplay(old);"NO_ERROR"}
            catch(e:MonsterValidationException){e.machineCode}
        must("E_PATCH24_REPLAY",
            code=="E_PATCH24_CONTEXT_NOT_READY" &&
            oldResult===old.outcome && oldTrace==old.branchTrace &&
            manager.metrics.snapshot()==snapshot &&
            manager.bootstrap.metrics.snapshot()==bootstrap)
        println("STAGE49_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE49_PATCH_NATIVE_GREEN")
    }
}
