package pastafari

/** Cam 46 — craith arbrofol, nid nam cynhyrchu a brofwyd.
 * Mae rhaniad sganio hanesyddol yn ail-adrodd y pâr cymwys cyntaf.
 * Mae'r rhestr ddilys wedi'i threfnu, ond mae'r dyblygiad yn symud rhengoedd.
 */
class LegacyYear5000RepeatedCandidateAdapter {
    fun candidatesWithOverlap(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>
    ): List<Year5000TieCandidate> {
        require(candidates.isNotEmpty()) { "E_DISCOVERY23_EMPTY_INPUT" }
        for(c in candidates) {
            require(c.closeGateIndex > c.openGateIndex) {
                "E_DISCOVERY23_GATE_INDEX_ORDER"
            }
            require(c.closeGateDay > c.openGateDay) {
                "E_DISCOVERY23_GATE_DAY_ORDER"
            }
        }
        val eligible=candidates.filter { c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
                c.length>=ExactInt.of(252) && c.length<=ExactInt.of(5778) &&
                c.openGateDay<calculationDay &&
                calculationDay<=c.closeGateDay
        }.sortedWith(compareBy<Year5000TieCandidate>{it.length}
            .thenBy{it.openGateDay})
        require(eligible.isNotEmpty()) { "E_DISCOVERY23_NO_ELIGIBLE" }
        // Gwall sganio arbrofol: mae'r un ffin ymgeisydd yn cael ei chyfrif ddwywaith.
        return listOf(eligible.first())+eligible
    }

    fun chooseAtRank(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000TieCandidate {
        val repeated=candidatesWithOverlap(calculationDay,candidates)
        require(oneBasedRank>=ExactInt.ONE &&
            oneBasedRank<=ExactInt.of(repeated.size.toLong())) {
            "E_DISCOVERY23_RANK_RANGE"
        }
        return repeated[(oneBasedRank-ExactInt.ONE).toIntExact()]
    }
}
