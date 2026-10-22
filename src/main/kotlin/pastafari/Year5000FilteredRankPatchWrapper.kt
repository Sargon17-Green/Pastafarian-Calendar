package pastafari

/** Cam 45: hidlo ymgeiswyr blwyddyn 5000 cyn dewis rheng.
 * Mae'r llwybr hanesyddol heb ei newid; nid yw'r cod hwn yn cyfrifo'r oracl.
 */
data class Year5000FilteredRankPatchOutcome(
    val legacyChosen: Year5000TieCandidate,
    val correctedChosen: Year5000TieCandidate,
    val eligibleCandidateCount: Int,
    val discardedCandidateCount: Int,
    val correctionApplied: Boolean,
    val historicalCalls: Int = 1,
    val correctedChecks: Int = 1
)

/** Cadw trefn yr hen addasydd unwaith, yna hidlo cyn cymhwyso rheng. */
class Year5000FilteredRankPatchWrapper(
    private val historical: LegacyYear5000UnfilteredRankAdapter =
        LegacyYear5000UnfilteredRankAdapter()
) {
    fun patch(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000FilteredRankPatchOutcome {
        val originalOrder = historical.allCandidatesSorted(candidates)
        val eligible = originalOrder.filter { historical.accepts(calculationDay,it) }
        require(eligible.isNotEmpty()) { "E_PATCH22_NO_ELIGIBLE_CANDIDATES" }
        require(oneBasedRank >= ExactInt.ONE &&
            oneBasedRank <= ExactInt.of(eligible.size.toLong())) {
            "E_PATCH22_ELIGIBLE_RANK_RANGE"
        }
        val i=(oneBasedRank - ExactInt.ONE).toIntExact()
        val legacyChosen=originalOrder[i]
        val correctedChosen=eligible[i]
        check(historical.accepts(calculationDay,correctedChosen)) {
            "E_PATCH22_SELECTED_INELIGIBLE"
        }
        check(eligible.size+originalOrder.count{ !historical.accepts(calculationDay,it) }
            == originalOrder.size) { "E_PATCH22_ELIGIBILITY_PARTITION" }
        return Year5000FilteredRankPatchOutcome(
            legacyChosen,correctedChosen,eligible.size,
            originalOrder.size-eligible.size,legacyChosen!=correctedChosen
        )
    }
}

data class Year5000FilteredRankPatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000FilteredRankPatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true,
    val invocationCount: Int = 1
)

/** Llwybr cyflwr ategol; mae gwiriadau mewnbwn cyn y bootstrap. */
class Year5000FilteredRankPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000FilteredRankPatchWrapper =
        Year5000FilteredRankPatchWrapper()
) {
    fun apply(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000FilteredRankPatchSession {
        val result=wrapper.patch(calculationDay,candidates,oneBasedRank)
        val context=BaseMonsterContext(calculationDay,calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" &&
            context.branchTrace==listOf("BOOT")) { "E_PATCH22_BOOT_SHAPE" }
        context.phase="PATCH_22"
        context.status="PATCHED_YEAR5000_ELIGIBILITY_BEFORE_RANK"
        context.branchTrace.add("PATCH_22")
        context.diagnostics.add("PATCH_22_FILTER_BEFORE_RANK")
        val session=Year5000FilteredRankPatchSession(
            context,result,context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch22.historical.calls")
        metrics.bump("patch22.corrected.checks")
        metrics.bump("patch22.applied")
        return session
    }

    fun rejectReplay(session: Year5000FilteredRankPatchSession) {
        if(session.context.status!="NEW" || session.context.phase!="BOOT")
            throw MonsterValidationException("E_PATCH22_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH22_REPLAY_NOT_SUPPORTED")
    }
}
