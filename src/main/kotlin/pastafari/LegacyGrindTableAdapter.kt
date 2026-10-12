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
