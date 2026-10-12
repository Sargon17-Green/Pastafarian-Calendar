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


/** Cam 19 — PATCH 09: cadw'r tri arllwys anghywir; cywiro'r IDs ffynhonnell. */
data class PourPatchOutcome(
    val drop: ExactInt,
    val iteration: Int,
    val order: List<Int>,
    val sourceIdsByPosition: List<Int>,
    val legacyRead: LegacyFixedPourRead,
    val correctedPours: List<ExactInt>,
    val correctedPourCalls: Int
)

data class PatchedPourStep(
    val iteration: Int,
    val order: List<Int>,
    val oldBowls: List<ExactInt>,
    val pourPatch: PourPatchOutcome,
    val newBowls: List<ExactInt>
)

data class PatchedPourRun(
    val steps: List<PatchedPourStep>,
    val finalBowls: List<ExactInt>,
    val orderAt46: List<Int>,
    val legacyFixedPourCalls: Int,
    val correctedPourCalls: Int,
    val permutationPatchCalls: Int
)

/**
 * Mae oldFixedPour yn parhau'n fyw ac yn anghywir.
 * Wedi'r hen alwad, darllenir yr hen GIPLUN yn safleoedd
 * 1..3 yn yr order, nid yn ôl IDau sefydlog 1..3.
 * Ni ddefnyddir yr oracl prawf mewn cynhyrchu.
 */
class PourPatchWrapper(
    private val legacy: LegacyFixedPourAdapter = LegacyFixedPourAdapter(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper(),
    private val stonePatch: StonePatchWrapper = StonePatchWrapper()
) {
    private fun save(value: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(value))

    private val stoneByPosition = intArrayOf(0, 1, 2, 3, 4, 0)

    fun patch(
        drop: ExactInt, iteration: Int,
        oldBowls: List<ExactInt>, stoneRow: MutableStoneRow
    ): PourPatchOutcome {
        require(iteration in 1..46) { "E_PATCH09_ITERATION_RANGE" }
        require(oldBowls.size == 7 && oldBowls[0] == ExactInt.ZERO) {
            "E_PATCH09_BOWL_SHAPE"
        }
        // Rhaid galw'r graith go iawn cyn unrhyw gywiriad.
        val scar = legacy.oldFixedPour(drop, iteration, oldBowls, stoneRow)
        val order = scar.order.toList()
        require(scar.drop == drop && scar.iteration == iteration &&
            scar.fixedPourCalls == 1 && scar.patch08Calls == 1 &&
            scar.sourceIdsWrong == listOf(1,2,3) &&
            scar.sourceIdsByPosition == order.take(3) &&
            scar.pours.size == 7 && order.sorted() == listOf(1,2,3,4,5,6)) {
            "E_PATCH09_LEGACY_SHAPE"
        }
        val oldSnapshot = oldBowls.toList()
        val stones = stoneRow.components()
        val corrected = MutableList(7) { ExactInt.ZERO }
        for (position in 1..3) {
            val id = order[position - 1]
            corrected[position] = save(
                drop.square() + stones[position-1] * oldSnapshot[id] +
                    ExactInt.of(((position * 2 + 1) * iteration).toLong())
            )
        }
        return PourPatchOutcome(
            drop, iteration, order, order.take(3),
            scar.copy(
                order = scar.order.toList(),
                sourceIdsWrong = scar.sourceIdsWrong.toList(),
                sourceIdsByPosition = scar.sourceIdsByPosition.toList(),
                pours = scar.pours.toList()
            ),
            corrected.toList(), 1
        )
    }

    /** 46 tro gyda'r hen giplun: nid yw nam in-place Cam 20 yma. */
    fun runPatchedPours(
        initialBowls: List<ExactInt>,
        visibleDrops: List<ExactInt>,
        stones: List<MutableStoneRow> = stonePatch.buildPatchedRows().rows
    ): PatchedPourRun {
        require(initialBowls.size == 7 && initialBowls[0] == ExactInt.ZERO) {
            "E_PATCH09_INITIAL_BOWLS"
        }
        require(visibleDrops.size == 47 && stones.size == 47) {
            "E_PATCH09_TABLE_SHAPE"
        }
        var bowls = initialBowls.toList()
        val steps = ArrayList<PatchedPourStep>(46)
        for (i in 1..46) {
            val old = bowls.toList()
            val outcome = patch(visibleDrops[i], i, old, stones[i])
            val order = outcome.order
            val row = stones[i].components()
            val next = MutableList(7) { ExactInt.ZERO }
            for (position in 1..6) {
                val id = order[position - 1]
                val prevId = order[if (position == 1) 5 else position - 2]
                val nextId = order[if (position == 6) 0 else position]
                val mixing = old[id] +
                    old[prevId].multiplyByInt(2) +
                    old[nextId].multiplyByInt(3) +
                    outcome.correctedPours[position] +
                    visibleDrops[i] + row[stoneByPosition[position - 1]]
                next[id] = save(
                    mixing.square() +
                    (old[prevId] * old[nextId]).multiplyByInt(5) +
                    ExactInt.of((i * position).toLong())
                )
            }
            bowls = next.toList()
            steps.add(
                PatchedPourStep(i, order.toList(), old, outcome, bowls)
            )
        }
        return PatchedPourRun(
            steps.toList(), bowls.toList(), steps.last().order.toList(),
            steps.sumOf { it.pourPatch.legacyRead.fixedPourCalls },
            steps.sumOf { it.pourPatch.correctedPourCalls },
            steps.sumOf { it.pourPatch.legacyRead.patch08Calls }
        )
    }
}
