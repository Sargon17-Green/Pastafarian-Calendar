package pastafari

/**
 * Pinned original production navigation only; probe is external.
 * No original source code is edited. These are candidates, not an oracle.
 */
object AdjacentYearBoundaryProbeV030 {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_V030_NO_ARGS" }
        val c = ExactInt.of(-15055671L)
        val nav = ProductionYearNavigator()
        val center = nav.year5000(c)
        val before = nav.previousYear(c, center)
        val after = nav.nextYear(c, center)
        val years = listOf(before, center, after)
        check(years.map { it.number.toString() } == listOf("4999","5000","5001")) {
            "E_V030_WRONG_YEARS"
        }
        check(before.closeGateIndex == center.openGateIndex &&
            before.closeDay == center.openDay &&
            after.openGateIndex == center.closeGateIndex &&
            after.openDay == center.closeDay) {
            "E_V030_NONCONTIGUOUS_YEAR_BOUNDS"
        }
        check(center.openGateIndex.toString() == "-4" &&
            center.closeGateIndex.toString() == "4" &&
            center.openDay.toString() == "-15057703" &&
            center.closeDay.toString() == "-15053459") {
            "E_V030_ORIGINAL_CENTRAL_CANDIDATE_DIFFERED"
        }
        for (y in years) {
            val length = y.closeDay - y.openDay
            check(length >= ExactInt.of(252L) && length <= ExactInt.of(5778L)) {
                "E_V030_YEAR_LENGTH_INVALID"
            }
            val row = listOf(c.toString(), y.number.toString(),
                y.openGateIndex.toString(), y.closeGateIndex.toString(),
                y.openDay.toString(), y.closeDay.toString(),
                (y.openDay + 1L).toString(), y.closeDay.toString(),
                length.toString())
            println(row.joinToString("\t"))
        }
        System.err.println("PINNED_KOTLIN_NATIVE_THREE_YEAR_BOUNDARY_PROBE_NOT_FULL_DATE")
    }
}
