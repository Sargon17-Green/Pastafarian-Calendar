package pastafari

/**
 * Cam 12 — DISCOVERY 06: mae'r hen ddarllenydd hanes yn adnabod
 * y tabl diferion GWELEDIG yn unig; nid oes ganddo lwybr i'r rhai cudd.
 */
data class LegacyPriorRead(
    val visibleIndex: Int,
    val back: Int,
    val slot: Int,
    val value: ExactInt?
)

class LegacyPriorAdapter {
    fun legacyPrior(visibleStore: List<ExactInt?>, i: Int, back: Int): LegacyPriorRead {
        require(i >= 1) { "E_DISCOVERY06_VISIBLE_INDEX" }
        require(back in 1..7) { "E_DISCOVERY06_BACK_RANGE" }
        require(visibleStore.isNotEmpty() && visibleStore[0] == null) {
            "E_DISCOVERY06_VISIBLE_SENTINEL"
        }
        val slot = i - back
        // Y GRAITH: dim trosi slot 0,-1,...,-6 i hidden1,...,hidden7.
        // Darllen o'r storfa weledig yn unig. Y canlyniad anghywir yw null.
        val result = if (slot >= 1) visibleStore.getOrNull(slot) else null
        return LegacyPriorRead(i, back, slot, result)
    }
}
