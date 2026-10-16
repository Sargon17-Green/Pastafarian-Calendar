package pastafari

/** Cam 33: prawf cynhyrchu ac oracl, heb newid llwybr Cam 32. */
object Stage33Tests {
    private fun insist(id:String,ok:Boolean){check(ok){id}}
    private fun rejects(block:()->Unit){
        try {block()}catch(_:IllegalArgumentException){return}
        error("E_PATCH16_MISSING_GUARD")
    }
    private fun oracle(a:ExactInt,b:ExactInt,
        open:ExactInt,close:ExactInt,day:ExactInt):Boolean {
        val days=close-open
        return b-a>=ExactInt.of(6) &&
            days>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            days<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            open<day && day<=close
    }
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val reference=NormativeCalendar()
        val wrapper=Year5000MinSixPatchWrapper()
        val manager=Year5000MinSixPatchManager()
        var count=0;var legacyRed=0;var legacyMatch=0;var sessions=0
        var first:Year5000MinSixPatchSession?=null
        for(i in -20..20){
            val a=ExactInt.of(i.toLong())
            val open=reference.gates.get(a)
            for(width in 5..8){
                val b=a+width.toLong()
                val close=reference.gates.get(b)
                for((k,day) in listOf(open,open+1L,close,close+1L)
                    .withIndex()){
                    val out=wrapper.patch(a,b,open,close,day)
                    val normative=oracle(a,b,open,close,day)
                    insist("E_PATCH16_MATRIX_$i-$width-$k",
                        out.correctedAccepted==normative &&
                        out.correctionApplied==(width==6 && (k==1 || k==2)) &&
                        out.legacyCalls==1 && out.correctedChecks==1 &&
                        out.gateGaps==ExactInt.of(width.toLong()) &&
                        out.yearDays==close-open &&
                        out.legacyAccepted==(normative && width!=6))
                    if(out.legacyAccepted!=normative)legacyRed++
                    else legacyMatch++
                    count++
                }
                val s=manager.apply(a,b,open,close,open+1L)
                insist("E_PATCH16_SESSION_$i-$width",
                    s.outcome.correctedAccepted==
                        oracle(a,b,open,close,open+1L) &&
                    s.outcome.correctionApplied==(width==6) &&
                    s.context.status=="PATCHED_YEAR5000_MIN_SIX" &&
                    s.branchTrace==listOf("BOOT","PATCH_16") &&
                    s.diagnostics==listOf("PATCH_16_MIN_SIX_GATE_GAPS") &&
                    s.context.branchTrace==s.branchTrace && s.applied)
                if(first==null)first=s
                sessions++
            }
        }
        insist("E_PATCH16_TOTALS",
            count==656 && legacyRed==82 &&
            legacyMatch==574 && sessions==164)
        println("STAGE33_REAL_GATE_GREEN_656")
        println("STAGE33_PRESERVED_EXPERIMENTAL_RED_82_MATCH_574")
        println("STAGE33_PRODUCTION_SESSION_GREEN_164")

        val huge=ExactInt.parse("1844674407370955161600000000000000000000000000")
        val far=ExactInt.parse("-1000000000000000000000000000000000000000000")
        var wide=0;var wideRed=0
        for(i in 1..384){
            val a=huge+i.toLong()
            val open=far+(i*10000L)
            val close=open+(252+(i*17)%5527).toLong()
            for(width in 5..8){
                val b=a+width.toLong()
                val out=wrapper.patch(a,b,open,close,open+1L)
                insist("E_PATCH16_WIDE_$i-$width",
                    out.correctedAccepted==oracle(a,b,open,close,open+1L) &&
                    out.correctionApplied==(width==6))
                if(out.correctionApplied)wideRed++
                wide++
            }
        }
        insist("E_PATCH16_WIDE_TOTALS",wide==1536 && wideRed==384)
        println("STAGE33_BIGINT_GREEN_1536_RED_384")

        val zero=ExactInt.ZERO
        val six=ExactInt.of(6)
        for(len in listOf(251L,252L,5778L,5779L)){
            val close=ExactInt.of(len)
            val out=wrapper.patch(zero,six,zero,close,ExactInt.ONE)
            insist("E_PATCH16_LENGTH_$len",
                out.correctedAccepted==(len in 252L..5778L) &&
                out.correctionApplied==out.correctedAccepted)
        }
        val f=NormativeCore.FOUNDATION_DAY
        val year=reference.year5000(f)
        insist("E_PATCH16_YEAR5000",
            wrapper.patch(year.openGateIndex,year.closeGateIndex,
                year.openGateDay,year.closeGateDay,f).correctedAccepted)
        println("STAGE33_YEAR5000_LENGTH_BOUNDARIES_GREEN")

        val counts=manager.metrics.snapshot()
        val boot=manager.bootstrap.metrics.snapshot()
        rejects{wrapper.patch(zero,zero,zero,six,zero)}
        rejects{wrapper.patch(zero,six,six,zero,zero)}
        rejects{manager.apply(zero,zero,zero,six,zero)}
        insist("E_PATCH16_NO_COUNTER_LEAK",
            counts["patch16.historical.calls"]==164L &&
            counts["patch16.corrected.checks"]==164L &&
            counts["patch16.applied"]==164L &&
            boot["bootstrap.ready"]==164L &&
            manager.metrics.snapshot()==counts &&
            manager.bootstrap.metrics.snapshot()==boot)
        val session=first?:error("E_PATCH16_NO_FIRST")
        val saved=session.outcome
        val code=try {
            manager.rejectReplay(session);"NO_ERROR"
        }catch(e:MonsterValidationException){e.machineCode}
        insist("E_PATCH16_REPLAY",
            code=="E_PATCH16_CONTEXT_NOT_READY" &&
            session.outcome===saved &&
            session.branchTrace==listOf("BOOT","PATCH_16") &&
            manager.metrics.snapshot()==counts &&
            manager.bootstrap.metrics.snapshot()==boot)
        println("STAGE33_GUARDS_REPLAY_METRICS_GREEN")
        println("STAGE33_PATCH_NATIVE_GREEN")
    }
}
