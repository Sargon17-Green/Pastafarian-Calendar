package pastafari

/** Bounded production probe for two-hop navigation, 18 endpoints and 15 strict interiors. */
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
        val next2 = navigator.nextYear(calculationDay, next)
        val previous2 = navigator.previousYear(calculationDay, previous)
        val forwardTarget = base.closeDay + 1L
        val backwardTarget = base.openDay
        val foundForward = navigator.findTargetYear(calculationDay, forwardTarget)
        val foundBackward = navigator.findTargetYear(calculationDay, backwardTarget)
        val forwardTarget2 = next.closeDay + 1L
        val backwardTarget2 = previous.openDay
        val foundForward2 = navigator.findTargetYear(calculationDay, forwardTarget2)
        val foundBackward2 = navigator.findTargetYear(calculationDay, backwardTarget2)


        // Bounded endpoints of five already verified intervals; no exterior years.
        val intervals = listOf(previous2, previous, base, next, next2)
        val endpoints = ArrayList<Triple<ProductionYearInterval, String, ExactInt>>()
        for ((position, year) in intervals.withIndex()) {
            endpoints.add(Triple(year, "AFTER_OPEN", year.openDay + 1L))
            endpoints.add(Triple(year, "AT_CLOSE", year.closeDay))
            if (position > 0) endpoints.add(Triple(year, "AT_OPEN", year.openDay))
            if (position < intervals.lastIndex) {
                endpoints.add(Triple(year, "AFTER_CLOSE", year.closeDay + 1L))
            }
        }
        check(endpoints.size == 18) { "E_INTERVAL_CASE_COUNT" }
        val endpointResults = endpoints.map { entry ->
            val resolved = navigator.findTargetYear(calculationDay, entry.third)
            val position = intervals.indexOf(entry.first)
            val expected = when (entry.second) {
                "AFTER_OPEN", "AT_CLOSE" -> entry.first
                "AT_OPEN" -> intervals[position - 1]
                "AFTER_CLOSE" -> intervals[position + 1]
                else -> error("E_INTERVAL_KIND")
            }
            check(resolved == expected) { "E_PRODUCTION_INTERVAL_ENDPOINT_SEMANTICS" }
            entry to resolved
        }
        // Three non-boundary days within each of five production intervals.
        // Independent Python checks the targets against separately derived geometry.
        val quarterDivisor = ExactInt.of(4L)
        val halfDivisor = ExactInt.of(2L)
        val interiorResults = ArrayList<Pair<Triple<ProductionYearInterval, Int, ExactInt>, ProductionYearInterval>>()
        for (year in intervals) {
            val span = year.closeDay - year.openDay
            val quarter = span / quarterDivisor
            val middle = span / halfDivisor
            val targets = listOf(year.openDay + quarter, year.openDay + middle,
                year.closeDay - quarter)
            check(targets[0] > year.openDay && targets[0] < targets[1] &&
                targets[1] < targets[2] && targets[2] < year.closeDay
            ) { "E_PRODUCTION_INTERIOR_SAMPLE_COLLAPSE" }
            for ((position, target) in targets.withIndex()) {
                val resolved = navigator.findTargetYear(calculationDay, target)
                check(resolved == year) { "E_PRODUCTION_INTERIOR_YEAR_MISMATCH" }
                interiorResults.add(Triple(year, position + 1, target) to resolved)
            }
        }
        check(interiorResults.size == 15) { "E_PRODUCTION_INTERIOR_CASE_COUNT" }
        check(foundForward == next) { "E_ADJACENT_FORWARD_FIND_DISAGREES" }
        check(foundBackward == previous) { "E_ADJACENT_BACKWARD_FIND_DISAGREES" }
        check(foundForward2 == next2) { "E_TWO_HOP_FORWARD_FIND_DISAGREES" }
        check(foundBackward2 == previous2) { "E_TWO_HOP_BACKWARD_FIND_DISAGREES" }

        // Force a complete, bounded real production gate trace for independent comparison.
        for (index in -GATE_HALF_WIDTH..GATE_HALF_WIDTH) {
            val day = navigator.gateDay(ExactInt.of(index.toLong()))
            println("GATE\t$index\t$day")
        }

        emit("YEAR", base)
        emit("NEXT", next)
        emit("PREVIOUS", previous)
        emit("NEXT2", next2)
        emit("PREVIOUS2", previous2)
        println("FIND_FORWARD\t$forwardTarget\t${fields(foundForward)}")
        println("FIND_BACKWARD\t$backwardTarget\t${fields(foundBackward)}")
        println("FIND_FORWARD2\t$forwardTarget2\t${fields(foundForward2)}")
        println("FIND_BACKWARD2\t$backwardTarget2\t${fields(foundBackward2)}")
        for ((entry, resolved) in endpointResults) {
            println(listOf("INTERVAL", entry.first.number, entry.second, entry.third,
                resolved.number, resolved.openGateIndex, resolved.closeGateIndex,
                resolved.openDay, resolved.closeDay).joinToString("\t"))
        }
        for ((entry, resolved) in interiorResults) {
            println(listOf("INTERIOR_YEAR", entry.first.number, entry.second, entry.third,
                resolved.number, resolved.openGateIndex, resolved.closeGateIndex,
                resolved.openDay, resolved.closeDay).joinToString("\t"))
        }
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
