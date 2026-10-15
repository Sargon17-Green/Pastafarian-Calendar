package pastafari

/** Cam 29: cywiriad cyfeiriad giatiau negyddol; cedwir y graith arbrofol Cam 28. */
data class NegativeGateDirectionPatchOutcome(
    val magnitude: ExactInt,
    val previousNegativeGate: ExactInt,
    val positiveGap: Int,
    val negativeGap: Int,
    val negativeStreamFirst: ExactInt,
    val negativeStreamStep: Int,
    val legacyNegativeGate: ExactInt,
    val correctedNegativeGate: ExactInt,
    val negativeGapRank: GateGapPatchOutcome,
    val legacyCalls: Int,
    val correctedCalls: Int
)

/** Nid yw'r llwybr cynhyrchu hwn yn dibynnu ar NormativeCalendar (oracl y profion).
 * Rhaid i'r galwr ddarparu stream Bowl 1 / Seal 1 o saws (F,F-magnitude).
 */
class NegativeGateDirectionPatchWrapper(
    private val legacy: LegacyNegativeGateDirectionAdapter = LegacyNegativeGateDirectionAdapter(),
    private val rankPatch: GateGapRankPatchWrapper = GateGapRankPatchWrapper()
) {
    fun patch(
        magnitude: ExactInt,
        previousNegativeGate: ExactInt,
        positiveGap: Int,
        negativeStreamFirst: ExactInt,
        negativeStreamStep: Int
    ): NegativeGateDirectionPatchOutcome {
        require(magnitude >= ExactInt.ONE) { "E_PATCH14_MAGNITUDE" }
        require(positiveGap in 42..963) { "E_PATCH14_POSITIVE_GAP" }
        val wrong = legacy.negativeGateFromPositiveGap(
            magnitude, previousNegativeGate, positiveGap)
        val rank = rankPatch.patch(-magnitude, negativeStreamFirst, negativeStreamStep)
        val gap = rank.correctedGateGap
        check(gap in 42..963 && rank.gateIndex == -magnitude &&
            rank.legacyRank0Calls == 1 && rank.correctedRankCalls == 1) {
            "E_PATCH14_NEGATIVE_GAP_SHAPE"
        }
        return NegativeGateDirectionPatchOutcome(
            magnitude, previousNegativeGate, positiveGap, gap,
            negativeStreamFirst, negativeStreamStep,
            wrong, previousNegativeGate - ExactInt.of(gap.toLong()),
            rank, 1, 1)
    }
}
