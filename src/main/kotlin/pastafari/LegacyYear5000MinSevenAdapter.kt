package pastafari

/** Cam 32: damcaniaeth arbrofol hanesyddol, nid nam cynhyrchu profedig.
 * Defnyddio saith bwlch giât o leiaf yn anghywir; chwech yw'r lleiafswm.
 */
class LegacyYear5000MinSevenAdapter {
    fun acceptsCandidate(
        openGateIndex: ExactInt, closeGateIndex: ExactInt,
        openGateDay: ExactInt, closeGateDay: ExactInt,
        calculationDay: ExactInt
    ): Boolean {
        require(closeGateIndex > openGateIndex) {
            "E_DISCOVERY16_GATE_INDICES"
        }
        require(closeGateDay > openGateDay) {
            "E_DISCOVERY16_GATE_DAYS"
        }
        val length = closeGateDay - openGateDay
        return closeGateIndex - openGateIndex >= ExactInt.of(7) &&
            length >= ExactInt.of(252) &&
            length <= ExactInt.of(5778) &&
            openGateDay < calculationDay &&
            calculationDay <= closeGateDay
    }
}
