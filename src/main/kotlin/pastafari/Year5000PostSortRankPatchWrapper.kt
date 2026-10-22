package pastafari

/** Cam 43: cywiro'r rheng cyn trefnu, gan gadw craith arbrofol Cam 42.
 * Nid yw'r dosbarth hwn yn gwneud unrhyw gyfrifiad oracl blwyddyn.
 */
data class Year5000PostSortRankPatchOutcome(
    val legacyChosen: Year5000TieCandidate,
    val correctedChosen: Year5000TieCandidate,
    val candidateCount: Int,
    val correctionApplied: Boolean,
    val legacyCalls: Int = 1,
    val correctedChecks: Int = 1
)

/** Mae'r un galwad i'r llwybr hanesyddol yn cadw trefn y rhestr.
 * Trefnir ar ôl cymhwysedd ac cyn cymhwyso'r rheng un-seiliedig.
 */
class Year5000PostSortRankPatchWrapper(
    private val legacy: LegacyYear5000PreSortRankAdapter =
        LegacyYear5000PreSortRankAdapter()
) {
    fun patch(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000PostSortRankPatchOutcome {
        val encounter = legacy.eligibleInEncounterOrder(calculationDay,candidates)
        require(oneBasedRank>=ExactInt.ONE &&
            oneBasedRank<=ExactInt.of(encounter.size.toLong())) {
            "E_PATCH21_RANK_RANGE"
        }
        val sorted = encounter.sortedWith(
            compareBy<Year5000TieCandidate> { it.length }
                .thenBy { it.openGateDay }
        )
        check(sorted.size==encounter.size &&
            sorted.toSet()==encounter.toSet() &&
            sorted.zipWithNext().all { (x,y) ->
                x.length<y.length ||
                    (x.length==y.length && x.openGateDay<=y.openGateDay)
            }) { "E_PATCH21_CANONICAL_ORDER" }
        val rank0=(oneBasedRank-ExactInt.ONE).toIntExact()
        val before=encounter[rank0]
        val after=sorted[rank0]
        return Year5000PostSortRankPatchOutcome(
            before,after,sorted.size,before!=after)
    }
}

data class Year5000PostSortRankPatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000PostSortRankPatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true,
    val invocationCount: Int = 1
)

/** Nid oes newidiadau yn y llwybr bootstrap hanesyddol.
 * Mae methiant dilysu yn digwydd cyn newid cyflwr neu fesuryddion.
 */
class Year5000PostSortRankPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000PostSortRankPatchWrapper =
        Year5000PostSortRankPatchWrapper()
) {
    fun apply(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000PostSortRankPatchSession {
        val result=wrapper.patch(calculationDay,candidates,oneBasedRank)
        val context=BaseMonsterContext(calculationDay,calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" &&
            context.branchTrace==listOf("BOOT")) { "E_PATCH21_BOOT_SHAPE" }
        context.phase="PATCH_21"
        context.status="PATCHED_YEAR5000_RANK_AFTER_SORT"
        context.branchTrace.add("PATCH_21")
        context.diagnostics.add("PATCH_21_SORT_BEFORE_RANK")
        val session=Year5000PostSortRankPatchSession(
            context,result,context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch21.legacy.calls")
        metrics.bump("patch21.corrected.checks")
        metrics.bump("patch21.applied")
        return session
    }

    fun rejectReplay(session: Year5000PostSortRankPatchSession) {
        if(session.context.status!="NEW" || session.context.phase!="BOOT")
            throw MonsterValidationException("E_PATCH21_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH21_REPLAY_NOT_SUPPORTED")
    }
}
