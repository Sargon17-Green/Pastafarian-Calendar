package pastafari

/** Read-only production probe; no date or algorithmic certification. */
object Post55ProductionYearGateProbe {
    private fun yearFields(year: ProductionYearInterval): String =
        listOf(year.number, year.openGateIndex, year.closeGateIndex,
            year.openDay, year.closeDay).joinToString("\t")

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_PROBE_ARGS" }
        val calculationDay = ExactInt.of(-15055671L)
        val navigator = ProductionYearNavigator()
        for (i in -2L..2L) {
            println("GATE\t$i\t${navigator.gateDay(ExactInt.of(i))}")
        }
        val base = navigator.year5000(calculationDay)
        println("YEAR\t${yearFields(base)}")
        for (target in listOf(base.openDay + 1L, calculationDay, base.closeDay)) {
            println("FIND\t$target\t${yearFields(navigator.findTargetYear(calculationDay, target))}")
        }
        for (day in listOf(calculationDay - 1L, calculationDay,
                           calculationDay + 1L, base.openDay, base.closeDay)) {
            val index = navigator.exactGateIndex(day)
            println("EXACT\t$day\t${index?.toString() ?: "NONE"}")
        }
        println("PRODUCTION_GATE_LIMIT\t8192")
    }
}
