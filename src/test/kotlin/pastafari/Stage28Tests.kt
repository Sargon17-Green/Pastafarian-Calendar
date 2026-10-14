package pastafari

/** Stage 28: test-only normative comparison of an isolated legacy hypothesis. */
object Stage28Tests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val table = NormativeCalendar().GateTable()
        val legacy = LegacyNegativeGateDirectionAdapter()
        var red = 0
        var match = 0
        var previous = NormativeCore.FOUNDATION_DAY
        check(table.get(ExactInt.ZERO) == previous)
        for (i in 1..24) {
            val n = ExactInt.of(i.toLong())
            val positiveGap = table.positiveGateGap(n)
            val negativeGap = table.negativeGateGap(n)
            val wrong = legacy.negativeGateFromPositiveGap(n, previous, positiveGap)
            val correct = table.get(ExactInt.ZERO - n)
            check(correct == previous - ExactInt.of(negativeGap.toLong()))
            check(wrong == previous - ExactInt.of(positiveGap.toLong()))
            check(positiveGap in 42..963 && negativeGap in 42..963)
            if (wrong == correct) match++ else red++
            previous = correct
        }
        check(red > 0) { "E_DISCOVERY14_NO_DIFFERENTIAL_RED" }
        check(red + match == 24)
        check(table.get(ExactInt.ZERO - ExactInt.of(24L)) == previous)
        check(table.get(ExactInt.ONE) > NormativeCore.FOUNDATION_DAY)
        println("STAGE28_NEGATIVE_DIRECTION_DIFFERENTIAL_RED_$red")
        println("STAGE28_NEGATIVE_DIRECTION_INCIDENTAL_MATCH_$match")
        println("STAGE28_NORMATIVE_NEGATIVE_GATE_GREEN_24")
        println("STAGE28_EXPERIMENTAL_EXPECTED_RED_PASS")
    }
}
