package pastafari

/** Bounded read-only production probe for one adjacent year in each direction. */
object Post55ProductionAdjacentYearProbe {
    private const val MAX_GATE_ABS_INDEX = 8192
    private const val GATE_HALF_WIDTH = 280
    private const val EXPECTED_GATE_COUNT = GATE_HALF_WIDTH * 2 + 1

    private fun fields(year: ProductionYearInterval): String =
        listOf(year.number, year.openGateIndex, year.closeGateIndex,
            year.openDay, year.closeDay).joinToString("\t")

    private fun emit(kind: String, year: ProductionYearInterval) {
        println("$kind\t${fields(year)}")
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_ADJACENT_PROBE_ARGS" }
        val calculationDay = ExactInt.of(-15055671L)
        val navigator = ProductionYearNavigator(
            maxGateAbsIndex = MAX_GATE_ABS_INDEX,
            maxYearTransitions = 8
        )

        val base = navigator.year5000(calculationDay)
        val next = navigator.nextYear(calculationDay, base)
        val previous = navigator.previousYear(calculationDay, base)
        val forwardTarget = base.closeDay + 1L
        val backwardTarget = base.openDay
        val foundForward = navigator.findTargetYear(calculationDay, forwardTarget)
        val foundBackward = navigator.findTargetYear(calculationDay, backwardTarget)

        check(foundForward == next) { "E_ADJACENT_FORWARD_FIND_DISAGREES" }
        check(foundBackward == previous) { "E_ADJACENT_BACKWARD_FIND_DISAGREES" }

        // Force a complete, bounded real production gate trace for independent comparison.
        for (index in -GATE_HALF_WIDTH..GATE_HALF_WIDTH) {
            val day = navigator.gateDay(ExactInt.of(index.toLong()))
            println("GATE\t$index\t$day")
        }

        emit("YEAR", base)
        emit("NEXT", next)
        emit("PREVIOUS", previous)
        println("FIND_FORWARD\t$forwardTarget\t${fields(foundForward)}")
        println("FIND_BACKWARD\t$backwardTarget\t${fields(foundBackward)}")
        println("PRODUCTION_GATE_LIMIT\t$MAX_GATE_ABS_INDEX")
        println("PRODUCTION_EXPANDED_GATES\t${navigator.expandedGateCount}")

        check(navigator.expandedGateCount == EXPECTED_GATE_COUNT) {
            "E_ADJACENT_PRODUCTION_GATE_COUNT"
        }
        check(navigator.expandedGateCount <= MAX_GATE_ABS_INDEX) {
            "E_ADJACENT_PRODUCTION_GATE_BUDGET"
        }
    }
}
