package pastafari

/**
 * Component-level independent soak bridge: production rank-selection wrappers only.
 * No NormativeCore/NormativeCalendar imports; NOT a full-date converter.
 * Input/output (tab separated): G|Y, signedGateIndex|candidateCount, first, step,
 * followed on output by correctedRank, gateGapOrZero, rejectedAnswers.
 */
object Post55ProductionRankBridge {
    @JvmStatic
    fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_COMPONENT_ARGS" }
        val gap = GateGapRankPatchWrapper()
        val year = Year5000InclusiveAcceptancePatchWrapper()
        while (true) {
            val line = readLine() ?: break
            val f = line.split('\t')
            require(f.size == 4) { "E_COMPONENT_INPUT_FIELDS" }
            val kind = f[0]
            val id = ExactInt.parse(f[1])
            val first = ExactInt.parse(f[2])
            val step = f[3].toInt()
            val rank: Int
            val gapValue: Int
            val rejected: Int
            when (kind) {
                "G" -> {
                    val result = gap.patch(id, first, step)
                    rank = result.correctedRank1
                    gapValue = result.correctedGateGap
                    rejected = result.rejectedCandidates.size
                }
                "Y" -> {
                    val count = id.toIntExact()
                    val result = year.patch(first, step, count)
                    rank = result.correctedRank
                    gapValue = 0
                    rejected = result.rejectedAnswers
                }
                else -> throw IllegalArgumentException("E_COMPONENT_KIND")
            }
            println(listOf(kind, id.toString(), first.toString(), step.toString(),
                rank.toString(), gapValue.toString(), rejected.toString()
            ).joinToString("\t"))
        }
    }
}
