package pastafari

/** Bounded three-order diagnostic of the real production findTargetYear navigator. */
object Post55ProductionOrderInvariantProbe {
    private const val GATE_LIMIT = 8192
    private const val HALF_WIDTH = 280
    private const val EXPECTED_GATE_COUNT = HALF_WIDTH * 2 + 1

    private data class TargetCase(
        val year: ProductionYearInterval, val ordinal: Int, val day: ExactInt
    )

    private fun navigator(): ProductionYearNavigator =
        ProductionYearNavigator(maxGateAbsIndex = GATE_LIMIT, maxYearTransitions = 8)

    private fun fields(year: ProductionYearInterval): String =
        listOf(year.number, year.openGateIndex, year.closeGateIndex,
            year.openDay, year.closeDay).joinToString("\t")

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_ORDER_PROBE_ARGS" }
        val foundation = ExactInt.of(-15055671L)
        val seed = navigator()
        val center = seed.year5000(foundation)
        val before = seed.previousYear(foundation, center)
        val after = seed.nextYear(foundation, center)
        val years = listOf(seed.previousYear(foundation, before), before,
            center, after, seed.nextYear(foundation, after))
        check(years.size == 5 && years.map { it.number.toString() } ==
            listOf("4998", "4999", "5000", "5001", "5002")
        ) { "E_ORDER_YEAR_SET" }
        for (i in 0 until years.lastIndex) {
            check(years[i].closeGateIndex == years[i + 1].openGateIndex &&
                years[i].closeDay == years[i + 1].openDay
            ) { "E_ORDER_YEAR_CONTIGUITY" }
        }
        val quarterDivisor = ExactInt.of(4L)
        val halfDivisor = ExactInt.of(2L)
        val cases = ArrayList<TargetCase>()
        for (year in years) {
            val span = year.closeDay - year.openDay
            val quarter = span / quarterDivisor
            val targets = listOf(year.openDay + quarter,
                year.openDay + span / halfDivisor, year.closeDay - quarter)
            check(year.openDay < targets[0] && targets[0] < targets[1] &&
                targets[1] < targets[2] && targets[2] < year.closeDay
            ) { "E_ORDER_INTERIOR_COLLAPSE" }
            for ((position, target) in targets.withIndex()) {
                cases.add(TargetCase(year, position + 1, target))
            }
        }
        check(cases.size == 15) { "E_ORDER_TARGET_COUNT" }
        val natural = (0 until cases.size).toList()
        val reversed = natural.reversed()
        val permuted = natural.map { (it * 7) % cases.size }
        check(permuted.toSet().size == cases.size && permuted != natural &&
            permuted != reversed) { "E_ORDER_NOT_PERMUTATION" }
        for ((orderName, order) in listOf(
            "NATURAL" to natural, "REVERSED" to reversed, "PERMUTED" to permuted
        )) {
            // New source-free navigator for each traversal; no shared mutable gate table.
            val worker = navigator()
            for (index in order) {
                val case = cases[index]
                val result = worker.findTargetYear(foundation, case.day)
                check(result == case.year &&
                    result.openDay < case.day && case.day < result.closeDay
                ) { "E_ORDER_REAL_PRODUCTION_MISMATCH" }
                println(listOf("ORDER", orderName, index, case.year.number,
                    case.ordinal, case.day, result.number, result.openGateIndex,
                    result.closeGateIndex, result.openDay, result.closeDay
                ).joinToString("\t"))
            }
            check(worker.expandedGateCount in 1..GATE_LIMIT) {
                "E_ORDER_PRODUCTION_BUDGET"
            }
            println("ORDER_GATES\t$orderName\t${worker.expandedGateCount}")
        }
        for (index in -HALF_WIDTH..HALF_WIDTH) {
            println("GATE\t$index\t${seed.gateDay(ExactInt.of(index.toLong()))}")
        }
        check(seed.expandedGateCount == EXPECTED_GATE_COUNT) {
            "E_ORDER_SEED_GATE_TRACE"
        }
        println("SEED_GATES\t${seed.expandedGateCount}")
    }
}
