package pastafari

/** Bounded adversarial ownership and same-instance order diagnostic. */
object Post55ProductionBoundaryStateProbe {
    private const val GATE_LIMIT = 8192
    private const val HALF_WIDTH = 280
    private data class Case(val id: Int, val target: ExactInt, val owner: ExactInt)
    private fun navigator() =
        ProductionYearNavigator(maxGateAbsIndex = GATE_LIMIT, maxYearTransitions = 8)
    private fun fields(y: ProductionYearInterval) =
        listOf(y.number, y.openGateIndex, y.closeGateIndex, y.openDay, y.closeDay)
            .joinToString("\t")

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_BOUNDARY_ARGS" }
        val foundation = ExactInt.of(-15055671L)
        val one = ExactInt.of(1L)
        val seed = navigator()
        val y5000 = seed.year5000(foundation)
        val before = seed.previousYear(foundation, y5000)
        val after = seed.nextYear(foundation, y5000)
        val years = listOf(seed.previousYear(foundation, before), before,
            y5000, after, seed.nextYear(foundation, after))
        check(years.map { it.number.toString() } ==
            listOf("4998", "4999", "5000", "5001", "5002")) { "E_YEARS" }
        for (i in 0..3) {
            check(years[i].closeGateIndex == years[i + 1].openGateIndex &&
                years[i].closeDay == years[i + 1].openDay) { "E_CONTIGUITY" }
        }
        val cases = ArrayList<Case>(18)
        fun add(day: ExactInt, owner: ExactInt) {
            cases.add(Case(cases.size, day, owner))
        }
        for (y in years) add(y.openDay + one, y.number)
        for (y in years) add(y.closeDay, y.number)
        for (i in 1..4) add(years[i].openDay, years[i - 1].number)
        for (i in 0..3) add(years[i].closeDay + one, years[i + 1].number)
        check(cases.size == 18 && cases.map { it.target }.toSet().size == 10) {
            "E_CASES"
        }
        for (i in 0..3)
            check(cases[i + 10].target == cases[i + 5].target &&
                cases[i + 14].target == cases[i + 1].target) { "E_ALIAS" }
        val natural = (0..17).toList()
        val reversed = natural.reversed()
        val stride = natural.map { (5 * it) % 18 }
        check(stride.toSet().size == 18 && stride != natural &&
            stride != reversed) { "E_STRIDE" }

        val caseRows = ArrayList<String>(108)
        val gateRows = ArrayList<String>(3)
        for ((session, order) in listOf("NATURAL" to natural,
            "REVERSED" to reversed, "STRIDE5" to stride)) {
            // This same instance is reused in both phases, without reset.
            val worker = navigator()
            for (phase in 1..2) {
                val phaseOrder = if (phase == 1) order else order.reversed()
                for ((position, id) in phaseOrder.withIndex()) {
                    val sample = cases[id]
                    val actual = worker.findTargetYear(foundation, sample.target)
                    check(actual.number == sample.owner &&
                        actual.openDay < sample.target &&
                        sample.target <= actual.closeDay) { "E_OWNERSHIP" }
                    caseRows.add(listOf("CASE", session, phase, position,
                        id, sample.target, fields(actual)).joinToString("\t"))
                }
            }
            check(worker.expandedGateCount in 1..GATE_LIMIT) { "E_GATE_BUDGET" }
            gateRows.add("SESSION_GATES\t" + session + "\t" +
                worker.expandedGateCount)
        }
        check(caseRows.size == 108 && gateRows.size == 3) { "E_ROW_COUNTS" }
        caseRows.forEach(::println)
        gateRows.forEach(::println)
        for (index in -HALF_WIDTH..HALF_WIDTH) {
            println("GATE\t" + index + "\t" +
                seed.gateDay(ExactInt.of(index.toLong())))
        }
        check(seed.expandedGateCount == 561) { "E_SEED_GATE_TRACE" }
        println("SEED_GATES\t" + seed.expandedGateCount)
    }
}
