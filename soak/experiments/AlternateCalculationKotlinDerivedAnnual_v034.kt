package pastafari

import java.math.BigInteger

/**
 * DERIVED one-pass 3569-day year 5000 at c=-15055672.
 *
 * All original Kotlin production source files are read from a frozen commit.
 * A separately generated copy adds wholeYearAt() cloned from the original
 * dayAt() loop. Output is not the original 3569 F(c,t) calls.
 */
object AlternateCalculationKotlinDerivedAnnualV034 {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.size == 1 && args[0] == "-15055672") {
            "E_V034_FIXED_CHANGED_CALCULATION_DAY"
        }
        val c = ExactInt.of(-15055672L)
        val nav = ProductionYearNavigator()
        val y = nav.year5000(c)
        val length = (y.closeDay-y.openDay).toIntExact()
        check(y.number.toString() == "5000" &&
              y.openGateIndex.toString() == "-1" &&
              y.closeGateIndex.toString() == "5" &&
              y.openDay.toString() == "-15056174" &&
              y.closeDay.toString() == "-15052605" &&
              length == 3569) {
            "E_V034_CHANGED_C_NATIVE_BOUNDS_MISMATCH"
        }

        val cutlets = ProductionCutletStructureEngine(nav).build(c,y)
        val months = ProductionMonthStructureEngine().build(c,y)
        check(months.lengths.size == months.monthCount &&
              months.canonicalIndices.size == months.monthCount &&
              months.lengths.sum() == length) {
            "E_V034_ORIGINAL_MONTH_STRUCTURE"
        }
        check(cutlets.cutlets.isNotEmpty() &&
              cutlets.cutlets.first().firstDay == y.openDay+1L &&
              cutlets.cutlets.last().lastDay == y.closeDay &&
              cutlets.cutlets.zipWithNext().all {(a,b)->a.lastDay+1L==b.firstDay}) {
            "E_V034_ORIGINAL_CUTLET_COVERAGE"
        }
        val weaving = ProductionMonthWeavingEngine(months.lengths)
        val count = ExactInt.parse(weaving.countAll().toString())
        val sauce = ProductionSauceEngine()
        val cooked = sauce.cook(c,y.openDay+1L)
        val stream = sauce.question(cooked,4,32)
        val rank = ProductionRankSampler().choose(stream,count)
        val all = weaving.wholeYearAt(BigInteger(rank.toString()))
        check(all.size == length) { "E_V034_DERIVED_YEAR_NOT_COMPLETE" }
        val tallies = IntArray(months.monthCount)
        var selectedCutlet=0
        for(i in all.indices) {
            val t = y.openDay+1L+i.toLong()
            while(selectedCutlet < cutlets.cutlets.size &&
                  t>cutlets.cutlets[selectedCutlet].lastDay) selectedCutlet++
            check(selectedCutlet < cutlets.cutlets.size) { "E_V034_MISSING_CUTLET" }
            val cutlet = cutlets.cutlets[selectedCutlet]
            check(t>=cutlet.firstDay) { "E_V034_GAP_IN_CUTLETS" }
            val day = all[i]
            check(day.monthOrdinal in 1..months.monthCount) { "E_V034_MONTH_RANGE" }
            tallies[day.monthOrdinal-1]++
            check(day.dayInMonth==tallies[day.monthOrdinal-1]) {
                "E_V034_MONTH_PREFIX_MISMATCH"
            }
            val index=months.canonicalIndices[day.monthOrdinal-1]
            check(index in 1..47 && cutlet.canonicalIndex in 1..17) {
                "E_V034_CANONICAL_RANGE"
            }
            println(listOf(c.toString(),t.toString(),y.number.toString(),
                cutlet.canonicalIndex.toString(),
                (t-cutlet.firstDay+1L).toString(),
                index.toString(),day.dayInMonth.toString()).joinToString("\t"))
            if((i+1)%512==0 || i+1==length) {
                System.err.println("DERIVED_KOTLIN_ALTERNATE_C_ROWS=" + (i+1).toString())
            }
        }
        check(tallies.contentEquals(months.lengths)) { "E_V034_YEAR_MONTH_TOTALS" }
        System.err.println("DERIVED_KOTLIN_ALTERNATE_C_DONE rows=" + length.toString() +
            " original_full_year_calls=false")
    }
}
