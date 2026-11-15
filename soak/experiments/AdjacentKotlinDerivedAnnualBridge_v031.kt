package pastafari

import java.math.BigInteger

/**
 * Experimental DERIVED Kotlin annual output for original-source years 4999 and
 * 5001. Exactly the same pinned original production structure methods as v028,
 * plus a hash-guarded copy of its dayAt loop extended to wholeYearAt().
 * The original Kotlin production branch and dayAt method remain untouched.
 */
object AdjacentKotlinDerivedAnnualBridgeV031 {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.size == 1 && args[0] == "-15055671") {
            "E_V031_FIXED_FOUNDATION_DAY_ONLY"
        }
        val c=ExactInt.of(-15055671L)
        val nav=ProductionYearNavigator()
        val central=nav.year5000(c)
        val prev=nav.previousYear(c,central)
        val next=nav.nextYear(c,central)
        val intervals=listOf(prev,next)
        val expected=listOf(
            listOf("4999","-12","-4","-15061829","-15057703","4126"),
            listOf("5001","4","14","-15053459","-15047892","5567")
        )
        var written=0
        for ((index,y) in intervals.withIndex()) {
            val size=(y.closeDay-y.openDay).toIntExact()
            val actual=listOf(y.number.toString(),
                y.openGateIndex.toString(), y.closeGateIndex.toString(),
                y.openDay.toString(), y.closeDay.toString(), size.toString())
            check(actual==expected[index]) {
                "E_V031_SOURCE_ORIGINAL_ADJACENT_YEAR_GATE_MISMATCH"
            }
            val cutlets=ProductionCutletStructureEngine(nav).build(c,y)
            val months=ProductionMonthStructureEngine().build(c,y)
            require(months.lengths.size==months.monthCount &&
                months.lengths.sum()==size &&
                months.canonicalIndices.size==months.monthCount) {
                "E_V031_SOURCE_MONTH_STRUCTURE"
            }
            check(cutlets.cutlets.first().firstDay==y.openDay+1L &&
                cutlets.cutlets.last().lastDay==y.closeDay &&
                cutlets.cutlets.zipWithNext().all { (a,b)->a.lastDay+1L==b.firstDay }) {
                "E_V031_SOURCE_CUTLET_GAPS"
            }
            val weaving=ProductionMonthWeavingEngine(months.lengths)
            val count=ExactInt.parse(weaving.countAll().toString())
            val sauce=ProductionSauceEngine()
            val cooked=sauce.cook(c,y.openDay+1L)
            val stream=sauce.question(cooked,4,32)
            val rank=ProductionRankSampler().choose(stream,count)
            val all=weaving.wholeYearAt(BigInteger(rank.toString()))
            check(all.size==size) { "E_V031_NOT_ALL_DAYS" }
            val counts=IntArray(months.monthCount)
            var cutletId=0
            for (i in all.indices) {
                val t=y.openDay+1L+i.toLong()
                while(cutletId < cutlets.cutlets.size &&
                    t>cutlets.cutlets[cutletId].lastDay) cutletId++
                check(cutletId<cutlets.cutlets.size) { "E_V031_CUTLET_MISSING" }
                val cutlet=cutlets.cutlets[cutletId]
                check(t>=cutlet.firstDay) { "E_V031_CUTLET_GAP" }
                val woven=all[i]
                check(woven.monthOrdinal in 1..months.monthCount) { "E_V031_MONTH_ORDINAL" }
                counts[woven.monthOrdinal-1]++
                check(woven.dayInMonth==counts[woven.monthOrdinal-1]) {
                    "E_V031_MONTH_PREFIX_COUNT"
                }
                val m=months.canonicalIndices[woven.monthOrdinal-1]
                check(m in 1..47 && cutlet.canonicalIndex in 1..17) {
                    "E_V031_CANONICAL_SOURCE_NAMES"
                }
                println(listOf(c.toString(),t.toString(),y.number.toString(),
                    cutlet.canonicalIndex.toString(),
                    (t-cutlet.firstDay+1L).toString(),
                    m.toString(),woven.dayInMonth.toString()).joinToString("\t"))
                written++
                if(written%1000==0)
                    System.err.println("KOTLIN_ADJACENT_DERIVED_ROWS=" + written)
            }
            check(counts.contentEquals(months.lengths)) {
                "E_V031_MONTH_TOTAL_NOT_EXHAUSTED"
            }
            System.err.println("KOTLIN_ADJACENT_DERIVED_YEAR_COMPLETE=" +
                y.number.toString() + " rows=" + size.toString())
        }
        check(written==4126+5567) { "E_V031_TOTAL_TWO_YEAR_LENGTH" }
        System.err.println("KOTLIN_TWO_ADJACENT_DERIVED_YEARS_COMPLETE=" +
            written.toString() + " originalNativeFullYearCertification=false")
    }
}
