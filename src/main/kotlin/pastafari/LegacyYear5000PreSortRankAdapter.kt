package pastafari

/** Cam 42: graith arbrofol, NID nam a brofwyd yn y cod cynhyrchu.
 * Yr hen drefn yw cymhwyso'r rheng cyn trefnu ymgeiswyr blwyddyn 5000.
 * Gwneir y prawf ar set derfynol o ymgeiswyr a ddarperir, heb oracl.
 */
class LegacyYear5000PreSortRankAdapter {
    fun eligibleInEncounterOrder(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>
    ): List<Year5000TieCandidate> {
        require(candidates.isNotEmpty()) { "E_DISCOVERY21_EMPTY_INPUT" }
        for (c in candidates) {
            require(c.closeGateIndex > c.openGateIndex) {
                "E_DISCOVERY21_INVALID_INDICES"
            }
            require(c.closeGateDay > c.openGateDay) {
                "E_DISCOVERY21_INVALID_DAYS"
            }
        }
        val eligible=candidates.filter { c ->
            c.closeGateIndex-c.openGateIndex>=ExactInt.of(6) &&
                c.length>=ExactInt.of(252) &&
                c.length<=ExactInt.of(5778) &&
                c.openGateDay<calculationDay &&
                calculationDay<=c.closeGateDay
        }
        require(eligible.isNotEmpty()) { "E_DISCOVERY21_NO_ELIGIBLE" }
        return eligible
    }

    fun chooseAtRank(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000TieCandidate {
        val encounter=eligibleInEncounterOrder(calculationDay,candidates)
        require(oneBasedRank>=ExactInt.ONE &&
            oneBasedRank<=ExactInt.of(encounter.size.toLong())) {
            "E_DISCOVERY21_RANK_RANGE"
        }
        return encounter[(oneBasedRank-ExactInt.ONE).toIntExact()]
    }
}
