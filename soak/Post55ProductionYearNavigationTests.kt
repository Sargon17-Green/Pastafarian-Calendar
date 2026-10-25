package pastafari

/** Normative test-only regression, not independent full-date certification. */
object Post55ProductionYearNavigationTests {
    private fun same(a: ProductionYearInterval, b: NormativeCalendar.Year): Boolean =
        a.number == b.number && a.openGateIndex == b.openGateIndex &&
        a.closeGateIndex == b.closeGateIndex &&
        a.openDay == b.openGateDay && a.closeDay == b.closeGateDay

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val foundation = NormativeCore.FOUNDATION_DAY
        val navigator = ProductionYearNavigator()
        val oracle = NormativeCalendar()
        var adjacent = 0
        var targets = 0
        for (offset in listOf(-1L, 0L, 1L)) {
            val c = foundation + offset
            val anchor = navigator.year5000(c)
            val expected = oracle.year5000(c)
            check(same(anchor, expected)) { "E_POST55_YEAR_NAV_ANCHOR_$offset" }
            check(same(navigator.nextYear(c, anchor), oracle.nextYear(c, expected))) {
                "E_POST55_YEAR_NAV_NEXT_$offset"
            }
            check(same(navigator.previousYear(c, anchor), oracle.previousYear(c, expected))) {
                "E_POST55_YEAR_NAV_PREVIOUS_$offset"
            }
            adjacent += 2
            for (delta in listOf(-1000L, -250L, -1L, 0L, 1L, 250L, 1000L)) {
                val t = foundation + delta
                check(same(navigator.findTargetYear(c, t), oracle.findTargetYear(c, t))) {
                    "E_POST55_YEAR_NAV_TARGET_" + offset + "_" + delta
                }
                targets++
            }
        }
        check(adjacent == 6 && targets == 21)
        println("POST55_PRODUCTION_YEAR_ADJACENT_6_ORACLE_GREEN")
        println("POST55_PRODUCTION_YEAR_TARGET_21_ORACLE_GREEN")
        check(navigator.expandedGateCount > 1)
        var blocked = false
        try { ProductionYearNavigator(maxYearTransitions = 0) }
        catch (_: IllegalArgumentException) { blocked = true }
        check(blocked) { "E_POST55_YEAR_NAV_BUDGET_GUARD" }
        println("POST55_PRODUCTION_YEAR_NAVIGATION_TEST_ONLY_GREEN")
    }
}
