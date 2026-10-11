package pastafari

/**
 * Craith fwriadol DISCOVERY 02: mae'r hen dag yn anghofio'r +1
 * ar ddiwrnod y Sylfaen ac ar bob diwrnod ar ei ôl.
 * Nid oes dibyniaeth ar unrhyw god prawf na chyfeirnod normadol.
 */
class LegacyDayTagAdapter {
    private val foundationDay = ExactInt.of(-15055671L)

    fun oldDayTag(day: ExactInt): ExactInt =
        (day - foundationDay).abs().multiplyByInt(2)
}
