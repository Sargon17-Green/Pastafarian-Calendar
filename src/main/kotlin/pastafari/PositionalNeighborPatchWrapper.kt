package pastafari

/**
 * Cam 25 — PATCH 12: defnyddio cymydog yn nhrefn diferyn 46.
 * Cedwir y caller rhifol anghywir Cam 24 a'i alw'n gyntaf.
 * Mae'r bowls terfynol a diferyn 46 yn fewnbynnau allanol.
 */
data class PositionalNeighborPatchOutcome(
    val drop46: ExactInt,
    val seal: Int,
    val queriedBowlId: Int,
    val drop46Order: List<Int>,
    val legacyRead: LegacyNumericNeighborRead,
    val correctedNeighborId: Int,
    val correctedFirstAnswer: ExactInt,
    val correctedDirectionNumber: ExactInt,
    val correctedDirectionStep: Int,
    val legacyNumericNeighborCalls: Int,
    val correctedNeighborCalls: Int,
    val patchedPermutationCalls: Int
)

class PositionalNeighborPatchWrapper(
    private val legacy: LegacyNumericNeighborAdapter = LegacyNumericNeighborAdapter(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper()
) {
    private fun save(value: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(value))

    fun patch(
        finalBowls: List<ExactInt>, drop46: ExactInt,
        queriedBowlId: Int, seal: Int
    ): PositionalNeighborPatchOutcome {
        require(finalBowls.size == 7 && finalBowls[0] == ExactInt.ZERO) {
            "E_PATCH12_FINAL_BOWL_SHAPE"
        }
        require(queriedBowlId in 1..6) { "E_PATCH12_QUERY_BOWL_RANGE" }
        require(seal > 0) { "E_PATCH12_SEAL_RANGE" }
        val snapshot = finalBowls.toList()
        // Galw'r graith go iawn CYNN cofio'r ID cymydog cywir.
        val scar = legacy.oldNumericNeighborQuestion(
            snapshot.toList(),drop46,queriedBowlId,seal)
        val order = scar.drop46Order.toList()
        val position = order.indexOf(queriedBowlId)
        require(position >= 0 && order.size == 6 &&
            order.sorted() == listOf(1,2,3,4,5,6) &&
            scar.drop46 == drop46 && scar.seal == seal &&
            scar.queriedBowlId == queriedBowlId &&
            scar.numericNeighborCalls == 1 &&
            scar.permutationPatchCalls == 1 &&
            scar.actualNeighborIdWrong ==
                (if (queriedBowlId == 6) 1 else queriedBowlId + 1) &&
            scar.positionalNeighborIdExpected ==
                order[(position + 1) % 6]) {
            "E_PATCH12_LEGACY_SHAPE"
        }
        // PATCH 12: cymydog nesaf yn nhrefn y diferyn 46 yn unig.
        val nextId = order[(position + 1) % 6]
        val base = snapshot[queriedBowlId] + seal.toLong() + 181L
        val first = save(
            base.square() + snapshot[nextId].multiplyByInt(179) +
                seal.toLong()
        )
        val directionBase = first + seal.toLong() + 1L + 193L
        val direction = save(
            directionBase.square() +
                first.multiplyByInt(193) +
                snapshot[6].multiplyByInt(197)
        )
        return PositionalNeighborPatchOutcome(
            drop46,seal,queriedBowlId,order,
            scar.copy(drop46Order = scar.drop46Order.toList()),
            nextId,first,direction,
            if (direction.modInt(2) == 1) 1 else -1,
            1,1,scar.permutationPatchCalls
        )
    }
}
