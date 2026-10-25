package pastafari

/**
 * Post-55 integration: gate geometry and Year 5000 candidate selection
 * using ONLY production rank-selection and exact arithmetic.
 *
 * The answer stream provider is an explicit dependency, not a back door to
 * the test-only NormativeCore oracle. A production sauce+bowls provider is
 * still needed before this can be a standalone full-calendar engine.
 */
data class ProductionAnswerStream(
    val firstAnswer: ExactInt,
    val directionStep: Int
)

fun interface ProductionGateAnswerProvider {
    /** gateIndex != 0; signed index is part of the sauce question. */
    fun ask(gateIndex: ExactInt): ProductionAnswerStream
}

data class ProductionYear5000Candidate(
    val openIndex: ExactInt,
    val closeIndex: ExactInt,
    val openDay: ExactInt,
    val closeDay: ExactInt
) {
    val length: ExactInt get() = closeDay - openDay

    fun toTieCandidate(): Year5000TieCandidate =
        Year5000TieCandidate(openIndex, closeIndex, openDay, closeDay)
}

data class ProductionYear5000Selection(
    val candidate: ProductionYear5000Candidate,
    val rank1: Int,
    val candidateCount: Int,
    val rejectedAnswers: Int,
    val historicalIndex0: Int,
    val correctedIndex0: Int
)

class ProductionGateYear5000Engine(
    private val gateAnswers: ProductionGateAnswerProvider,
    private val maxGateAbsIndex: Int = 8192
) {
    private val foundation = ExactInt.of(-15055671L)
    private val maxYearLength = ExactInt.of(5778L)
    private val minYearLength = ExactInt.of(252L)
    private val minIndexGap = ExactInt.of(6L)
    private val gapRank = GateGapRankPatchWrapper()
    private val candidateRank = Year5000InclusiveAcceptancePatchWrapper()
    private val rankIndex = Year5000RankIndexPatchWrapper()
    private val gates = mutableMapOf(ExactInt.ZERO to foundation)
    private var minIndex = ExactInt.ZERO
    private var maxIndex = ExactInt.ZERO

    init {
        require(maxGateAbsIndex >= 16 && maxGateAbsIndex <= 100000) {
            "E_POST55_GATE_RESOURCE_BOUND"
        }
    }

    val expandedGateCount: Int get() = gates.size
    val lowestIndex: ExactInt get() = minIndex
    val highestIndex: ExactInt get() = maxIndex

    fun getGate(index: ExactInt): ExactInt {
        require(index.abs() <= ExactInt.of(maxGateAbsIndex.toLong())) {
            "E_POST55_GATE_INDEX_BUDGET"
        }
        while (maxIndex < index) {
            val target = maxIndex + 1L
            val answer = gateAnswers.ask(target)
            val chosen = gapRank.patch(target, answer.firstAnswer,
                answer.directionStep).correctedGateGap
            check(chosen in 42..963) { "E_POST55_POSITIVE_GAP_RANGE" }
            val previous = gates[maxIndex] ?: error("E_POST55_POSITIVE_PREVIOUS")
            val next = previous + chosen.toLong()
            check(next > previous) { "E_POST55_NONMONOTONIC_POSITIVE" }
            gates[target] = next
            maxIndex = target
        }
        while (minIndex > index) {
            val target = minIndex - 1L
            val answer = gateAnswers.ask(target)
            val chosen = gapRank.patch(target, answer.firstAnswer,
                answer.directionStep).correctedGateGap
            check(chosen in 42..963) { "E_POST55_NEGATIVE_GAP_RANGE" }
            val previous = gates[minIndex] ?: error("E_POST55_NEGATIVE_PREVIOUS")
            val next = previous - chosen.toLong()
            check(next < previous) { "E_POST55_NONMONOTONIC_NEGATIVE" }
            gates[target] = next
            minIndex = target
        }
        return gates[index] ?: error("E_POST55_MISSING_GATE")
    }

    fun coverDays(low: ExactInt, high: ExactInt) {
        require(low <= high) { "E_POST55_INVALID_DAY_WINDOW" }
        while (getGate(minIndex) > low) {
            getGate(minIndex - 1L)
        }
        while (getGate(maxIndex) < high) {
            getGate(maxIndex + 1L)
        }
    }

    fun year5000Candidates(calculationDay: ExactInt):
        List<ProductionYear5000Candidate> {
        coverDays(calculationDay - 5778L, calculationDay + 5778L)
        val found = ArrayList<ProductionYear5000Candidate>()
        var start = minIndex
        while (start < maxIndex) {
            val open = getGate(start)
            if (open >= calculationDay) break
            var end = start + 6L
            while (end <= maxIndex) {
                val close = getGate(end)
                val length = close - open
                if (length > maxYearLength) break
                if (length >= minYearLength &&
                    end - start >= minIndexGap &&
                    open < calculationDay &&
                    calculationDay <= close
                ) {
                    found.add(ProductionYear5000Candidate(start,end,open,close))
                }
                end += 1L
            }
            start += 1L
        }
        require(found.isNotEmpty()) { "E_POST55_NO_YEAR5000_CANDIDATES" }
        return found.sortedWith(
            compareBy<ProductionYear5000Candidate> { it.length }
                .thenBy { it.openDay }
        )
    }

    /** Input stream for self-date seal=10; not constructed by this engine. */
    fun chooseYear5000(
        calculationDay: ExactInt,
        selfDateStream: ProductionAnswerStream
    ): ProductionYear5000Selection {
        val candidates = year5000Candidates(calculationDay)
        val rankOutcome = candidateRank.patch(
            selfDateStream.firstAnswer,
            selfDateStream.directionStep,
            candidates.size
        )
        val ordered = candidates.map { it.toTieCandidate() }
        val pick = rankIndex.patch(
            calculationDay, ordered,
            ExactInt.of(rankOutcome.correctedRank.toLong())
        )
        val chosen = candidates[pick.correctedIndex0]
        check(chosen.toTieCandidate() == pick.correctedChosen) {
            "E_POST55_YEAR_RANK_INDEX_INCONSISTENT"
        }
        return ProductionYear5000Selection(
            chosen,rankOutcome.correctedRank,candidates.size,
            rankOutcome.rejectedAnswers,pick.historical.wrongIndex0,
            pick.correctedIndex0
        )
    }
}
