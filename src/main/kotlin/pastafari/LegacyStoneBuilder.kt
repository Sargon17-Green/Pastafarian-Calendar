package pastafari

/** Cam 8 — yr un gwrthrych newidiol yw ffynhonnell a chyrchfan y pum cyfrifiad. */
data class MutableStoneRow(
    var wheat: ExactInt,
    var barley: ExactInt,
    var salt: ExactInt,
    var bitter: ExactInt,
    var red: ExactInt
) {
    fun components(): List<ExactInt> = listOf(wheat, barley, salt, bitter, red)
}

/**
 * DISCOVERY 04: cadw'r nam hanesyddol, nid ei gywiro.
 * Yn benodol, mae'r barlys yn defnyddio gwenith NEWYDD, yr halen yn
 * defnyddio barlys NEWYDD, y chwerw yn defnyddio halen NEWYDD,
 * a'r coch yn defnyddio gwenith/chwerw NEWYDD.
 */
class LegacyStoneBuilder(
    private val remainder: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    private val savePatch: SavePatchWrapper = SavePatchWrapper()
) {
    private fun save(value: ExactInt): ExactInt =
        savePatch.savePatch(remainder.oldRemainder(value))

    fun mutateStonesWrong(state: MutableStoneRow, rowIndex: Int): MutableStoneRow {
        require(rowIndex in 2..46) { "E_DISCOVERY04_ROW_RANGE" }
        state.wheat = save(state.wheat.square() + state.barley.multiplyByInt(3) + rowIndex.toLong())
        state.barley = save(state.barley.square() + state.salt.multiplyByInt(5) + state.wheat)
        state.salt = save(state.salt.square() + state.bitter.multiplyByInt(7) + state.barley)
        state.bitter = save(state.bitter.square() + state.red.multiplyByInt(11) + state.salt)
        state.red = save(state.red.square() + state.wheat.multiplyByInt(13) + state.bitter)
        return state
    }

    fun buildLegacyRows(): List<MutableStoneRow> {
        val zero = ExactInt.ZERO
        val rows = ArrayList<MutableStoneRow>(47)
        rows.add(MutableStoneRow(zero, zero, zero, zero, zero)) // sentinela, nid carreg 0
        val live = MutableStoneRow(
            ExactInt.of(17), ExactInt.of(29), ExactInt.of(43), ExactInt.of(71), ExactInt.of(101)
        )
        rows.add(live.copy())
        for (i in 2..46) {
            mutateStonesWrong(live, i)
            rows.add(live.copy()) // dim aliasu rhesi o fewn y tabl
        }
        return rows
    }
}
