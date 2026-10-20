package pastafari

/** Cam 38: craith dybiedig, nid nam cynhyrchu wedi'i brofi.
 * Mae'r hen lwybr yn cau'r flwyddyn ar y dde yn anghywir.
 * Dilys: open < c <= close; hen: open < c < close.
 */
class LegacyYear5000ClosingExclusiveAdapter {
    fun acceptsCandidate(
        openGateIndex: ExactInt, closeGateIndex: ExactInt,
        openGateDay: ExactInt, closeGateDay: ExactInt,
        calculationDay: ExactInt
    ): Boolean {
        require(closeGateIndex > openGateIndex) { "E_DISCOVERY19_GATE_INDICES" }
        require(closeGateDay > openGateDay) { "E_DISCOVERY19_GATE_DAYS" }
        val length = closeGateDay - openGateDay
        return closeGateIndex - openGateIndex >= ExactInt.of(6) &&
            length >= ExactInt.of(252) &&
            length <= ExactInt.of(5778) &&
            openGateDay < calculationDay &&
            calculationDay < closeGateDay
    }
}
