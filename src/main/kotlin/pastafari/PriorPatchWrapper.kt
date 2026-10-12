package pastafari

/** Cam 13 — PATCH 06: mae'r hen legacyPrior yn aros yn weladwy-only. */
data class PriorPatchOutcome(
    val visibleIndex: Int,
    val back: Int,
    val slot: Int,
    val hiddenK: Int?,
    val source: String,
    val legacyPriorCalled: Boolean,
    val correctedValue: ExactInt
)

/**
 * Mae slot positif yn galw'r helper etifeddol go iawn.
 * Mae slot 0 neu negyddol yn defnyddio'r cyfieithydd hiddenByNearness,
 * HEb alw'r helper raw pan fo'r hanes yn gudd.
 */
class PriorPatchWrapper(
    private val legacyPriorAdapter: LegacyPriorAdapter = LegacyPriorAdapter(),
    private val hiddenNearness: HiddenNearnessPatchWrapper = HiddenNearnessPatchWrapper()
) {
    fun priorPatch(
        visibleStore: List<ExactInt?>,
        backwardHiddenStore: List<ExactInt>,
        i: Int,
        back: Int
    ): PriorPatchOutcome {
        require(i >= 1) { "E_PATCH06_VISIBLE_INDEX" }
        require(back in 1..7) { "E_PATCH06_BACK_RANGE" }
        require(visibleStore.isNotEmpty() && visibleStore[0] == null) {
            "E_PATCH06_VISIBLE_SENTINEL"
        }
        val slot = i - back
        if (slot >= 1) {
            // Dim darlleniad cudd ar y gangen hon, er yn absennol y storfa gudd.
            val raw = legacyPriorAdapter.legacyPrior(visibleStore, i, back)
            require(raw.slot == slot && raw.value != null) { "E_PATCH06_MISSING_VISIBLE_SLOT" }
            return PriorPatchOutcome(i, back, slot, null, "VISIBLE_LEGACY", true, raw.value)
        }
        val k = 1 - slot
        require(k in 1..7) { "E_PATCH06_HIDDEN_K_RANGE" }
        require(backwardHiddenStore.size == 8) { "E_PATCH06_HIDDEN_STORAGE_LENGTH" }
        // Ni chaniateir galw legacyPrior yma; mae'n anghywir ar slot<=0.
        val corrected = hiddenNearness.hiddenByNearness(backwardHiddenStore, k)
        return PriorPatchOutcome(i, back, slot, k, "HIDDEN_PATCH05", false, corrected)
    }
}
