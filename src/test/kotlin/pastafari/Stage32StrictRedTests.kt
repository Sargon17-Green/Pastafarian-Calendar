package pastafari

/** Cam 32: dylai'r honiad hen saith bwlch fethu yn fwriadol. */
object Stage32StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val oracle = NormativeCalendar()
        val old = LegacyYear5000MinSevenAdapter()
        for (i in -20..20) {
            val a = ExactInt.of(i.toLong())
            val b = a + 6L
            val open = oracle.gates.get(a)
            val close = oracle.gates.get(b)
            val day = open + 1L
            val wrong = old.acceptsCandidate(a,b,open,close,day)
            val expected = b-a >= ExactInt.of(6) &&
                close-open >= ExactInt.of(252) &&
                close-open <= ExactInt.of(5778) &&
                open < day && day <= close
            check(wrong == expected) {
                "E_DISCOVERY16_STRICT_MIN_SEVEN_RED"
            }
        }
        error("E_DISCOVERY16_STRICT_NO_DIFFERENTIAL")
    }
}
