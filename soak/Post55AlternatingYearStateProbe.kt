package pastafari

/** QA-only: repeated mixed-sign year searches on one live production navigator. */
object Post55AlternatingYearStateProbe {
    private val origin = ExactInt.of(-15055671L)
    private const val LIMIT = 8192
    private data class Query(
        val label: String, val target: ExactInt,
        val expected: ProductionYearInterval? = null,
        val expectedError: String? = null
    )
    private fun ok(label: String, target: ExactInt, interval: ProductionYearInterval) =
        Query(label, target, interval)
    private fun red(label: String, target: ExactInt, error: String) =
        Query(label, target, null, error)
    private fun nav() = ProductionYearNavigator(maxGateAbsIndex = LIMIT, maxYearTransitions = 2)
    private fun five(y: ProductionYearInterval) =
        listOf(y.number, y.openGateIndex, y.closeGateIndex, y.openDay, y.closeDay)
    private fun execute(series: String, work: List<Query>) {
        check(work.size == 17) { "E_ALTERNATING_PLAN_LENGTH" }
        val worker = nav()
        var previousCount = 0
        for ((step, q) in work.withIndex()) {
            if (q.expectedError == null) {
                val found = worker.findTargetYear(origin, q.target)
                check(found == q.expected && found.openDay < q.target && q.target <= found.closeDay) {
                    "E_ALTERNATING_SELF_CHECK"
                }
                val count = worker.expandedGateCount
                check(count in 1..LIMIT && count >= previousCount) { "E_ALTERNATING_CACHE" }
                println((listOf("QUERY", series, step, q.label, "OK", q.target) +
                         five(found) + listOf(count)).joinToString("\t"))
                previousCount = count
            } else {
                val error = try {
                    worker.findTargetYear(origin, q.target)
                    "NO_REJECTION"
                } catch (e: IllegalStateException) {
                    e.message ?: "NO_MESSAGE"
                }
                check(error == q.expectedError) { "E_ALTERNATING_BUDGET_REJECTION" }
                val count = worker.expandedGateCount
                check(count in 1..LIMIT && count >= previousCount) { "E_ALTERNATING_CACHE" }
                println(listOf("QUERY", series, step, q.label, error,
                               q.target, count).joinToString("\t"))
                previousCount = count
            }
        }
    }
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_ALTERNATING_ARGS" }
        val seed = nav()
        val y0 = seed.year5000(origin)
        val p1 = seed.nextYear(origin, y0)
        val p2 = seed.nextYear(origin, p1)
        val m1 = seed.previousYear(origin, y0)
        val m2 = seed.previousYear(origin, m1)
        check(listOf(m2, m1, y0, p1, p2).map { it.number.toString() } ==
              listOf("4998", "4999", "5000", "5001", "5002")) { "E_ALTERNATING_YEAR_SET" }
        val first = y0.openDay + 1L
        val plus = p2.openDay + 1L
        val minus = m2.openDay + 1L
        val forward3 = p2.closeDay + 1L
        val backward3 = m2.openDay
        execute("A", listOf(
            ok("BASE_FIRST", first, y0),
            ok("PLUS_TWO_FIRST", plus, p2),
            ok("MINUS_TWO_AFTER_PLUS", minus, m2),
            ok("BASE_AFTER_BOTH", first, y0),
            ok("MINUS_TWO_AT_CLOSE", m2.closeDay, m2),
            ok("PLUS_TWO_AT_CLOSE", p2.closeDay, p2),
            ok("PLUS_TWO_AT_OPEN", p2.openDay, p1),
            ok("MINUS_ONE_AT_OPEN", m1.openDay, m2),
            ok("BASE_AT_OPEN", y0.openDay, m1),
            ok("BASE_AT_CLOSE", y0.closeDay, y0),
            ok("BASE_AFTER_CLOSE", y0.closeDay + 1L, p1),
            ok("PLUS_TWO_REPEAT", plus, p2),
            red("FORWARD3_REJECT", forward3, "E_POST55_YEAR_FORWARD_BUDGET"),
            ok("MINUS_TWO_RECOVER", minus, m2),
            red("BACKWARD3_REJECT", backward3, "E_POST55_YEAR_BACKWARD_BUDGET"),
            ok("PLUS_TWO_RECOVER", plus, p2),
            ok("BASE_FINAL", first, y0)
        ))
        execute("B", listOf(
            ok("BASE_FIRST", first, y0),
            ok("MINUS_TWO_FIRST", minus, m2),
            ok("PLUS_TWO_AFTER_MINUS", plus, p2),
            ok("BASE_AFTER_BOTH", first, y0),
            ok("PLUS_TWO_AT_CLOSE", p2.closeDay, p2),
            ok("MINUS_TWO_AT_CLOSE", m2.closeDay, m2),
            ok("MINUS_ONE_AT_OPEN", m1.openDay, m2),
            ok("PLUS_TWO_AT_OPEN", p2.openDay, p1),
            ok("BASE_AFTER_CLOSE", y0.closeDay + 1L, p1),
            ok("BASE_AT_OPEN", y0.openDay, m1),
            ok("BASE_FIRST_REPEAT", first, y0),
            ok("MINUS_TWO_REPEAT", minus, m2),
            red("BACKWARD3_REJECT", backward3, "E_POST55_YEAR_BACKWARD_BUDGET"),
            ok("PLUS_TWO_RECOVER", plus, p2),
            red("FORWARD3_REJECT", forward3, "E_POST55_YEAR_FORWARD_BUDGET"),
            ok("MINUS_TWO_RECOVER", minus, m2),
            ok("BASE_FINAL", first, y0)
        ))
        for (index in -280..280)
            println(listOf("GATE", index, seed.gateDay(ExactInt.of(index.toLong()))).joinToString("\t"))
        check(seed.expandedGateCount in 1..LIMIT) { "E_ALTERNATING_TRACE_BUDGET" }
        println("TRACE_GATES\t561")
    }
}
