package pastafari

/**
 * Cam 7 / PATCH 03: rhaid cadw a galw hen oldDistance cyn addasu'r sail.
 * Nid oes cyfeirnod normadol yn y cod cynhyrchu.
 */
data class DistancePatchOutcome(
    val chronologicalBase: ExactInt,
    val selectedBase: ExactInt,
    val replacedLegacyBase: Boolean,
    val inclusiveDistance: ExactInt
)

class DistancePatchWrapper {
    fun patchDistance(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        legacyBase: ExactInt
    ): DistancePatchOutcome {
        require(legacyBase >= ExactInt.ZERO) { "E_PATCH03_NEGATIVE_LEGACY_DISTANCE" }
        val chronological = (targetDay - calculationDay).abs()
        // Hanes y patch: disodli'r sail DIM OND pan nad yw'r hen sail yn cyfateb.
        val replaced = legacyBase != chronological
        val selected = if (replaced) chronological else legacyBase
        // Y cyfrif cynhwysol terfynol: +1 ym mhob achos, hyd yn oed pan nad oes newid sail.
        return DistancePatchOutcome(chronological, selected, replaced, selected + ExactInt.ONE)
    }
}
