package pastafari

/** Cam 49: cywiro'r dethol safle blwyddyn 5000 heb alw'r oracl prawf.
 * Mae'r addasydd modiwlo hanesyddol yn aros yn ddigyfnewid.
 */
data class Year5000RejectionRankPatchOutcome(
    val legacyRank: Int,
    val correctedRank: Int,
    val candidateCount: Int,
    val rejectedAnswers: Int,
    val correctionApplied: Boolean,
    val historicalCalls: Int = 1,
    val correctedChecks: Int = 1
)

class Year5000RejectionRankPatchWrapper(
    private val historical: LegacyYear5000FirstAnswerModuloAdapter =
        LegacyYear5000FirstAnswerModuloAdapter()
) {
    fun patch(
        firstAnswer: ExactInt,
        directionStep: Int,
        candidateCount: Int
    ): Year5000RejectionRankPatchOutcome {
        require(candidateCount>0){ "E_PATCH24_NO_CANDIDATES" }
        require(directionStep==1 || directionStep == -1) {
            "E_PATCH24_DIRECTION"
        }
        val m=LegacyYear5000FirstAnswerModuloAdapter.ANSWER_MODULUS
        require(firstAnswer>=ExactInt.ONE && firstAnswer<=m) {
            "E_PATCH24_ANSWER_RANGE"
        }
        val n=ExactInt.of(candidateCount.toLong())
        val limit=(m/n)*n
        val legacy=historical.rankFromFirstAnswer(firstAnswer,candidateCount)
        var answer=firstAnswer
        var rejected=0
        while(answer>limit) {
            rejected++
            check(rejected<=candidateCount) {
                "E_PATCH24_REJECTION_GUARD"
            }
            answer=ExactInt.ONE + (answer-ExactInt.ONE +
                ExactInt.of(directionStep.toLong())).euclideanMod(m)
        }
        val corrected=((answer-ExactInt.ONE).euclideanMod(n)+ExactInt.ONE)
            .toIntExact()
        check(corrected in 1..candidateCount) {
            "E_PATCH24_RANK_RANGE"
        }
        return Year5000RejectionRankPatchOutcome(
            legacy,corrected,candidateCount,rejected,legacy!=corrected)
    }
}

data class Year5000RejectionRankPatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000RejectionRankPatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true,
    val invocationCount: Int = 1
)

class Year5000RejectionRankPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000RejectionRankPatchWrapper =
        Year5000RejectionRankPatchWrapper()
) {
    fun apply(
        firstAnswer: ExactInt, directionStep: Int, candidateCount: Int
    ): Year5000RejectionRankPatchSession {
        // Rhaid cwblhau'r dilysu cyn newid cyd-destun na metrigau.
        val outcome=wrapper.patch(firstAnswer,directionStep,candidateCount)
        val context=BaseMonsterContext(firstAnswer,firstAnswer)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" &&
            context.branchTrace==listOf("BOOT")) {
            "E_PATCH24_BOOT_SHAPE"
        }
        context.phase="PATCH_24"
        context.status="PATCHED_YEAR5000_REJECTION_RANK"
        context.branchTrace.add("PATCH_24")
        context.diagnostics.add("PATCH_24_REJECTION_SAMPLING")
        val session=Year5000RejectionRankPatchSession(
            context,outcome,context.branchTrace.toList(),
            context.diagnostics.toList()
        )
        metrics.bump("patch24.historical.calls")
        metrics.bump("patch24.corrected.checks")
        metrics.bump("patch24.applied")
        return session
    }

    fun rejectReplay(session: Year5000RejectionRankPatchSession){
        if(session.context.status!="NEW" || session.context.phase!="BOOT")
            throw MonsterValidationException("E_PATCH24_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH24_REPLAY_NOT_SUPPORTED")
    }
}
