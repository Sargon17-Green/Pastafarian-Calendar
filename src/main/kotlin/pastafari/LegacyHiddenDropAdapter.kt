package pastafari

/** Mewnbynnau'r cyfrifiad cudd: rhifau a gywirwyd gan PATCH 02/03. */
data class HiddenWorkCounts(
    val action: ExactInt,
    val target: ExactInt,
    val distance: ExactInt,
    val connection: ExactInt,
    val direction: ExactInt
)

/**
 * Cam 10 — DISCOVERY 05. Mae'r cof FFEISEGOL yn rhedeg hidden7 ... hidden1.
 * Mae darllenydd agosrwydd hen ffasiwn yn defnyddio'r cyfeiriad k yn uniongyrchol.
 * NI cheir cyfieithydd PATCH 05 yma; mae'r nam yn rhaid aros yn weladwy.
 */
class LegacyHiddenDropAdapter(
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper()
) {
    // Trefn hanesyddol wrthdro; mae cyfrifiad hidden k yn defnyddio coeff[7-k].
    private val reversedCoefficients = arrayOf(
        intArrayOf(15, 22, 30, 32),
        intArrayOf(13, 19, 26, 28),
        intArrayOf(11, 16, 22, 24),
        intArrayOf(9, 13, 18, 20),
        intArrayOf(7, 10, 14, 16),
        intArrayOf(5, 7, 10, 12),
        intArrayOf(3, 4, 6, 8)
    )
    private val grindingStones = intArrayOf(0, 1, 2, 3, 4, 0, 1)

    private fun save(value: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(value))

    /** Slot 0 yw'r sentinela; slot 1 yw hidden7, slot 7 yw hidden1. */
    fun buildBackwardStorage(counts: HiddenWorkCounts, stones: List<MutableStoneRow>): List<ExactInt> {
        require(stones.size == 47) { "E_DISCOVERY05_STONE_TABLE_LENGTH" }
        val physical = MutableList(8) { ExactInt.ZERO }
        for (k in 1..7) {
            val coefficients = reversedCoefficients[7 - k]
            val row = stones[k].components()
            var x = counts.action +
                counts.target.multiplyByInt(coefficients[0]) +
                counts.distance.multiplyByInt(coefficients[1]) +
                counts.connection.multiplyByInt(coefficients[2]) +
                counts.direction.multiplyByInt(coefficients[3])
            for (stone in row) x += stone
            x = save(x)
            for (grind in 1..7) {
                val preceding = x
                x = save(
                    preceding.square() + preceding.multiplyByInt(3) +
                        row[grindingStones[grind - 1]] + grind.toLong()
                )
            }
            physical[8 - k] = x
        }
        return physical.toList()
    }

    /** Y graith: dim mapio agosrwydd -> slot corfforol. */
    fun legacyHiddenDirectByAssumedNearness(storage: List<ExactInt>, k: Int): ExactInt {
        require(k in 1..7) { "E_DISCOVERY05_K_RANGE" }
        require(storage.size == 8) { "E_DISCOVERY05_STORAGE_LENGTH" }
        return storage[k]
    }
}
