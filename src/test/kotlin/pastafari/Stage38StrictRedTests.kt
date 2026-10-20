package pastafari

/** Cam 38: mae'r hen wirio diwrnod cau'n methu'n fwriadol. */
object Stage38StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val calendar = NormativeCalendar()
        val f = NormativeCore.FOUNDATION_DAY
        val selected = calendar.year5000(f)
        val wrong = LegacyYear5000ClosingExclusiveAdapter().acceptsCandidate(
            selected.openGateIndex, selected.closeGateIndex,
            selected.openGateDay, selected.closeGateDay,
            selected.closeGateDay)
        val correct = selected.openGateDay < selected.closeGateDay &&
            selected.closeGateDay <= selected.closeGateDay &&
            selected.closeGateDay - selected.openGateDay >=
                ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            selected.closeGateDay - selected.openGateDay <=
                ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            selected.closeGateIndex - selected.openGateIndex >= ExactInt.of(6)
        check(wrong == correct) { "E_DISCOVERY19_STRICT_CLOSE_GATE_RED" }
        error("E_DISCOVERY19_STRICT_NO_RED")
    }
}
