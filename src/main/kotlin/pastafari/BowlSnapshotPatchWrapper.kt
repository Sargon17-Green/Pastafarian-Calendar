package pastafari

/** Cam 21 — PATCH 10: pob darlleniad o'r UN hen snapshot. */
data class SnapshotBowlWrite(
    val position: Int,
    val bowlId: Int,
    val previousId: Int,
    val nextId: Int,
    val previousSnapshotRead: ExactInt,
    val nextSnapshotRead: ExactInt,
    val newValue: ExactInt
)

data class SnapshotBowlPatchOutcome(
    val iteration: Int,
    val oldSnapshot: List<ExactInt>,
    val legacyStep: LegacyInPlaceBowlStep,
    val correctedWrites: List<SnapshotBowlWrite>,
    val correctedBowls: List<ExactInt>,
    val legacyMutatorCalls: Int,
    val correctedSnapshotCalls: Int
)

data class SnapshotBowlRun(
    val steps: List<SnapshotBowlPatchOutcome>,
    val finalBowls: List<ExactInt>,
    val orderAt46: List<Int>,
    val legacyMutatorCalls: Int,
    val correctedSnapshotCalls: Int,
    val patchedPourCalls: Int,
    val preservedFixedPourCalls: Int,
    val permutationPatchCalls: Int,
    val preservedLegacyWrites: Int,
    val correctedWrites: Int
)

/**
 * Mae'r hen mutator anghywir yn cael ei alw ar glôn cyn y cywiriad.
 * Nid yw'r hen graith yn dylanwadu ar gyfrifo'r canlyniad newydd.
 * Y pours PATCH 09 o'r un galwad legacy yw'r pours cywir.
 * Ni ddefnyddir yr oracl prawf yn y llwybr cynhyrchu.
 */
class BowlSnapshotPatchWrapper(
    private val legacy: LegacyInPlaceBowlAdapter = LegacyInPlaceBowlAdapter(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper(),
    private val stonePatch: StonePatchWrapper = StonePatchWrapper()
) {
    private fun save(value: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(value))

    private val stoneByPosition = intArrayOf(0,1,2,3,4,0)

    fun patch(
        drop: ExactInt, iteration: Int,
        oldBowls: List<ExactInt>,
        stoneRow: MutableStoneRow
    ): SnapshotBowlPatchOutcome {
        require(iteration in 1..46) { "E_PATCH10_ITERATION_RANGE" }
        require(oldBowls.size == 7 && oldBowls[0] == ExactInt.ZERO) {
            "E_PATCH10_BOWL_SHAPE"
        }
        val original = oldBowls.toList()
        // Y graith hanesyddol yn gyntaf, bob tro, ar giplun ar wahân.
        val scar = legacy.mutateBowlsWrong(drop,iteration,original.toList(),stoneRow)
        val pour = scar.pourPatch
        val order = pour.order.toList()
        require(scar.iteration == iteration && scar.oldSnapshot == original &&
            scar.writes.size == 6 && scar.newBowls.size == 7 &&
            scar.writes.map { it.position } == (1..6).toList() &&
            order.sorted() == listOf(1,2,3,4,5,6) &&
            pour.correctedPourCalls == 1 &&
            pour.legacyRead.fixedPourCalls == 1 &&
            pour.legacyRead.patch08Calls == 1 &&
            pour.sourceIdsByPosition == order.take(3) &&
            pour.correctedPours.size == 7) {
            "E_PATCH10_LEGACY_SHAPE"
        }
        val stones = stoneRow.components()
        val next = MutableList(7) { ExactInt.ZERO }
        val writes = ArrayList<SnapshotBowlWrite>(6)
        for (position in 1..6) {
            val id = order[position-1]
            val prevId = order[if (position == 1) 5 else position-2]
            val nextId = order[if (position == 6) 0 else position]
            // Holl 6 darlleniad o 'original': ni ddarllenir 'next'.
            val previousRead = original[prevId]
            val nextRead = original[nextId]
            val mixed = original[id] +
                previousRead.multiplyByInt(2) +
                nextRead.multiplyByInt(3) +
                pour.correctedPours[position] +
                drop + stones[stoneByPosition[position-1]]
            val fixed = save(
                mixed.square() +
                (previousRead * nextRead).multiplyByInt(5) +
                ExactInt.of((iteration * position).toLong())
            )
            next[id] = fixed
            writes.add(SnapshotBowlWrite(
                position,id,prevId,nextId,previousRead,nextRead,fixed))
        }
        require(writes.size == 6 && writes.map { it.bowlId }.sorted() ==
            listOf(1,2,3,4,5,6) && next[0] == ExactInt.ZERO) {
            "E_PATCH10_CORRECTED_SHAPE"
        }
        return SnapshotBowlPatchOutcome(
            iteration,original,
            scar.copy(oldSnapshot = scar.oldSnapshot.toList(),
                writes = scar.writes.toList(),
                newBowls = scar.newBowls.toList()),
            writes.toList(),next.toList(),1,1
        )
    }

    /** 46 tro cywir gyda 46 o alwadau gwirioneddol i'r hen mutator. */
    fun runPatchedSnapshots(
        initialBowls: List<ExactInt>,
        visibleDrops: List<ExactInt>,
        stones: List<MutableStoneRow> = stonePatch.buildPatchedRows().rows
    ): SnapshotBowlRun {
        require(initialBowls.size == 7 && initialBowls[0] == ExactInt.ZERO) {
            "E_PATCH10_INITIAL_BOWLS"
        }
        require(visibleDrops.size == 47 && stones.size == 47) {
            "E_PATCH10_TABLE_SHAPE"
        }
        var current = initialBowls.toList()
        val steps = ArrayList<SnapshotBowlPatchOutcome>(46)
        for (i in 1..46) {
            val outcome = patch(visibleDrops[i],i,current,stones[i])
            steps.add(outcome)
            current = outcome.correctedBowls.toList()
        }
        return SnapshotBowlRun(
            steps.toList(),current.toList(),
            steps.last().legacyStep.pourPatch.order.toList(),
            steps.sumOf { it.legacyMutatorCalls },
            steps.sumOf { it.correctedSnapshotCalls },
            steps.sumOf { it.legacyStep.pourPatch.correctedPourCalls },
            steps.sumOf { it.legacyStep.pourPatch.legacyRead.fixedPourCalls },
            steps.sumOf { it.legacyStep.pourPatch.legacyRead.patch08Calls },
            steps.sumOf { it.legacyStep.writes.size },
            steps.sumOf { it.correctedWrites.size }
        )
    }
}
