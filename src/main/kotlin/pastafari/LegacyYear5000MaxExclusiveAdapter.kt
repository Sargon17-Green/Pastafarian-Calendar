package pastafari

/** Cam 34: craith ddamcaniaethol, nid nam cynhyrchu a brofwyd.
 * Hen gymhariaeth anghywir: hyd < 5778, lle dylai 5778 ei hun fod yn ddilys.
 */
class LegacyYear5000MaxExclusiveAdapter {
    fun acceptsCandidate(
        openGateIndex: ExactInt, closeGateIndex: ExactInt,
        openGateDay: ExactInt, closeGateDay: ExactInt,
        calculationDay: ExactInt
    ): Boolean {
        require(closeGateIndex > openGateIndex) { "E_DISCOVERY17_GATE_INDICES" }
        require(closeGateDay > openGateDay) { "E_DISCOVERY17_GATE_DAYS" }
        val length = closeGateDay - openGateDay
        return closeGateIndex - openGateIndex >= ExactInt.of(6) &&
            length >= ExactInt.of(252) &&
            length < ExactInt.of(5778) &&
            openGateDay < calculationDay &&
            calculationDay <= closeGateDay
    }
}
