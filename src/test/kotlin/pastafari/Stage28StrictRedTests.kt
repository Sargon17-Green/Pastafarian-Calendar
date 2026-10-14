package pastafari

/** Cam 28: mae'r honiad anghywir hwn i fod i fethu'n fwriadol. */
object Stage28StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val oracle = NormativeCalendar()
        val legacy = LegacyNegativeGateDirectionAdapter()
        var previous = NormativeCore.FOUNDATION_DAY
        for (i in 1..24) {
            val n = ExactInt.of(i.toLong())
            val wrong = legacy.negativeGateFromPositiveGap(n, previous, oracle.positiveGateGap(n))
            val correct = oracle.gates.get(-n)
            if (wrong != correct) {
                check(wrong == correct) { "E_DISCOVERY14_STRICT_NEGATIVE_GATE_DIRECTION_RED" }
            }
            previous = correct
        }
        error("E_DISCOVERY14_NO_DIFFERENTIAL_RED")
    }
}
