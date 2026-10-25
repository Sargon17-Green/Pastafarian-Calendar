package pastafari

/**
 * Cam 54 — DISCOVERY 27: graith arbrofol, NID nam cynhyrchu profedig.
 * Mae'r rhestr a roddir eisoes yn gymwys, unigryw ac mewn trefn normadol.
 * Y GRAITH yw defnyddio rank1 fel index0 gyda lapio cylchol (rank1 % n).
 * Mae'r oracl normadol yn aros dan src/test yn unig.
 */
data class LegacyYear5000RankAsIndexRead(
    val rank1: ExactInt,
    val count: Int,
    val wrongIndex0: Int,
    val wrongChosen: Year5000TieCandidate,
    val wrappedAtEnd: Boolean,
    val listReads: Int = 1
)

class LegacyYear5000RankAsIndexAdapter {
    fun oldChoose(
        calculationDay: ExactInt,
        ordered: List<Year5000TieCandidate>,
        rank1: ExactInt
    ): LegacyYear5000RankAsIndexRead {
        require(ordered.isNotEmpty()) { "E_DISCOVERY27_EMPTY" }
        require(rank1 >= ExactInt.ONE &&
            rank1 <= ExactInt.of(ordered.size.toLong())) { "E_DISCOVERY27_RANK" }
        for (c in ordered) {
            require(c.closeGateIndex - c.openGateIndex >= ExactInt.of(6) &&
                c.length >= ExactInt.of(252) && c.length <= ExactInt.of(5778) &&
                c.openGateDay < calculationDay && calculationDay <= c.closeGateDay) {
                "E_DISCOVERY27_UNFILTERED"
            }
        }
        require(ordered.distinctBy { it.openGateIndex to it.closeGateIndex }.size ==
            ordered.size) { "E_DISCOVERY27_DUPLICATE" }
        require(ordered.zipWithNext().all { (a,b) ->
            a.length < b.length ||
                (a.length == b.length && a.openGateDay <= b.openGateDay)
        }) { "E_DISCOVERY27_UNSORTED" }
        // GRAITH: rank un-seiliedig yn cael ei ddefnyddio'n fynegai sero-seiliedig.
        val index0 = rank1.toIntExact() % ordered.size
        return LegacyYear5000RankAsIndexRead(
            rank1,ordered.size,index0,ordered[index0],index0==0)
    }
}

data class LegacyYear5000RankAsIndexSession(
    val context: BaseMonsterContext,
    val outcome: LegacyYear5000RankAsIndexRead,
    val trace: List<String>,
    val diagnostics: List<String>
)

class LegacyYear5000RankAsIndexManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val adapter: LegacyYear5000RankAsIndexAdapter =
        LegacyYear5000RankAsIndexAdapter()
) {
    fun observe(day: ExactInt, candidates: List<Year5000TieCandidate>,
                rank1: ExactInt): LegacyYear5000RankAsIndexSession {
        val read = adapter.oldChoose(day,candidates,rank1)
        val context = BaseMonsterContext(day,day)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" && context.branchTrace==listOf("BOOT")) {
            "E_DISCOVERY27_BOOT"
        }
        context.phase="DISCOVERY_27"
        context.status="OBSERVED_YEAR5000_RANK_AS_INDEX"
        context.branchTrace.add("DISCOVERY_27")
        context.diagnostics.add("DISCOVERY_27_ONE_BASED_RANK_USED_AS_INDEX0")
        metrics.bump("discovery27.historical.calls")
        metrics.bump("discovery27.observed")
        return LegacyYear5000RankAsIndexSession(
            context,read,context.branchTrace.toList(),context.diagnostics.toList())
    }
    fun rejectReplay(session: LegacyYear5000RankAsIndexSession): Nothing {
        if (session.context.phase!="BOOT" || session.context.status!="NEW")
            throw MonsterValidationException("E_DISCOVERY27_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_DISCOVERY27_REPLAY_NOT_SUPPORTED")
    }
}
