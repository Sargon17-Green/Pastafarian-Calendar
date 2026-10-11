package pastafari

/**
 * PATCH 02: cynnal y graith hanesyddol ac addasu ei hallbwn yn unig.
 * Mae'r prawf uniongyrchol ar gyfer diwrnod y Sylfaen yn fwriadol
 * ddiangen, ond rhaid ei gadw fel rhan o'r patch hanesyddol.
 */
class DayTagPatchWrapper {
    private val foundationDay = ExactInt.of(-15055671L)

    fun dayTagWithFoundationScar(day: ExactInt, legacyDayTag: ExactInt): ExactInt {
        require(legacyDayTag >= ExactInt.ZERO) { "E_PATCH02_NEGATIVE_LEGACY_TAG" }
        val afterOrOnFoundation = day >= foundationDay
        val redundantFoundationGuard = day == foundationDay
        return if (afterOrOnFoundation || redundantFoundationGuard) {
            legacyDayTag + ExactInt.ONE
        } else {
            legacyDayTag
        }
    }
}
