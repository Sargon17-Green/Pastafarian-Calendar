package pastafari

/** Cam 29: integreiddio fel haen ychwanegol i gadw llwybrau Camau 1–28 yn annibynnol. */
data class NegativeGateDirectionPatchSession(
    val baseContext: BaseMonsterContext,
    val outcome: NegativeGateDirectionPatchOutcome,
    val phase: String = "PATCH_14",
    val status: String = "PATCHED_NEGATIVE_GATE_DIRECTION",
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true,
    val invocationCount: Int = 1
)

class NegativeGateDirectionPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: NegativeGateDirectionPatchWrapper =
        NegativeGateDirectionPatchWrapper()
) {
    /** Stream negyddol Bowl 1 / Seal 1 (saws F,F-magnitude) o'r galwr;
     * dim oracl yn y dosbarth hwn, a dim newid i MonsterBootstrap hanesyddol.
     */
    fun applyNegativeGateDirectionPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        magnitude: ExactInt, previousNegativeGate: ExactInt,
        positiveGap: Int, negativeStreamFirst: ExactInt,
        negativeStreamStep: Int
    ): NegativeGateDirectionPatchSession {
        // Gwirio holl fewnbynnau'r llwybr newydd cyn galw'r hen beiriant.
        val output = wrapper.patch(
            magnitude, previousNegativeGate, positiveGap,
            negativeStreamFirst, negativeStreamStep)
        val base = bootstrap.applyGateGapRankPatch(
            calculationDay, targetDay, -magnitude,
            negativeStreamFirst, negativeStreamStep)
        check(base.patch13CorrectedGateGap == output.negativeGap &&
            base.patch13Outcome?.acceptedAnswer ==
                output.negativeGapRank.acceptedAnswer &&
            base.branchTrace == listOf("BOOT", "PATCH_13") &&
            base.status == "PATCHED_GATE_GAP_RANK1") {
            "E_PATCH14_PRODUCTION_RANK_DISAGREEMENT"
        }
        val session = NegativeGateDirectionPatchSession(
            baseContext = base, outcome = output,
            branchTrace = base.branchTrace.toList() + "PATCH_14",
            diagnostics = base.diagnostics.toList() +
                "PATCH_14_NEGATIVE_SAUCE_DIRECTION")
        metrics.bump("patch14.experimental.legacy.calls")
        metrics.bump("patch14.corrected.negative.calls")
        metrics.bump("patch14.applied")
        return session
    }
}
