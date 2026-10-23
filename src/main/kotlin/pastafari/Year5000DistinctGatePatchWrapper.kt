package pastafari

/** Cam 47: cywiro cyfrif pâr clwyd ddwywaith heb ddileu'r graith arbrofol. */
data class Year5000DistinctGatePatchOutcome(
    val legacyChosen: Year5000TieCandidate,
    val correctedChosen: Year5000TieCandidate,
    val uniqueCandidateCount: Int,
    val removedDuplicateCount: Int,
    val correctionApplied: Boolean,
    val historicalCalls: Int = 1,
    val correctedChecks: Int = 1
)

/** Defnyddio'r hen lwybr unwaith, ond cymhwyso'r rheng i bob pâr unigryw. */
class Year5000DistinctGatePatchWrapper(
    private val historical: LegacyYear5000RepeatedCandidateAdapter =
        LegacyYear5000RepeatedCandidateAdapter()
) {
    fun patch(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000DistinctGatePatchOutcome {
        val repeated = historical.candidatesWithOverlap(calculationDay,candidates)
        val seen = linkedMapOf<Pair<ExactInt,ExactInt>,Year5000TieCandidate>()
        for(candidate in repeated) {
            val key = candidate.openGateIndex to candidate.closeGateIndex
            val prev = seen[key]
            require(prev==null || prev==candidate) {
                "E_PATCH23_CONFLICTING_GATE_PAIR_PAYLOAD"
            }
            if(prev==null) seen[key]=candidate
        }
        val distinct = seen.values.toList()
        require(distinct.isNotEmpty()) { "E_PATCH23_NO_UNIQUE_PAIRS" }
        require(oneBasedRank>=ExactInt.ONE &&
            oneBasedRank<=ExactInt.of(distinct.size.toLong())) {
            "E_PATCH23_DISTINCT_RANK_RANGE"
        }
        val i=(oneBasedRank-ExactInt.ONE).toIntExact()
        val before=repeated[i]
        val after=distinct[i]
        check(distinct.size==seen.size &&
            distinct.toSet().size==distinct.size &&
            repeated.size >= distinct.size &&
            repeated.size-distinct.size >= 1) { "E_PATCH23_DISTINCT_ACCOUNTING" }
        return Year5000DistinctGatePatchOutcome(
            before,after,distinct.size,repeated.size-distinct.size,
            before!=after)
    }
}

data class Year5000DistinctGatePatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000DistinctGatePatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true,
    val invocationCount: Int = 1
)

/** Dim cyflwr o'r hen arbrawf yn cael ei ailddefnyddio; gwrthod ail-chwarae. */
class Year5000DistinctGatePatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000DistinctGatePatchWrapper =
        Year5000DistinctGatePatchWrapper()
) {
    fun apply(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000DistinctGatePatchSession {
        // Gwarant dim ysgrifennu i fetreg neu gyd-destun ar fethiant dilysu.
        val result = wrapper.patch(calculationDay,candidates,oneBasedRank)
        val context = BaseMonsterContext(calculationDay,calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" &&
            context.branchTrace==listOf("BOOT")) { "E_PATCH23_BOOT_SHAPE" }
        context.phase="PATCH_23"
        context.status="PATCHED_YEAR5000_DISTINCT_GATE_PAIRS"
        context.branchTrace.add("PATCH_23")
        context.diagnostics.add("PATCH_23_REMOVE_REPEATED_GATE_PAIR")
        val session=Year5000DistinctGatePatchSession(
            context,result,context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch23.historical.calls")
        metrics.bump("patch23.corrected.checks")
        metrics.bump("patch23.applied")
        return session
    }
    fun rejectReplay(session: Year5000DistinctGatePatchSession) {
        if(session.context.status!="NEW" || session.context.phase!="BOOT")
            throw MonsterValidationException("E_PATCH23_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH23_REPLAY_NOT_SUPPORTED")
    }
}
