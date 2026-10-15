package pastafari

/** Cam 30 — damcaniaeth hanesyddol yn unig, nid nam cynhyrchu profedig.
 * Y graith yw defnyddio [agored, caeedig] yn lle (agored, caeedig]
 * wrth ddewis ymgeiswyr blwyddyn 5000.
 */
class LegacyYear5000OpeningAdapter {
    fun acceptsCandidate(
        openGateIndex: ExactInt,
        closeGateIndex: ExactInt,
        openGateDay: ExactInt,
        closeGateDay: ExactInt,
        calculationDay: ExactInt
    ): Boolean {
        require(closeGateIndex - openGateIndex >= ExactInt.of(6)) {
            "E_DISCOVERY15_MIN_SIX_GATE_GAPS"
        }
        require(closeGateDay > openGateDay) { "E_DISCOVERY15_GATE_ORDER" }
        val length = closeGateDay - openGateDay
        val allowedLength =
            length >= ExactInt.of(252) && length <= ExactInt.of(5778)
        return allowedLength &&
            openGateDay <= calculationDay &&
            calculationDay <= closeGateDay
    }
}
