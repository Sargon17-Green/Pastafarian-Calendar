package pastafari

/**
 * Cam 24 — DISCOVERY 12.
 * Mae order y diferyn 46 yn gywir, ond mae'r caller etifeddol
 * yn gofyn i bowlId+1 (neu 1 ar ôl 6) yn hytrach na'r
 * bowl nesaf yn nhrefn y diferyn 46.
 */
data class LegacyNumericNeighborRead(
    val drop46: ExactInt,
    val seal: Int,
    val queriedBowlId: Int,
    val drop46Order: List<Int>,
    val actualNeighborIdWrong: Int,
    val positionalNeighborIdExpected: Int,
    val firstAnswer: ExactInt,
    val directionNumber: ExactInt,
    val directionStep: Int,
    val permutationPatchCalls: Int,
    val numericNeighborCalls: Int
)

class LegacyNumericNeighborAdapter(
    private val permutationPatch: PermutationPatchWrapper = PermutationPatchWrapper(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper()
) {
    private fun save(value: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(value))

    fun oldNumericNeighborQuestion(
        finalBowls: List<ExactInt>,
        drop46: ExactInt,
        queriedBowlId: Int,
        seal: Int
    ): LegacyNumericNeighborRead {
        require(finalBowls.size == 7 && finalBowls[0] == ExactInt.ZERO) {
            "E_DISCOVERY12_FINAL_BOWL_SHAPE"
        }
        require(queriedBowlId in 1..6) { "E_DISCOVERY12_QUERY_BOWL_RANGE" }
        require(seal > 0) { "E_DISCOVERY12_SEAL_RANGE" }
        val patched = permutationPatch.patch(drop46)
        val order = patched.correctedOrder.toList()
        require(order.sorted() == listOf(1,2,3,4,5,6) &&
            patched.correctedUnrankCalls == 1 &&
            patched.legacyRead.legacyCalls == 1) {
            "E_DISCOVERY12_PERMUTATION_SHAPE"
        }
        val index = order.indexOf(queriedBowlId)
        require(index >= 0) { "E_DISCOVERY12_QUERY_NOT_IN_ORDER" }
        val trueNeighbor = order[(index + 1) % 6]
        // Y nam etifeddol: cymydog yn ôl ID rhifol, nid safle permutation.
        val numericNeighbor = if (queriedBowlId == 6) 1 else queriedBowlId + 1
        val firstBase = finalBowls[queriedBowlId] + seal.toLong() + 181L
        val first = save(
            firstBase.square() +
                finalBowls[numericNeighbor].multiplyByInt(179) +
                seal.toLong()
        )
        val directionBase = first + seal.toLong() + 1L + 193L
        val directionNumber = save(
            directionBase.square() +
                first.multiplyByInt(193) +
                finalBowls[6].multiplyByInt(197)
        )
        return LegacyNumericNeighborRead(
            drop46, seal, queriedBowlId, order,
            numericNeighbor, trueNeighbor,
            first, directionNumber,
            if (directionNumber.modInt(2) == 1) 1 else -1,
            1, 1
        )
    }
}
