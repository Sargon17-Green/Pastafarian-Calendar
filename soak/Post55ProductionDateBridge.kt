package pastafari

import java.math.BigInteger

/**
 * Production-only post-55 seven-column date bridge. No normative/test oracle.
 * Fail-closed on resource budget exhaustion; never a self-certification.
 * Input: calculation JDN<TAB>target JDN, one pair per line.
 * Output: c, t, year, cutlet index, day-in-cutlet, month index, day-in-month.
 */
object Post55ProductionDateBridge {
    private val canonicalDecimal = Regex("-?(?:0|[1-9][0-9]*)")

    fun convert(calculationDay: ExactInt, targetDay: ExactInt): List<String> {
        val navigator = ProductionYearNavigator()
        val year = navigator.findTargetYear(calculationDay, targetDay)
        val cutlets = ProductionCutletStructureEngine(navigator).build(calculationDay, year)
        val cutlet = cutlets.cutlets.singleOrNull {
            targetDay >= it.firstDay && targetDay <= it.lastDay
        } ?: error("E_POST55_CUTLET_TARGET")
        val months = ProductionMonthStructureEngine().build(calculationDay, year)
        val weaving = ProductionMonthWeavingEngine(months.lengths)
        val rankCount = ExactInt.parse(weaving.countAll().toString())
        val sauce = ProductionSauceEngine()
        val prepared = sauce.cook(calculationDay, year.openDay + 1L)
        val stream = sauce.question(prepared, 4, 32)
        val rank = ProductionRankSampler().choose(stream, rankCount)
        val offset0 = (targetDay - year.openDay - 1L).toIntExact()
        val wovenDay = weaving.dayAt(BigInteger(rank.toString()), offset0)
        val monthIndex = months.canonicalIndices[wovenDay.monthOrdinal - 1]
        return listOf(calculationDay.toString(), targetDay.toString(), year.number.toString(),
            cutlet.canonicalIndex.toString(), (targetDay-cutlet.firstDay+1L).toString(),
            monthIndex.toString(), wovenDay.dayInMonth.toString())
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_POST55_BRIDGE_ARGS" }
        while (true) {
            val line = readLine() ?: break
            val fields = line.split('\t')
            require(fields.size == 2 && fields.all { canonicalDecimal.matches(it) }) {
                "E_POST55_BRIDGE_INPUT"
            }
            val calculationDay = ExactInt.parse(fields[0])
            val targetDay = ExactInt.parse(fields[1])
            println(convert(calculationDay, targetDay).joinToString("\t"))
        }
    }
}
