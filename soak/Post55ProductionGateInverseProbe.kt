package pastafari

/** Strict bounded probe: gateDay(index) and exactGateIndex(day), never full-date certification. */
object Post55ProductionGateInverseProbe {
    private const val HALF_WIDTH = 280
    private const val MAX_GATE_ABS_INDEX = 8192
    private const val EXPECTED_EXPANDED = 2 * HALF_WIDTH + 1

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_GATE_INVERSE_ARGS" }
        val calculationDay = ExactInt.of(-15055671L)
        val navigator = ProductionYearNavigator(
            maxGateAbsIndex = MAX_GATE_ABS_INDEX, maxYearTransitions = 8
        )
        val year5000 = navigator.year5000(calculationDay)
        val previous = navigator.previousYear(calculationDay, year5000)
        val previous2 = navigator.previousYear(calculationDay, previous)
        val next = navigator.nextYear(calculationDay, year5000)
        val next2 = navigator.nextYear(calculationDay, next)
        val years = listOf(previous2, previous, year5000, next, next2)
        check(years.map { it.number.toString() } == listOf("4998", "4999", "5000", "5001", "5002")) {
            "E_GATE_INVERSE_YEARS"
        }
        val shared = years.zipWithNext { left, right ->
            check(left.closeGateIndex == right.openGateIndex &&
                left.closeDay == right.openDay) { "E_GATE_INVERSE_CONTIGUITY" }
            left.closeGateIndex
        }
        check(shared.size == 4 && shared.toSet().size == 4) { "E_GATE_INVERSE_SHARED" }
        val first = ExactInt.of((-HALF_WIDTH).toLong())
        val last = ExactInt.of(HALF_WIDTH.toLong())
        check(shared.all { it > first && it < last }) { "E_GATE_INVERSE_BOUNDARY_RANGE" }

        for (index in -HALF_WIDTH..HALF_WIDTH) {
            val exactIndex = ExactInt.of(index.toLong())
            val day = navigator.gateDay(exactIndex)
            println("GATE\t$index\t$day")
        }
        for (index in -HALF_WIDTH..HALF_WIDTH) {
            val exactIndex = ExactInt.of(index.toLong())
            val day = navigator.gateDay(exactIndex)
            val inverse = navigator.exactGateIndex(day)
            check(inverse == exactIndex) { "E_GATE_INVERSE_EXACT_ROUNDTRIP" }
            println("INVERSE\t$day\t$inverse")
        }
        for (boundary in shared) {
            val day = navigator.gateDay(boundary)
            println("SHARED\t$boundary")
            for (delta in listOf(-1L, 1L)) {
                val candidate = day + delta
                val actual = navigator.exactGateIndex(candidate)
                check(actual == null) { "E_GATE_INVERSE_NEIGHBOR_FALSE_POSITIVE" }
                println("NEAR\t$boundary\t$delta\t$candidate\tNONE")
            }
        }
        println("PRODUCTION_GATE_LIMIT\t$MAX_GATE_ABS_INDEX")
        println("PRODUCTION_EXPANDED_GATES\t${navigator.expandedGateCount}")
        check(navigator.expandedGateCount == EXPECTED_EXPANDED) { "E_GATE_INVERSE_EXPANSION" }
    }
}
