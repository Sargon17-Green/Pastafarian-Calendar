package pastafari

/** Cam 30: rhaid i'r un honiad anghywir fethu'n fwriadol. */
object Stage30StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val calendar = NormativeCalendar()
        val historical = LegacyYear5000OpeningAdapter()
        for (i in -12..12) {
            val openIndex = ExactInt.of(i.toLong())
            val closeIndex = openIndex + 6L
            val open = calendar.gates.get(openIndex)
            val close = calendar.gates.get(closeIndex)
            val incorrect = historical.acceptsCandidate(
                openIndex, closeIndex, open, close, open)
            val normative = open < open && open <= close
            check(incorrect == normative) {
                "E_DISCOVERY15_STRICT_OPEN_GATE_RED"
            }
        }
        error("E_DISCOVERY15_NO_STRICT_RED")
    }
}
