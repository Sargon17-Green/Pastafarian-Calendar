package pastafari

/** QA-only bounded transition budget, recovery and cache probe (12 cases). */
object Post55YearTransitionBudgetProbe {
    private val foundation = ExactInt.of(-15055671L)
    private const val LIMIT = 8192
    private fun nav(budget: Int) = ProductionYearNavigator(maxGateAbsIndex = LIMIT, maxYearTransitions = budget)
    private fun five(y: ProductionYearInterval) =
        listOf(y.number, y.openGateIndex, y.closeGateIndex, y.openDay, y.closeDay).joinToString("\t")
    private val cache = ArrayList<String>()
    private fun sample(name: String, step: Int, worker: ProductionYearNavigator) {
        val count = worker.expandedGateCount
        check(count in 1..LIMIT) { "E_TRANSITION_GATE_BUDGET" }
        cache.add(listOf("CACHE", name, step, count).joinToString("\t"))
    }
    private fun ctor(id: Int, label: String, budget: Int) {
        val code = try { nav(budget); "NO_REJECTION" }
                   catch (e: IllegalArgumentException) { e.message ?: "NO_MESSAGE" }
        check(code == "E_POST55_YEAR_TRANSITION_BUDGET") { "E_TRANSITION_CTOR" }
        println(listOf("CASE", id, label, code).joinToString("\t"))
    }
    private fun reject(id: Int, label: String, worker: ProductionYearNavigator,
                       target: ExactInt, expected: String) {
        val code = try { worker.findTargetYear(foundation, target); "NO_REJECTION" }
                   catch (e: IllegalStateException) { e.message ?: "NO_MESSAGE" }
        check(code == expected) { "E_TRANSITION_DIRECTION" }
        println(listOf("CASE", id, label, target, code).joinToString("\t"))
    }
    private fun accept(id: Int, label: String, worker: ProductionYearNavigator,
                       target: ExactInt, expected: ProductionYearInterval) {
        val actual = worker.findTargetYear(foundation, target)
        check(actual == expected && actual.openDay < target && target <= actual.closeDay) {
            "E_TRANSITION_RECOVERY"
        }
        println(listOf("CASE", id, label, target, five(actual)).joinToString("\t"))
    }
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_TRANSITION_ARGS" }
        val seed = nav(2)
        val y0 = seed.year5000(foundation)
        val yp1 = seed.nextYear(foundation, y0)
        val yp2 = seed.nextYear(foundation, yp1)
        val ym1 = seed.previousYear(foundation, y0)
        val ym2 = seed.previousYear(foundation, ym1)
        check(listOf(ym2, ym1, y0, yp1, yp2).map { it.number.toString() } ==
              listOf("4998", "4999", "5000", "5001", "5002")) { "E_TRANSITION_YEARS" }
        val t0 = y0.openDay + 1L
        val tp1 = yp1.openDay + 1L
        val tp2 = yp2.openDay + 1L
        val tm1 = ym1.openDay + 1L
        val tm2 = ym2.openDay + 1L

        ctor(0, "CTOR_ZERO", 0)
        ctor(1, "CTOR_OVER", 100001)
        val forwardOne = nav(1)
        reject(2, "F2_BUDGET1", forwardOne, tp2, "E_POST55_YEAR_FORWARD_BUDGET")
        sample("FWD1", 0, forwardOne)
        accept(3, "F1_RECOVER", forwardOne, tp1, yp1)
        sample("FWD1", 1, forwardOne)
        accept(4, "BASE_AFTER_F1", forwardOne, t0, y0)
        sample("FWD1", 2, forwardOne)

        val backwardOne = nav(1)
        reject(5, "B2_BUDGET1", backwardOne, tm2, "E_POST55_YEAR_BACKWARD_BUDGET")
        sample("BWD1", 0, backwardOne)
        accept(6, "B1_RECOVER", backwardOne, tm1, ym1)
        sample("BWD1", 1, backwardOne)
        accept(7, "BASE_AFTER_B1", backwardOne, t0, y0)
        sample("BWD1", 2, backwardOne)

        val forwardTwo = nav(2)
        sample("FWD2", 0, forwardTwo)
        accept(8, "F2_BUDGET2", forwardTwo, tp2, yp2)
        sample("FWD2", 1, forwardTwo)
        check(forwardTwo.findTargetYear(foundation, t0) == y0) { "E_F2_RETURN" }
        sample("FWD2", 2, forwardTwo)

        val backwardTwo = nav(2)
        sample("BWD2", 0, backwardTwo)
        accept(9, "B2_BUDGET2", backwardTwo, tm2, ym2)
        sample("BWD2", 1, backwardTwo)
        check(backwardTwo.findTargetYear(foundation, t0) == y0) { "E_B2_RETURN" }
        sample("BWD2", 2, backwardTwo)

        for (group in listOf("FWD1", "BWD1", "FWD2", "BWD2")) {
            val counts = cache.filter { it.startsWith("CACHE\t" + group + "\t") }
                              .map { it.split("\t")[3].toInt() }
            check(counts.size == 3 && counts.zipWithNext().all { it.first <= it.second }) {
                "E_TRANSITION_CACHE_MONOTONICITY"
            }
        }
        println("CASE\t10\tFWD_PROFILE\tOK")
        println("CASE\t11\tBWD_PROFILE\tOK")
        cache.forEach(::println)
        for (i in -280..280)
            println(listOf("GATE", i, seed.gateDay(ExactInt.of(i.toLong()))).joinToString("\t"))
        check(seed.expandedGateCount == 561) { "E_TRANSITION_TRACE_COUNT" }
        println("TRACE_GATES\t561")
    }
}
