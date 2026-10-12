package pastafari

/**
 * Cam 11 — PATCH 05. Cedwir y storfa ffisegol yn ôl ac mae'r
 * darllenydd anghywir o Gam 10 yn parhau'n alwadadwy.
 */
data class HiddenNearnessPatchOutcome(
    val requestedK: Int,
    val physicalSlot: Int,
    val legacyDirectValue: ExactInt,
    val correctedValue: ExactInt
)

/**
 * Cyn cywiro, rhaid galw'r hen ddarllenydd go iawn a chadw ei allbwn.
 * Dim cyfeirnod normadol na newid trefn y storfa yn y cod cynhyrchu.
 */
class HiddenNearnessPatchWrapper(
    private val legacyAdapter: LegacyHiddenDropAdapter = LegacyHiddenDropAdapter()
) {
    fun hiddenByNearness(storage: List<ExactInt>, k: Int): ExactInt {
        require(k in 1..7) { "E_PATCH05_K_RANGE" }
        require(storage.size == 8) { "E_PATCH05_STORAGE_LENGTH" }
        return storage[8 - k]
    }

    fun patch(storage: List<ExactInt>, k: Int): HiddenNearnessPatchOutcome {
        require(k in 1..7) { "E_PATCH05_K_RANGE" }
        require(storage.size == 8) { "E_PATCH05_STORAGE_LENGTH" }
        // Cadw'r graith: rhaid ei GALW, nid dim ond cyfrifo slot arall.
        val legacyValue = legacyAdapter.legacyHiddenDirectByAssumedNearness(storage, k)
        val slot = 8 - k
        val corrected = hiddenByNearness(storage, k)
        return HiddenNearnessPatchOutcome(k, slot, legacyValue, corrected)
    }
}
