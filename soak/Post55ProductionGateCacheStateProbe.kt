package pastafari

/** Bounded signed inverse/cache-order QA; this does not certify full dates. */
object Post55ProductionGateCacheStateProbe {
    private const val LIMIT = 8192
    private val indices = listOf(-280, -279, -40, -19, -12, -5, -4, -1, 0, 1,
        3, 4, 5, 14, 22, 23, 40, 279, 280)
    private fun n(i: Int) = ExactInt.of(i.toLong())

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_CACHE_ARGS" }
        check(indices.size == 19 && indices.toSet().size == 19) { "E_CACHE_INDICES" }
        val sessions = listOf("FRESH" to emptyList<Int>(),
            "NEGATIVE_FIRST" to indices, "POSITIVE_FIRST" to indices.reversed())
        for ((name, warm) in sessions) {
            val worker = ProductionYearNavigator(maxGateAbsIndex = LIMIT, maxYearTransitions = 8)
            for ((position, index) in warm.withIndex()) {
                val day = worker.gateDay(n(index))
                println("WARM\t$name\t$position\t$index\t$day")
            }
            for ((position, index) in indices.withIndex()) {
                val day = worker.gateDay(n(index))
                val inverse = worker.exactGateIndex(day)
                check(inverse == n(index)) { "E_CACHE_INVERSE" }
                println("ROUND\t$name\t$position\t$index\t$day\t$inverse")
            }
            for ((position, index) in indices.withIndex()) {
                val left = worker.gateDay(n(index))
                val right = worker.gateDay(n(index + 1))
                val span = right - left
                check(span >= ExactInt.of(2L)) { "E_CACHE_INTERIOR" }
                val middle = left + span / ExactInt.of(2L)
                check(left < middle && middle < right &&
                    worker.exactGateIndex(middle) == null) { "E_CACHE_FALSE_GATE" }
                println("MID\t$name\t$position\t$index\t$middle\tNONE")
            }
            val gates = worker.expandedGateCount
            check(gates in 1..LIMIT) { "E_CACHE_GATE_BUDGET" }
            println("SESSION\t$name\t$gates")
        }
    }
}
