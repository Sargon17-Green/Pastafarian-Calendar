package pastafari

/**
 * Cam 14 — DISCOVERY 07: paramedrau unarddeg malu yn nhrefn FFISEGOL
 * zero-based, heb sentinel. Nid yw'r dosbarth hwn yn cyfrifo'r diferion
 * gweledig ac nid yw'n cyflwyno cywiriad PATCH 07.
 */
data class VisibleGrindRow(
    val a: Int, val b: Int, val c: Int, val d: Int, val stoneKind: Int
)

data class LegacyGrindRead(
    val requestedGrind: Int,
    val directIndex: Int,
    val row: VisibleGrindRow?,
    val undefined: Boolean
)

class LegacyGrindTableAdapter {
    // Y 11 rhes normadol, ond eu storio â mynegai ffisegol 0..10.
    // Nid oes rhes sentinel yn y storfa hon.
    private val physicalRows = listOf(
        VisibleGrindRow(3, 5, 7, 11, 0),
        VisibleGrindRow(5, 7, 11, 13, 1),
        VisibleGrindRow(7, 11, 13, 17, 2),
        VisibleGrindRow(11, 13, 17, 19, 3),
        VisibleGrindRow(13, 17, 19, 23, 4),
        VisibleGrindRow(17, 19, 23, 29, 0),
        VisibleGrindRow(19, 23, 29, 31, 1),
        VisibleGrindRow(23, 29, 31, 37, 2),
        VisibleGrindRow(29, 31, 37, 41, 3),
        VisibleGrindRow(31, 37, 41, 43, 4),
        VisibleGrindRow(37, 41, 43, 47, 0)
    )

    fun physicalRows(): List<VisibleGrindRow> = physicalRows.toList()

    /** Y GRAITH: mae 'grind' yn 1-based ond defnyddir ef fel index 0-based. */
    fun legacyGrindRow(grind: Int): LegacyGrindRead {
        require(grind in 1..11) { "E_DISCOVERY07_GRIND_RANGE" }
        val row = physicalRows.getOrNull(grind)
        return LegacyGrindRead(grind, grind, row, row == null)
    }
}

/**
 * Cam 15 — PATCH 07. Cadw'r tabl etifeddol a'i fynegai anghywir yn fyw;
 * ychwanegu sentinel lleol yn y cyfieithydd, nid yn y storfa wreiddiol.
 */
data class GrindPatchOutcome(
    val requestedGrind: Int,
    val legacyRead: LegacyGrindRead,
    val physicalRows: List<VisibleGrindRow>,
    val sentinelRows: List<VisibleGrindRow?>,
    val translatedIndex: Int,
    val correctedRow: VisibleGrindRow
)

class GrindPatchWrapper(
    private val legacyAdapter: LegacyGrindTableAdapter = LegacyGrindTableAdapter()
) {
    fun patch(grind: Int): GrindPatchOutcome {
        require(grind in 1..11) { "E_PATCH07_GRIND_RANGE" }
        // Y graith wirioneddol: galw'r hen helper CYN cyfieithu.
        val raw = legacyAdapter.legacyGrindRow(grind)
        val physical = legacyAdapter.physicalRows()
        require(physical.size == 11 && raw.requestedGrind == grind &&
            raw.directIndex == grind && raw.row == physical.getOrNull(grind) &&
            raw.undefined == (raw.row == null)) { "E_PATCH07_LEGACY_SHAPE" }
        val sentinel: List<VisibleGrindRow?> =
            listOf<VisibleGrindRow?>(null) + physical
        require(sentinel.size == 12 && sentinel[0] == null) {
            "E_PATCH07_SENTINEL_SHAPE"
        }
        val corrected = requireNotNull(sentinel[grind]) {
            "E_PATCH07_TRANSLATED_ROW_MISSING"
        }
        return GrindPatchOutcome(grind, raw, physical, sentinel, grind, corrected)
    }
}
