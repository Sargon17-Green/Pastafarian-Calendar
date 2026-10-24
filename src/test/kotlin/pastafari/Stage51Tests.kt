package pastafari

/** Cam 51: cymharu'r trwsiad â'r oracl wreiddiol mewn profion yn unig. */
object Stage51Tests {
    private fun must(code:String, condition:Boolean) { check(condition){code} }
    private fun rejects(block:()->Unit) {
        try {block()} catch(_:IllegalArgumentException) {return}
        error("E_PATCH25_EXPECTED_GUARD")
    }
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val patch=Year5000WrappedAnswerPatchWrapper()
        val manager=Year5000WrappedAnswerPatchManager()
        val m=NormativeCore.M
        must("E_PATCH25_MODULUS",LegacyYear5000UnwrappedAnswerAdapter.MODULUS==m)
        val oracle=NormativeCalendar()
        val day=NormativeCore.FOUNDATION_DAY
        val candidates=mutableListOf<Year5000TieCandidate>()
        for(i in -16..16) {
            val a=ExactInt.of(i.toLong());val open=oracle.gates.get(a)
            for(width in 6..12) {
                val b=a+width.toLong()
                candidates.add(Year5000TieCandidate(a,b,open,oracle.gates.get(b)))
            }
        }
        val eligible=candidates.filter { c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
            c.length>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            c.length<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            c.openGateDay<day && day<=c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate>{it.length}.thenBy{it.openGateDay})
        must("E_PATCH25_REAL_PAIRS",candidates.size==231 && eligible.isNotEmpty())
        val stream=NormativeCore.askBowl(NormativeCore.sauce(day,day),1,NormativeCore.SEAL_YEAR_5000)
        val actual=patch.patch(stream.first,stream.directionStep,eligible.size)
        must("E_PATCH25_REAL_ORACLE",actual.correctedRank==
            NormativeCore.chooseRankInt(stream,eligible.size) &&
            oracle.year5000(day).openGateDay<day)
        println("STAGE51_REAL_231_GATE_PAIRS_ORACLE_GREEN")

        var fixed=0;var backward=0;var sessions=0
        var saved:Year5000WrappedAnswerPatchSession?=null
        for(n in 2..65) {
            val divisor=ExactInt.of(n.toLong())
            must("E_PATCH25_NONZERO_REM_$n",m.euclideanMod(divisor)>ExactInt.ZERO)
            val r=patch.patch(m,1,n)
            val good=NormativeCore.chooseRankShort(NormativeCore.AnswerStream(m,1),divisor).toIntExact()
            val sess=manager.apply(m,1,n)
            must("E_PATCH25_WRAP_$n",r.correctedRank==1 && r.correctedRank==good &&
                r.legacyRank==null && r.correctionApplied && r.rejectedAnswers==1 &&
                sess.outcome==r && sess.trace==listOf("BOOT","PATCH_25") &&
                sess.context.status=="PATCHED_YEAR5000_WRAPPED_ANSWER" &&
                sess.diagnostics==listOf("PATCH_25_MODULUS_WRAP"))
            if(saved==null)saved=sess
            fixed++;sessions++
            val previous=patch.patch(m,-1,n)
            val prior=NormativeCore.chooseRankShort(NormativeCore.AnswerStream(m,-1),divisor).toIntExact()
            must("E_PATCH25_BACKWARD_$n",previous.correctedRank==prior &&
                previous.legacyRank==prior && !previous.correctionApplied)
            backward++
        }
        must("E_PATCH25_SYNTH_TOTAL",fixed==64 && backward==64 && sessions==64)
        println("STAGE51_SYNTHETIC_64_WRAPS_FIXED_64_BACKWARD_MATCH_GREEN")

        var giants=0
        for(n in 1001..1128) {
            val divisor=ExactInt.of(n.toLong())
            must("E_PATCH25_BIG_NONZERO_$n",m.euclideanMod(divisor)>ExactInt.ZERO)
            val f=patch.patch(m,1,n)
            val b=patch.patch(m,-1,n)
            must("E_PATCH25_BIG_$n",f.correctedRank==1 && f.legacyRank==null &&
                f.rejectedAnswers==1 && f.correctionApplied &&
                b.correctedRank==NormativeCore.chooseRankShort(
                    NormativeCore.AnswerStream(m,-1),divisor).toIntExact() &&
                b.correctedRank==b.legacyRank && !b.correctionApplied)
            giants++
        }
        must("E_PATCH25_BIG_TOTAL",giants==128)
        println("STAGE51_BIGINT_128_WRAPS_FIXED_128_BACKWARD_MATCH_GREEN")
        must("E_PATCH25_SINGLETON",patch.patch(m,1,1).correctedRank==1)
        rejects{patch.patch(ExactInt.ZERO,1,3)}
        rejects{patch.patch(m+1L,1,3)}
        rejects{patch.patch(m,0,3)}
        rejects{patch.patch(m,2,3)}
        rejects{patch.patch(m,1,0)}
        rejects{patch.patch(m,1,-1)}
        val before=manager.metrics.snapshot()
        val boot=manager.bootstrap.metrics.snapshot()
        rejects{manager.apply(m,0,3)}
        rejects{manager.apply(m,1,0)}
        must("E_PATCH25_METRIC_STABILITY",before["patch25.applied"]==64L &&
            before["patch25.historical.calls"]==64L &&
            before["patch25.corrected.checks"]==64L &&
            boot["bootstrap.ready"]==64L &&
            manager.metrics.snapshot()==before && manager.bootstrap.metrics.snapshot()==boot)
        val session=saved?:error("E_PATCH25_SESSION_MISSING")
        val code=try{manager.rejectReplay(session);"NO_ERROR"}
            catch(e:MonsterValidationException){e.machineCode}
        must("E_PATCH25_REPLAY",code=="E_PATCH25_CONTEXT_NOT_READY" &&
            manager.metrics.snapshot()==before && manager.bootstrap.metrics.snapshot()==boot)
        println("STAGE51_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE51_PATCH_NATIVE_GREEN")
    }
}
