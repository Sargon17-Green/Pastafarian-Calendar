package pastafari

/**
 * Cam 22 — DISCOVERY 11: cache hen sum y bowls ar ôl y tro cyntaf.
 * Mae'r 12 stir yn defnyddio ciplun hen bowls i gymysgu, ond
 * mae'r savedBowlSum o stir 1 yn aros yn sownd ar stir 2..12.
 * Dim PATCH 11, dim adeiladwr diferion gweledig.
 */
data class LegacyCachedStirStep(
    val stir: Int,
    val oldSnapshot: List<ExactInt>,
    val savedSumUsed: ExactInt,
    val sumCacheOriginStir: Int,
    val correctedPermutationOrder: List<Int>,
    val newBowls: List<ExactInt>,
    val patchedPermutationCalls: Int
)

data class LegacyCachedStirRun(
    val steps: List<LegacyCachedStirStep>,
    val finalBowls: List<ExactInt>,
    val originalCachedSum: ExactInt,
    val totalStirs: Int,
    val permutationPatchCalls: Int,
    val cachedSumComputations: Int
)

class LegacyCachedStirAdapter(
    private val permutationPatch: PermutationPatchWrapper = PermutationPatchWrapper(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper()
) {
    private fun save(n: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(n))

    /** Cyfrifiad lleol i stir 1, nid normadol i stir 2..12. */
    private fun savedSum(bowls: List<ExactInt>, stir: Int): ExactInt {
        var total = ExactInt.ZERO
        for (id in 1..6) total += bowls[id]
        return save(total + ExactInt.of(149L * stir))
    }

    /** GRAITH: savedBowlSum o stir 1 yn unig i holl stir 1..12. */
    fun oldCachedPostStir12(initialBowls: List<ExactInt>): LegacyCachedStirRun {
        require(initialBowls.size == 7 && initialBowls[0] == ExactInt.ZERO) {
            "E_DISCOVERY11_INITIAL_BOWL_SHAPE"
        }
        var bowls = initialBowls.toList()
        var cached: ExactInt? = null
        var cacheCount = 0
        val steps = ArrayList<LegacyCachedStirStep>(12)
        for (stir in 1..12) {
            val old = bowls.toList()
            if (cached == null) {
                cached = savedSum(old, stir)
                cacheCount++
            }
            val savedBowlSum = cached
                ?: throw IllegalStateException("E_DISCOVERY11_CACHE_UNSET")
            // Mae'r permutation yn PATCH 08: y CACHE yw'r unig nam.
            val orderResult = permutationPatch.patch(savedBowlSum)
            val order = orderResult.correctedOrder.toList()
            require(order.sorted() == listOf(1,2,3,4,5,6) &&
                orderResult.correctedUnrankCalls == 1 &&
                orderResult.legacyRead.legacyCalls == 1) {
                "E_DISCOVERY11_ORDER_SHAPE"
            }
            val next = MutableList(7) { ExactInt.ZERO }
            for (position in 1..6) {
                val id = order[position-1]
                val prevId = order[if (position == 1) 5 else position-2]
                val nextId = order[if (position == 6) 0 else position]
                // Mae pob bowl yn darllen yr UN snapshot cywir.
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
            steps.add(LegacyCachedStirStep(
                stir,old,savedBowlSum,1,order,bowls,1))
        }
        check(cacheCount == 1 && steps.size == 12)
        return LegacyCachedStirRun(
            steps.toList(),bowls.toList(),
            cached ?: throw IllegalStateException("E_DISCOVERY11_CACHE_LOST"),
            steps.size,
            steps.sumOf { it.patchedPermutationCalls },
            cacheCount
        )
    }
}
