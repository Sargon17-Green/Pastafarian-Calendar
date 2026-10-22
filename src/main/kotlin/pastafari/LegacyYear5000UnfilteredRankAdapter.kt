package pastafari

/** Cam 44: anghysondeb arbrofol, nid nam sydd wedi'i brofi mewn cynhyrchu.
 * Mae'r drefn etifeddol yn dewis rheng ar ôl trefnu pob pâr, hyd yn oed
 * y rhai sydd y tu allan i derfynau'r flwyddyn.
 */
class LegacyYear5000UnfilteredRankAdapter {
    fun allCandidatesSorted(
        candidates: List<Year5000TieCandidate>
    ): List<Year5000TieCandidate> {
        require(candidates.isNotEmpty()) { "E_DISCOVERY22_EMPTY_INPUT" }
        for (c in candidates) {
            require(c.closeGateIndex > c.openGateIndex) {
                "E_DISCOVERY22_GATE_ORDER"
            }
            require(c.closeGateDay > c.openGateDay) {
                "E_DISCOVERY22_DAY_ORDER"
            }
        }
        return candidates.sortedWith(
            compareBy<Year5000TieCandidate> { it.length }
                .thenBy { it.openGateDay }
        )
    }

    fun chooseUnfiltered(
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000TieCandidate {
        val unfiltered = allCandidatesSorted(candidates)
        require(oneBasedRank >= ExactInt.ONE &&
            oneBasedRank <= ExactInt.of(unfiltered.size.toLong())) {
            "E_DISCOVERY22_RANK_RANGE"
        }
        return unfiltered[(oneBasedRank - ExactInt.ONE).toIntExact()]
    }

    fun accepts(
        calculationDay: ExactInt,
        candidate: Year5000TieCandidate
    ): Boolean {
        return candidate.closeGateIndex-candidate.openGateIndex >= ExactInt.of(6) &&
            candidate.length >= ExactInt.of(252) &&
            candidate.length <= ExactInt.of(5778) &&
            candidate.openGateDay < calculationDay &&
            calculationDay <= candidate.closeGateDay
    }
}
