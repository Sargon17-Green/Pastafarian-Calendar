package pastafari

/** Cam 51: cywiro colli lapio'r llif atebion; nid yw'r hen graith yn newid. */
data class Year5000WrappedAnswerPatchResult(
    val legacyRank: Int?, val correctedRank: Int, val rejectedAnswers: Int,
    val correctionApplied: Boolean, val candidateCount: Int
)

class Year5000WrappedAnswerPatchWrapper(
    private val legacy: LegacyYear5000UnwrappedAnswerAdapter =
        LegacyYear5000UnwrappedAnswerAdapter()
) {
    fun patch(firstAnswer: ExactInt, directionStep: Int, candidateCount: Int): Year5000WrappedAnswerPatchResult {
        require(candidateCount > 0) { "E_PATCH25_EMPTY_CANDIDATES" }
        require(directionStep == 1 || directionStep == -1) { "E_PATCH25_DIRECTION" }
        val m=LegacyYear5000UnwrappedAnswerAdapter.MODULUS
        require(firstAnswer >= ExactInt.ONE && firstAnswer <= m) { "E_PATCH25_FIRST_ANSWER_RANGE" }
        val n=ExactInt.of(candidateCount.toLong())
        val ceiling=(m/n)*n
        val old=legacy.tryRank(firstAnswer,directionStep,candidateCount,candidateCount+1)
        var answer=firstAnswer
        var rejected=0
        while(answer>ceiling) {
            rejected++
            check(rejected<=candidateCount){ "E_PATCH25_REJECTION_BUDGET" }
            answer=ExactInt.ONE+(answer-ExactInt.ONE+directionStep.toLong()).euclideanMod(m)
        }
        val corrected=((answer-ExactInt.ONE).euclideanMod(n)+ExactInt.ONE).toIntExact()
        check(corrected in 1..candidateCount) { "E_PATCH25_RANK_RANGE" }
        return Year5000WrappedAnswerPatchResult(old,corrected,rejected,old!=corrected,candidateCount)
    }
}

data class Year5000WrappedAnswerPatchSession(
    val context: BaseMonsterContext, val outcome: Year5000WrappedAnswerPatchResult,
    val trace: List<String>, val diagnostics: List<String>
)

class Year5000WrappedAnswerPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000WrappedAnswerPatchWrapper = Year5000WrappedAnswerPatchWrapper()
) {
    fun apply(firstAnswer: ExactInt, directionStep: Int, count: Int): Year5000WrappedAnswerPatchSession {
        val result=wrapper.patch(firstAnswer,directionStep,count)
        val context=BaseMonsterContext(firstAnswer,firstAnswer)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" && context.branchTrace==listOf("BOOT")) { "E_PATCH25_BOOT" }
        context.phase="PATCH_25"
        context.status="PATCHED_YEAR5000_WRAPPED_ANSWER"
        context.branchTrace.add("PATCH_25")
        context.diagnostics.add("PATCH_25_MODULUS_WRAP")
        metrics.bump("patch25.historical.calls")
        metrics.bump("patch25.corrected.checks")
        metrics.bump("patch25.applied")
        return Year5000WrappedAnswerPatchSession(context,result,context.branchTrace.toList(),context.diagnostics.toList())
    }
    fun rejectReplay(session: Year5000WrappedAnswerPatchSession): Nothing {
        if(session.context.status!="NEW" || session.context.phase!="BOOT")
            throw MonsterValidationException("E_PATCH25_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH25_REPLAY_NOT_SUPPORTED")
    }
}
