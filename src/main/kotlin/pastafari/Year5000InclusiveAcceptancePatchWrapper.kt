package pastafari

/** Cam 53: derbyn union ffin samplu; cedwir craith arbrofol Cam 52.
 *  Nid yw'r addasydd hanesyddol yn llwybr cynhyrchu nac yn oracl.
 */
data class Year5000InclusiveAcceptancePatchResult(
    val legacyRank: Int?,
    val correctedRank: Int,
    val rejectedAnswers: Int,
    val correctionApplied: Boolean,
    val candidateCount: Int
)

class Year5000InclusiveAcceptancePatchWrapper(
    private val historical: LegacyYear5000ExclusiveAcceptanceAdapter =
        LegacyYear5000ExclusiveAcceptanceAdapter()
) {
    fun patch(firstAnswer: ExactInt, directionStep: Int, candidateCount: Int):
        Year5000InclusiveAcceptancePatchResult {
        require(candidateCount > 0) { "E_PATCH26_CANDIDATE_COUNT" }
        require(directionStep == 1 || directionStep == -1) { "E_PATCH26_DIRECTION" }
        val m = LegacyYear5000ExclusiveAcceptanceAdapter.MODULUS
        require(firstAnswer >= ExactInt.ONE && firstAnswer <= m) {
            "E_PATCH26_FIRST_ANSWER_RANGE"
        }
        val n = ExactInt.of(candidateCount.toLong())
        val limit = (m / n) * n
        // Ymgynghorir â'r hen addasydd yn unig at ddiben cymharu.
        val old = historical.rankOrNull(
            firstAnswer, directionStep, candidateCount, candidateCount
        )
        var answer = firstAnswer
        var rejected = 0
        // Mae'r union ffin yn dderbyniol: answer <= floor(M/n)*n.
        while (answer > limit) {
            rejected++
            check(rejected <= candidateCount) { "E_PATCH26_REJECTION_BUDGET" }
            answer = ExactInt.ONE +
                (answer - ExactInt.ONE + directionStep.toLong()).euclideanMod(m)
        }
        val rank = ((answer - ExactInt.ONE).euclideanMod(n) + ExactInt.ONE)
            .toIntExact()
        check(rank in 1..candidateCount) { "E_PATCH26_RANK_RANGE" }
        return Year5000InclusiveAcceptancePatchResult(
            old, rank, rejected, old != rank, candidateCount
        )
    }
}

data class Year5000InclusiveAcceptancePatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000InclusiveAcceptancePatchResult,
    val trace: List<String>,
    val diagnostics: List<String>
)

class Year5000InclusiveAcceptancePatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000InclusiveAcceptancePatchWrapper =
        Year5000InclusiveAcceptancePatchWrapper()
) {
    fun apply(firstAnswer: ExactInt, directionStep: Int, candidateCount: Int):
        Year5000InclusiveAcceptancePatchSession {
        // Mae dilysu'n rhagflaenu pob effaith ar y cyd-destun neu'r metrigau.
        val outcome = wrapper.patch(firstAnswer, directionStep, candidateCount)
        val context = BaseMonsterContext(firstAnswer, firstAnswer)
        bootstrap.dispatcher.dispatch(context)
        check(context.status == "READY" && context.branchTrace == listOf("BOOT")) {
            "E_PATCH26_BOOT_SHAPE"
        }
        context.phase = "PATCH_26"
        context.status = "PATCHED_YEAR5000_INCLUSIVE_ACCEPTANCE"
        context.branchTrace.add("PATCH_26")
        context.diagnostics.add("PATCH_26_INCLUSIVE_ACCEPTANCE")
        metrics.bump("patch26.historical.calls")
        metrics.bump("patch26.corrected.checks")
        metrics.bump("patch26.applied")
        return Year5000InclusiveAcceptancePatchSession(
            context, outcome, context.branchTrace.toList(),
            context.diagnostics.toList()
        )
    }

    fun rejectReplay(session: Year5000InclusiveAcceptancePatchSession): Nothing {
        if (session.context.status != "NEW" || session.context.phase != "BOOT")
            throw MonsterValidationException("E_PATCH26_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH26_REPLAY_NOT_SUPPORTED")
    }
}
