package pastafari

/** Cam 28: gwahaniaeth cyfeiriad giatiau; addasydd arbrofol, nid nam cynhyrchu honedig. */
object Stage28Tests {
    private fun rejects(block: () -> Unit) {
        try {
            block()
        } catch (_: IllegalArgumentException) {
            return
        }
        error("E_DISCOVERY14_MISSING_INPUT_GUARD")
    }

    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val oracle = NormativeCalendar()
        val table = oracle.gates
        val legacy = LegacyNegativeGateDirectionAdapter()
        var red = 0
        var match = 0
        var previous = NormativeCore.FOUNDATION_DAY
        check(table.get(ExactInt.ZERO) == previous)
        check(table.minKnownGateIndex == ExactInt.ZERO)
        check(table.maxKnownGateIndex == ExactInt.ZERO)
        for (i in 1..24) {
            val n = ExactInt.of(i.toLong())
            val positiveGap = oracle.positiveGateGap(n)
            val negativeGap = oracle.negativeGateGap(n)
            val wrong = legacy.negativeGateFromPositiveGap(n, previous, positiveGap)
            val correct = table.get(-n)
            check(correct == previous - ExactInt.of(negativeGap.toLong()))
            check(wrong == previous - ExactInt.of(positiveGap.toLong()))
            check(positiveGap in 42..963 && negativeGap in 42..963)
            if (wrong == correct) match++ else red++
            previous = correct
        }
        check(red > 0) { "E_DISCOVERY14_NO_DIFFERENTIAL_RED" }
        check(red + match == 24)
        check(table.minKnownGateIndex == ExactInt.of(-24))
        check(table.get(ExactInt.of(-24)) == previous)
        check(table.get(ExactInt.ZERO) == NormativeCore.FOUNDATION_DAY)
        val positiveOne = table.get(ExactInt.ONE)
        check(positiveOne - NormativeCore.FOUNDATION_DAY ==
            ExactInt.of(oracle.positiveGateGap(ExactInt.ONE).toLong()))
        check(table.maxKnownGateIndex == ExactInt.ONE)

        // Yr un canlyniad wrth ehangu'n ôl cyn ehangu ymlaen, neu i'r gwrthwyneb.
        val other = NormativeCalendar()
        val otherTable = other.gates
        check(otherTable.get(ExactInt.ONE) == positiveOne)
        check(otherTable.get(ExactInt.of(-24)) == previous)
        check(otherTable.get(ExactInt.of(-1)) == table.get(ExactInt.of(-1)))
        check(otherTable.get(ExactInt.ZERO) == NormativeCore.FOUNDATION_DAY)

        rejects { legacy.negativeGateFromPositiveGap(ExactInt.ZERO, previous, 42) }
        rejects { legacy.negativeGateFromPositiveGap(ExactInt.of(-1), previous, 42) }
        rejects { legacy.negativeGateFromPositiveGap(ExactInt.ONE, previous, 41) }
        rejects { legacy.negativeGateFromPositiveGap(ExactInt.ONE, previous, 964) }
        val huge = ExactInt.parse("1844674407370955161600000000000000000000000000")
        val distantDay = ExactInt.parse("-100000000000000000000000000000000")
        check(legacy.negativeGateFromPositiveGap(huge, distantDay, 42) == distantDay - 42L)
        check(legacy.negativeGateFromPositiveGap(huge, distantDay, 963) == distantDay - 963L)
        check(legacy.negativeGateFromPositiveGap(ExactInt.ONE, distantDay, 42) == distantDay - 42L)

        println("STAGE28_NEGATIVE_DIRECTION_DIFFERENTIAL_RED_$red")
        println("STAGE28_NEGATIVE_DIRECTION_INCIDENTAL_MATCH_$match")
        println("STAGE28_NORMATIVE_NEGATIVE_GATE_GREEN_24")
        println("STAGE28_ORDER_INDEPENDENCE_AND_REPEAT_GREEN")
        println("STAGE28_INPUT_GUARDS_AND_BIGINT_PASS")
        println("STAGE28_EXPERIMENTAL_EXPECTED_RED_PASS")
    }
}
