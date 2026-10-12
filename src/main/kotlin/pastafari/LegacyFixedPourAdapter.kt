package pastafari

/** Cam 18 — DISCOVERY 09: defnyddio IDau sefydlog wrth arllwys, yn lle safleoedd. */
data class LegacyFixedPourRead(
    val drop: ExactInt,
    val iteration: Int,
    val order: List<Int>,
    val sourceIdsWrong: List<Int>,
    val sourceIdsByPosition: List<Int>,
    val pours: List<ExactInt>,
    val patch08Calls: Int,
    val fixedPourCalls: Int
)

data class LegacyPourStep(
    val iteration: Int,
    val order: List<Int>,
    val oldBowls: List<ExactInt>,
    val fixedPour: LegacyFixedPourRead,
    val newBowls: List<ExactInt>
)

data class LegacyPourRun(
    val steps: List<LegacyPourStep>,
    val finalBowls: List<ExactInt>,
    val orderAt46: List<Int>,
    val fixedPourCalls: Int,
    val permutationPatchCalls: Int
)

/**
 * Mae'r NAM yn y ffynhonnell arllwys yn unig: old[1],old[2],old[3].
 * Mae'r gorlan chwe bowlen arall yn defnyddio hen giplun a'r order cywir.
 * Dim bowlAlias/PATCH 09 ac ni adeiladir diferion gweledig yma.
 */
class LegacyFixedPourAdapter(
    private val permutationPatch: PermutationPatchWrapper = PermutationPatchWrapper(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper(),
    private val stonePatch: StonePatchWrapper = StonePatchWrapper()
) {
    private fun save(n: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(n))

    private val stoneByPosition = intArrayOf(0, 1, 2, 3, 4, 0)

    fun oldFixedPour(
        drop: ExactInt, iteration: Int, oldBowls: List<ExactInt>,
        stoneRow: MutableStoneRow
    ): LegacyFixedPourRead {
        require(iteration in 1..46) { "E_DISCOVERY09_ITERATION_RANGE" }
        require(oldBowls.size == 7) { "E_DISCOVERY09_BOWL_SHAPE" }
        val result = permutationPatch.patch(drop)
        val order = result.correctedOrder.toList()
        require(order.size == 6 && order.sorted() == listOf(1,2,3,4,5,6)) {
            "E_DISCOVERY09_ORDER_SHAPE"
        }
        val stones = stoneRow.components()
        val wrong = MutableList(7) { ExactInt.ZERO }
        // Nam etifeddol: mae'r tair ffynhonnell yn ID 1,2,3 sefydlog.
        wrong[1] = save(drop.square() + stones[0] * oldBowls[1] +
            ExactInt.of((3L * iteration)))
        wrong[2] = save(drop.square() + stones[1] * oldBowls[2] +
            ExactInt.of((5L * iteration)))
        wrong[3] = save(drop.square() + stones[2] * oldBowls[3] +
            ExactInt.of((7L * iteration)))
        return LegacyFixedPourRead(
            drop, iteration, order, listOf(1,2,3),
            order.take(3), wrong.toList(), 1, 1
        )
    }

    /** 46 cymysgiad: dim newid in-place; yr arllwys sydd yn anghywir. */
    fun runWrongPours(
        initialBowls: List<ExactInt>,
        visibleDrops: List<ExactInt>,
        stones: List<MutableStoneRow> = stonePatch.buildPatchedRows().rows
    ): LegacyPourRun {
        require(initialBowls.size == 7 && initialBowls[0] == ExactInt.ZERO) {
            "E_DISCOVERY09_INITIAL_BOWLS"
        }
        require(visibleDrops.size == 47 && stones.size == 47) {
            "E_DISCOVERY09_TABLE_SHAPE"
        }
        var bowls = initialBowls.toList()
        val steps = ArrayList<LegacyPourStep>(46)
        for (i in 1..46) {
            val old = bowls.toList()
            val read = oldFixedPour(visibleDrops[i], i, old, stones[i])
            val order = read.order
            val stone = stones[i].components()
            val next = MutableList(7) { ExactInt.ZERO }
            for (p in 1..6) {
                val id = order[p-1]
                val previous = order[if (p == 1) 5 else p-2]
                val following = order[if (p == 6) 0 else p]
                val linear = old[id] + old[previous].multiplyByInt(2) +
                    old[following].multiplyByInt(3) + read.pours[p] +
                    visibleDrops[i] + stone[stoneByPosition[p-1]]
                next[id] = save(linear.square() +
                    (old[previous] * old[following]).multiplyByInt(5) +
                    ExactInt.of((i.toLong() * p)))
            }
            bowls = next.toList()
            steps.add(LegacyPourStep(i, order.toList(), old,
                read.copy(pours = read.pours.toList()), bowls))
        }
        return LegacyPourRun(
            steps.toList(), bowls.toList(), steps.last().order.toList(),
            steps.sumOf { it.fixedPour.fixedPourCalls },
            steps.sumOf { it.fixedPour.patch08Calls }
        )
    }
}
