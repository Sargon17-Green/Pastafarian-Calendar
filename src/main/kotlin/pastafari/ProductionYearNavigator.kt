package pastafari

/** Post-55 production-only year traversal. Not a five-field converter. */
data class ProductionYearInterval(
    val number: ExactInt,
    val openGateIndex: ExactInt,
    val closeGateIndex: ExactInt,
    val openDay: ExactInt,
    val closeDay: ExactInt
)

class ProductionYearNavigator(
    private val sauce: ProductionSauceEngine = ProductionSauceEngine(),
    maxGateAbsIndex: Int = 8192,
    private val maxYearTransitions: Int = 128
) {
    private val foundation = ExactInt.of(-15055671L)
    private val minLength = ExactInt.of(252L)
    private val maxLength = ExactInt.of(5778L)
    private val rankSelector = Year5000InclusiveAcceptancePatchWrapper()
    private val gateTable = ProductionGateYear5000Engine(
        ProductionGateAnswerProvider { index ->
            sauce.answer(foundation, foundation + index, 1, 1)
        }, maxGateAbsIndex
    )

    init {
        require(maxYearTransitions in 1..100000) { "E_POST55_YEAR_TRANSITION_BUDGET" }
    }

    val expandedGateCount: Int get() = gateTable.expandedGateCount

    fun gateDay(index:ExactInt):ExactInt=gateTable.getGate(index)

    fun exactGateIndex(day:ExactInt):ExactInt? {
        gateTable.coverDays(day,day)
        var lo=gateTable.lowestIndex
        var hi=gateTable.highestIndex
        val two=ExactInt.of(2L)
        while(lo<hi) {
            val mid=lo+(hi-lo+1L)/two
            if(gateTable.getGate(mid)<=day) lo=mid else hi=mid-1L
        }
        return if(gateTable.getGate(lo)==day) lo else null
    }

    fun year5000(calculationDay: ExactInt): ProductionYearInterval {
        val stream = sauce.answer(calculationDay, calculationDay, 1, 10)
        val selected = gateTable.chooseYear5000(calculationDay, stream).candidate
        return ProductionYearInterval(
            ExactInt.of(5000L), selected.openIndex, selected.closeIndex,
            selected.openDay, selected.closeDay
        )
    }

    private fun validateYear(year: ProductionYearInterval) {
        require(year.openGateIndex < year.closeGateIndex &&
            year.closeGateIndex - year.openGateIndex >= ExactInt.of(6L) &&
            year.closeDay - year.openDay in minLength..maxLength &&
            gateTable.getGate(year.openGateIndex) == year.openDay &&
            gateTable.getGate(year.closeGateIndex) == year.closeDay
        ) { "E_POST55_YEAR_INVALID_INTERVAL" }
    }

    private fun selectIndex(
        calculationDay: ExactInt, boundaryDay: ExactInt,
        seal: Int, candidates: List<ExactInt>
    ): ExactInt {
        check(candidates.isNotEmpty()) { "E_POST55_YEAR_NO_CANDIDATES" }
        val stream = sauce.answer(calculationDay, boundaryDay, 1, seal)
        val rank = rankSelector.patch(
            stream.firstAnswer, stream.directionStep, candidates.size
        ).correctedRank
        return candidates[rank - 1]
    }

    fun nextYear(
        calculationDay: ExactInt, known: ProductionYearInterval
    ): ProductionYearInterval {
        validateYear(known)
        val openIndex = known.closeGateIndex
        val openDay = known.closeDay
        val candidates = ArrayList<ExactInt>()
        var end = openIndex + 6L
        while (true) {
            val length = gateTable.getGate(end) - openDay
            if (length > maxLength) break
            if (length >= minLength) candidates.add(end)
            end += 1L
        }
        val closeIndex = selectIndex(calculationDay, openDay, 11, candidates)
        return ProductionYearInterval(
            known.number + 1L, openIndex, closeIndex,
            openDay, gateTable.getGate(closeIndex)
        )
    }

    fun previousYear(
        calculationDay: ExactInt, known: ProductionYearInterval
    ): ProductionYearInterval {
        validateYear(known)
        val closeIndex = known.openGateIndex
        val closeDay = known.openDay
        val candidates = ArrayList<ExactInt>()
        var start = closeIndex - 6L
        while (true) {
            val length = closeDay - gateTable.getGate(start)
            if (length > maxLength) break
            if (length >= minLength) candidates.add(start)
            start -= 1L
        }
        val openIndex = selectIndex(calculationDay, closeDay, 12, candidates)
        return ProductionYearInterval(
            known.number - 1L, openIndex, closeIndex,
            gateTable.getGate(openIndex), closeDay
        )
    }

    fun findTargetYear(
        calculationDay: ExactInt, targetDay: ExactInt
    ): ProductionYearInterval {
        var current = year5000(calculationDay)
        var transitions = 0
        while (targetDay > current.closeDay) {
            check(transitions < maxYearTransitions) { "E_POST55_YEAR_FORWARD_BUDGET" }
            current = nextYear(calculationDay, current)
            transitions++
        }
        while (targetDay <= current.openDay) {
            check(transitions < maxYearTransitions) { "E_POST55_YEAR_BACKWARD_BUDGET" }
            current = previousYear(calculationDay, current)
            transitions++
        }
        check(current.openDay < targetDay && targetDay <= current.closeDay) {
            "E_POST55_YEAR_TARGET_OUTSIDE_INTERVAL"
        }
        return current
    }
}
