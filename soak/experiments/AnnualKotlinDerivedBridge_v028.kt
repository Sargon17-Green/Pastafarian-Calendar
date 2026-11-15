package pastafari

import java.math.BigInteger

/**
 * EXPERIMENTAL derived annual readout. Pinned original Kotlin production is
 * unchanged in its original checkout. A hash-guarded derivative clone adds
 * wholeYearAt() to one copied class. Not independent; not native full-year PASS.
 */
object AnnualKotlinDerivedBridgeV028 {
    private val DECIMAL = Regex("(?:0|-?[1-9][0-9]*)")

    @JvmStatic
    fun main(args: Array<String>) {
        require(args.size == 1 && DECIMAL.matches(args[0]) &&
            args[0] == "-15055671") { "E_DERIVED_ANNUAL_FIXED_FOUNDATION_ONLY" }
        val c = ExactInt.parse(args[0])
        val navigator = ProductionYearNavigator()
        val y = navigator.year5000(c)
        require(y.number.toString() == "5000" &&
            y.openGateIndex.toString() == "-4" &&
            y.closeGateIndex.toString() == "4" &&
            y.openDay.toString() == "-15057703" &&
            y.closeDay.toString() == "-15053459") {
            "E_DERIVED_ANNUAL_BOUNDARY_WITNESS_MISMATCH"
        }
        val size = (y.closeDay - y.openDay).toIntExact()
        require(size == 4244) { "E_DERIVED_ANNUAL_YEAR_LENGTH" }

        // Original production method calls, made once each.
        val cutlets = ProductionCutletStructureEngine(navigator).build(c, y)
        val months = ProductionMonthStructureEngine().build(c, y)
        require(cutlets.cutlets.first().firstDay == y.openDay + 1L &&
            cutlets.cutlets.last().lastDay == y.closeDay &&
            cutlets.cutlets.zipWithNext().all { (a, b) -> a.lastDay + 1L == b.firstDay }) {
            "E_DERIVED_ANNUAL_CUTLET_COVERAGE"
        }
        require(months.lengths.sum() == size &&
            months.lengths.size == months.monthCount &&
            months.canonicalIndices.size == months.monthCount) {
            "E_DERIVED_ANNUAL_MONTH_LENGTHS"
        }
        val weaving = ProductionMonthWeavingEngine(months.lengths)
        val count = ExactInt.parse(weaving.countAll().toString())
        val sauce = ProductionSauceEngine()
        val cooked = sauce.cook(c, y.openDay + 1L)
        val stream = sauce.question(cooked, 4, 32)
        val rank = ProductionRankSampler().choose(stream, count)

        // A separately added function clones ORIGINAL dayAt's unranking loop,
        // traverses all days, and saves the selected day after each step.
        val all = weaving.wholeYearAt(BigInteger(rank.toString()))
        require(all.size == size) { "E_DERIVED_ANNUAL_WEAVING_LENGTH" }
        System.err.println("DERIVED_KOTLIN_STRUCTURE_READY rows=$size originalNativeCalls=0")
        var ci = 0
        val monthTallies = IntArray(months.monthCount)
        for (i in all.indices) {
            val t = y.openDay + 1L + i.toLong()
            while (ci < cutlets.cutlets.size &&
                t > cutlets.cutlets[ci].lastDay) ci++
            check(ci < cutlets.cutlets.size) { "E_DERIVED_ANNUAL_CUTLET_MISSING" }
            val cutlet = cutlets.cutlets[ci]
            check(t >= cutlet.firstDay) { "E_DERIVED_ANNUAL_CUTLET_GAP" }
            val day = all[i]
            val ordinal = day.monthOrdinal
            check(ordinal in 1..months.monthCount) { "E_DERIVED_ANNUAL_MONTH_ID" }
            monthTallies[ordinal - 1]++
            check(day.dayInMonth == monthTallies[ordinal - 1]) {
                "E_DERIVED_ANNUAL_MONTH_PREFIX"
            }
            val monthCanonicalIndex = months.canonicalIndices[ordinal - 1]
            check(monthCanonicalIndex in 1..47 && cutlet.canonicalIndex in 1..17) {
                "E_DERIVED_ANNUAL_CANONICAL_ID"
            }
            val row = listOf(
                c.toString(), t.toString(), y.number.toString(),
                cutlet.canonicalIndex.toString(),
                (t - cutlet.firstDay + 1L).toString(),
                monthCanonicalIndex.toString(),
                day.dayInMonth.toString()
            )
            println(row.joinToString("\t"))
            if ((i + 1) % 512 == 0 || i + 1 == size) {
                System.err.println("DERIVED_KOTLIN_YEAR_ROWS_WRITTEN=${i + 1}")
            }
        }
        check(monthTallies.contentEquals(months.lengths)) {
            "E_DERIVED_ANNUAL_MONTH_TOTALS"
        }
        System.err.println(
            "DERIVED_KOTLIN_ANNUAL_COMPLETED rows=$size " +
            "independentNativeYearCertified=false")
    }
}
