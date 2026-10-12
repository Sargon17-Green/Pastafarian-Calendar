package pastafari

/**
 * Cam 23 — PATCH 11: ailgyfrifo savedBowlSum ar BOB stir.
 * Mae'r hen oldCachedPostStir12 yn parhau'n anghywir, yn cael
 * ei alw cyn y cywiriad, ac yn aros yn gwbl weladwy yn y tyst.
 */
data class FreshStirStep(
    val stir: Int,
    val oldSnapshot: List<ExactInt>,
    val freshSavedSum: ExactInt,
    val correctedPermutationOrder: List<Int>,
    val newBowls: List<ExactInt>,
    val permutationPatchCalls: Int
)

data class FreshStirPatchRun(
    val legacyRun: LegacyCachedStirRun,
    val steps: List<FreshStirStep>,
    val finalBowls: List<ExactInt>,
    val legacyCacheComputations: Int,
    val correctedSumComputations: Int,
    val legacyPermutationCalls: Int,
    val correctedPermutationCalls: Int,
    val legacyRuns: Int
)

class FreshStirPatchWrapper(
    private val legacy: LegacyCachedStirAdapter = LegacyCachedStirAdapter(),
    private val permutationPatch: PermutationPatchWrapper = PermutationPatchWrapper(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper()
) {
    private fun save(n: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(n))

    fun patch(initialBowls: List<ExactInt>): FreshStirPatchRun {
        require(initialBowls.size == 7 && initialBowls[0] == ExactInt.ZERO) {
            "E_PATCH11_INITIAL_BOWL_SHAPE"
        }
        val input = initialBowls.toList()
        // Galwad etifeddol go iawn; ni ddefnyddir ei bowls fel mewnbwn cywir.
        val scar = legacy.oldCachedPostStir12(input.toList())
        require(scar.totalStirs == 12 && scar.steps.size == 12 &&
            scar.cachedSumComputations == 1 && scar.permutationPatchCalls == 12 &&
            scar.steps.all { it.savedSumUsed == scar.originalCachedSum &&
                it.sumCacheOriginStir == 1 }) { "E_PATCH11_LEGACY_SHAPE" }
        var bowls = input.toList()
        val steps = ArrayList<FreshStirStep>(12)
        for (stir in 1..12) {
            val old = bowls.toList()
            var total = ExactInt.ZERO
            for (id in 1..6) total += old[id]
            // PATCH 11: gyfrifo eto, gyda stir y cylch PRESENNOL.
            val savedBowlSum = save(total + ExactInt.of(149L * stir))
            val permutation = permutationPatch.patch(savedBowlSum)
            val order = permutation.correctedOrder.toList()
            require(order.sorted() == listOf(1,2,3,4,5,6) &&
                permutation.correctedUnrankCalls == 1 &&
                permutation.legacyRead.legacyCalls == 1) {
                "E_PATCH11_PERMUTATION_SHAPE"
            }
            val next = MutableList(7) { ExactInt.ZERO }
            for (position in 1..6) {
                val id = order[position-1]
                val prevId = order[if (position == 1) 5 else position-2]
                val nextId = order[if (position == 6) 0 else position]
                val mixed = old[id] +
                    old[prevId].multiplyByInt(3) +
                    old[nextId].multiplyByInt(5) +
                    savedBowlSum + ExactInt.of(stir.toLong()) +
                    ExactInt.of((position * position).toLong())
                next[id] = save(
                    mixed.square() +
                    (old[prevId] * old[nextId]).multiplyByInt(7)
                )
            }
            bowls = next.toList()
            steps.add(FreshStirStep(
                stir,old,savedBowlSum,order,bowls,1))
        }
        check(steps.size == 12 && bowls.size == 7 && bowls[0] == ExactInt.ZERO)
        return FreshStirPatchRun(
            scar.copy(steps = scar.steps.toList(),
                finalBowls = scar.finalBowls.toList()),
            steps.toList(),bowls.toList(),
            scar.cachedSumComputations,steps.size,
            scar.permutationPatchCalls,
            steps.sumOf { it.permutationPatchCalls },1)
    }
}
