package pastafari

/** Cam 20 — DISCOVERY 10: ysgrifennu bowls byw yn lle snapshot. */
data class LegacyInPlaceWrite(
    val position: Int,
    val bowlId: Int,
    val previousId: Int,
    val nextId: Int,
    val previousLiveRead: ExactInt,
    val nextLiveRead: ExactInt,
    val newValue: ExactInt
)

data class LegacyInPlaceBowlStep(
    val iteration: Int,
    val oldSnapshot: List<ExactInt>,
    val pourPatch: PourPatchOutcome,
    val writes: List<LegacyInPlaceWrite>,
    val newBowls: List<ExactInt>
)

data class LegacyInPlaceBowlRun(
    val steps: List<LegacyInPlaceBowlStep>,
    val finalBowls: List<ExactInt>,
    val orderAt46: List<Int>,
    val patchedPourCalls: Int,
    val preservedLegacyPourCalls: Int,
    val permutationPatchCalls: Int,
    val inPlaceWrites: Int
)

/**
 * Y NAM yw bod live[id] yn cael ei osod cyn darllen y safle nesaf.
 * Mae'r tri phour yn dod o PATCH 09 ar snapshot CYWIR.
 * Nid oes cyfnewid ffynhonnell arllwys yma; mae'r gwall mewn
 * darlleniad byw o bowls cyfagos yn unig.
 */
class LegacyInPlaceBowlAdapter(
    private val pourPatch: PourPatchWrapper = PourPatchWrapper(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper(),
    private val stonePatch: StonePatchWrapper = StonePatchWrapper()
) {
    private fun save(value: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(value))

    private val stoneByPosition = intArrayOf(0,1,2,3,4,0)

    fun mutateBowlsWrong(
        drop: ExactInt,
        iteration: Int,
        oldBowls: List<ExactInt>,
        stoneRow: MutableStoneRow
    ): LegacyInPlaceBowlStep {
        require(iteration in 1..46) { "E_DISCOVERY10_ITERATION_RANGE" }
        require(oldBowls.size == 7 && oldBowls[0] == ExactInt.ZERO) {
            "E_DISCOVERY10_BOWL_SHAPE"
        }
        val snapshot = oldBowls.toList()
        // PATCH 09 cywir, sy'n galw hen fixed-pour gyntaf.
        val pour = pourPatch.patch(drop,iteration,snapshot,stoneRow)
        val order = pour.order
        require(order.size == 6 &&
            order.sorted() == listOf(1,2,3,4,5,6) &&
            pour.correctedPours.size == 7 &&
            pour.correctedPourCalls == 1 &&
            pour.legacyRead.fixedPourCalls == 1) {
            "E_DISCOVERY10_POUR_SHAPE"
        }
        val stone = stoneRow.components()
        val live = snapshot.toMutableList()
        val writes = ArrayList<LegacyInPlaceWrite>(6)
        for (position in 1..6) {
            val id = order[position-1]
            val previousId = order[if (position == 1) 5 else position-2]
            val nextId = order[if (position == 6) 0 else position]
            // BYW: mae previousId wedi cael ei newid o safle 2 ymlaen.
            val previousRead = live[previousId]
            val nextRead = live[nextId]
            val mixing = live[id] +
                previousRead.multiplyByInt(2) +
                nextRead.multiplyByInt(3) +
                pour.correctedPours[position] +
                drop + stone[stoneByPosition[position-1]]
            val result = save(
                mixing.square() +
                (previousRead * nextRead).multiplyByInt(5) +
                ExactInt.of((iteration * position).toLong())
            )
            live[id] = result // y graith: byw, dim nextBowls ar wahân
            writes.add(LegacyInPlaceWrite(
                position,id,previousId,nextId,previousRead,nextRead,result))
        }
        return LegacyInPlaceBowlStep(
            iteration,snapshot,pour,writes.toList(),live.toList())
    }

    /** Ailadrodd y graith am 46 diferion, heb adeiladu'r diferion yma. */
    fun runWrongInPlace(
        initialBowls: List<ExactInt>,
        visibleDrops: List<ExactInt>,
        stones: List<MutableStoneRow> = stonePatch.buildPatchedRows().rows
    ): LegacyInPlaceBowlRun {
        require(initialBowls.size == 7 && initialBowls[0] == ExactInt.ZERO) {
            "E_DISCOVERY10_INITIAL_BOWLS"
        }
        require(visibleDrops.size == 47 && stones.size == 47) {
            "E_DISCOVERY10_TABLE_SHAPE"
        }
        var current = initialBowls.toList()
        val steps = ArrayList<LegacyInPlaceBowlStep>(46)
        for (i in 1..46) {
            val step = mutateBowlsWrong(visibleDrops[i],i,current,stones[i])
            steps.add(step)
            current = step.newBowls.toList()
        }
        return LegacyInPlaceBowlRun(
            steps.toList(), current.toList(),
            steps.last().pourPatch.order.toList(),
            steps.sumOf { it.pourPatch.correctedPourCalls },
            steps.sumOf { it.pourPatch.legacyRead.fixedPourCalls },
            steps.sumOf { it.pourPatch.legacyRead.patch08Calls },
            steps.sumOf { it.writes.size }
        )
    }
}
