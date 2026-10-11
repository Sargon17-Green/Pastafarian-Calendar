package pastafari

/**
 * Cam 6 / DISCOVERY 03: hen ddiffyg pellter, wedi'i gadw yn fwriadol.
 * Mae'r hen gyfrifiad yn cymryd gwahaniaeth absoliwt rhwng dau dag
 * wedi'u cywiro gan PATCH 02, yn lle pellter cronolegol cynhwysol.
 * Dim galwad at yr oracl normadol yn y cod cynhyrchu hwn.
 */
class LegacyDistanceAdapter(
    private val legacyDayTag: LegacyDayTagAdapter = LegacyDayTagAdapter(),
    private val dayTagPatch: DayTagPatchWrapper = DayTagPatchWrapper()
) {
    private fun taggedDay(day: ExactInt): ExactInt {
        val oldTag = legacyDayTag.oldDayTag(day)
        return dayTagPatch.dayTagWithFoundationScar(day, oldTag)
    }

    fun oldDistance(calculationDay: ExactInt, targetDay: ExactInt): ExactInt =
        (taggedDay(calculationDay) - taggedDay(targetDay)).abs()
}
