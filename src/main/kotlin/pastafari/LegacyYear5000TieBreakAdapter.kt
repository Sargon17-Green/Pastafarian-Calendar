package pastafari

/** Cam 40: ymgeisydd blwyddyn 5000 heb gyfeirio at yr oracl prawf.
 * Mae pob eitem yn disgrifio pâr o giatiau: (agored, caeedig].
 */
data class Year5000TieCandidate(
    val openGateIndex: ExactInt,
    val closeGateIndex: ExactInt,
    val openGateDay: ExactInt,
    val closeGateDay: ExactInt
) {
    val length: ExactInt get() = closeGateDay - openGateDay
}

/** Graith arbrofol, NID nam cynhyrchu a brofwyd.
 * Trefn anghywir wrth gael hyd cyfartal:
 * (hyd esgynnol, dechrau disgynnol), yn lle dechrau esgynnol.
 */
class LegacyYear5000TieBreakAdapter {
    fun order(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>
    ): List<Year5000TieCandidate> {
        require(candidates.isNotEmpty()) { "E_DISCOVERY20_EMPTY_INPUT" }
        for (candidate in candidates) {
            require(candidate.closeGateIndex > candidate.openGateIndex) {
                "E_DISCOVERY20_BAD_GATE_INDICES"
            }
            require(candidate.closeGateDay > candidate.openGateDay) {
                "E_DISCOVERY20_BAD_GATE_DAYS"
            }
        }
        val eligible = candidates.filter { candidate ->
            candidate.closeGateIndex - candidate.openGateIndex >= ExactInt.of(6) &&
                candidate.length >= ExactInt.of(252) &&
                candidate.length <= ExactInt.of(5778) &&
                candidate.openGateDay < calculationDay &&
                calculationDay <= candidate.closeGateDay
        }
        require(eligible.isNotEmpty()) { "E_DISCOVERY20_NO_ELIGIBLE_CANDIDATE" }
        return eligible.sortedWith(
            compareBy<Year5000TieCandidate> { it.length }
                .thenByDescending { it.openGateDay }
        )
    }

    fun chooseAtRank(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000TieCandidate {
        val ordered = order(calculationDay, candidates)
        require(oneBasedRank >= ExactInt.ONE &&
            oneBasedRank <= ExactInt.of(ordered.size.toLong())) {
            "E_DISCOVERY20_RANK_RANGE"
        }
        return ordered[(oneBasedRank - ExactInt.ONE).toIntExact()]
    }
}
