package pastafari

/** Cam 9: rhaid cadw'r wastraff hanesyddol a'r rhes gywir ar wahân. */
data class StonePatchOutcome(
    val legacyGarbage: MutableStoneRow,
    val corrected: MutableStoneRow
)

data class StonePatchTable(
    val rows: List<MutableStoneRow>,
    val legacyGarbageRows: List<MutableStoneRow>,
    val legacyCalls: Int
)

/**
 * PATCH 04: mae'r cyfrifiad cywir yn darllen CIPLUN o'r hen res.
 * Galwir mutateStonesWrong ar glôn ar wahân cyn gwneud unrhyw gywiriad.
 * Ni chaiff y llwybr cynhyrchu alw'r oracl prawf.
 */
class StonePatchWrapper(
    private val legacy: LegacyStoneBuilder = LegacyStoneBuilder(),
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper()
) {
    private fun save(x: ExactInt): ExactInt = savePatch.savePatch(remainder.oldRemainder(x))

    fun stonePatch(previous: MutableStoneRow, rowIndex: Int): StonePatchOutcome {
        require(rowIndex in 2..46) { "E_PATCH04_ROW_RANGE" }
        val snapshot = previous.copy()
        // Y graith gyntaf; mae hyn yn newid'r CLÔN, byth y ciplun.
        val garbage = legacy.mutateStonesWrong(snapshot.copy(), rowIndex)
        val corrected = MutableStoneRow(
            save(snapshot.wheat.square() + snapshot.barley.multiplyByInt(3) + rowIndex.toLong()),
            save(snapshot.barley.square() + snapshot.salt.multiplyByInt(5) + snapshot.wheat),
            save(snapshot.salt.square() + snapshot.bitter.multiplyByInt(7) + snapshot.barley),
            save(snapshot.bitter.square() + snapshot.red.multiplyByInt(11) + snapshot.salt),
            save(snapshot.red.square() + snapshot.wheat.multiplyByInt(13) + snapshot.bitter)
        )
        return StonePatchOutcome(garbage, corrected)
    }

    fun buildPatchedRows(): StonePatchTable {
        val zero = ExactInt.ZERO
        val rows = ArrayList<MutableStoneRow>(47)
        val garbage = ArrayList<MutableStoneRow>(47)
        rows.add(MutableStoneRow(zero, zero, zero, zero, zero))
        garbage.add(MutableStoneRow(zero, zero, zero, zero, zero))
        val seed = MutableStoneRow(ExactInt.of(17), ExactInt.of(29), ExactInt.of(43),
            ExactInt.of(71), ExactInt.of(101))
        rows.add(seed.copy())
        garbage.add(seed.copy())
        for (i in 2..46) {
            val outcome = stonePatch(rows[i - 1], i)
            garbage.add(outcome.legacyGarbage)
            rows.add(outcome.corrected)
        }
        return StonePatchTable(rows, garbage, 45)
    }
}
