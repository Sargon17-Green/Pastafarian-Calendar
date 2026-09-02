package pastafari

object Stage01Tests {
    private var passed = 0

    private fun check(code: String, condition: Boolean) {
        if (!condition) throw IllegalStateException(code)
        passed++
    }

    private fun checkEq(code: String, expected: Any, actual: Any) {
        if (expected != actual) throw IllegalStateException("${code}_${expected}_${actual}")
        passed++
    }

    private fun checkArray(code: String, expected: IntArray, actual: IntArray) {
        if (!expected.contentEquals(actual)) throw IllegalStateException(code)
        passed++
    }

    private fun checkExactArray(code: String, expected: List<String>, actual: Array<ExactInt>) {
        val values = actual.map { it.toString() }
        if (values != expected) throw IllegalStateException(code)
        passed++
    }

    private fun exactIntegerTests() {
        checkEq("E_T01", "0", ExactInt.ZERO.toString())
        checkEq("E_T02", "-12345678901234567890", ExactInt.parse("-12345678901234567890").toString())
        val a = ExactInt.parse("999999999999999999999999999")
        val b = ExactInt.parse("123456789012345678901234567")
        checkEq("E_T03", "1123456789012345678901234566", (a + b).toString())
        checkEq("E_T04", "876543210987654321098765432", (a - b).toString())
        checkEq("E_T05", "1219326311370217952237463801111263526900", (ExactInt.parse("12345678901234567890") * ExactInt.parse("98765432109876543210")).toString())
        val x = NormativeCore.M * NormativeCore.M + 123L
        val qr = x.divRem(NormativeCore.M)
        checkEq("E_T06", NormativeCore.M.toString(), qr.first.toString())
        checkEq("E_T07", "123", qr.second.toString())
        checkEq("E_T08", "4", ExactInt.of(-1).euclideanMod(ExactInt.of(5)).toString())
        val farDay = NormativeCore.FOUNDATION_DAY + NormativeCore.M
        checkEq("E_T09", (NormativeCore.M.multiplyByInt(2) + 1L).toString(), NormativeCore.dayCount(farDay).toString())
    }

    private fun coreFixtureTests() {
        checkEq("E_T10", "170141183460469231731687303715884105727", NormativeCore.M.toString())
        checkEq("E_T11", NormativeCore.M.toString(), NormativeCore.save(NormativeCore.M).toString())
        checkEq("E_T12", NormativeCore.M.toString(), NormativeCore.save(NormativeCore.M.multiplyByInt(2)).toString())
        checkEq("E_T13", "1", NormativeCore.save(NormativeCore.M + 1L).toString())
        checkEq("E_T14", "1", NormativeCore.dayCount(NormativeCore.FOUNDATION_DAY).toString())
        checkEq("E_T15", "2", NormativeCore.dayCount(NormativeCore.FOUNDATION_DAY - 1).toString())
        checkEq("E_T16", "3", NormativeCore.dayCount(NormativeCore.FOUNDATION_DAY + 1).toString())

        val counts = NormativeCore.workCounts(NormativeCore.FOUNDATION_DAY, NormativeCore.FOUNDATION_DAY)
        checkEq("E_T17", "1", counts.distance.toString())
        checkEq("E_T18", "2", counts.direction.toString())

        checkExactArray(
            "E_T19",
            listOf("378", "1073", "2375", "6195", "10493"),
            NormativeCore.STONES[2]
        )
        checkExactArray(
            "E_T20",
            listOf(
                "73799454308499791987382386781055001470",
                "147925408106533232424672641008220632365",
                "94499522601819303005579577099149028685",
                "108473647672201258090947028490673028834",
                "137131922036975206684616468948804344042"
            ),
            NormativeCore.STONES[46]
        )

        val hidden = NormativeCore.buildHiddenDrops(counts)
        checkEq("E_T21", "119390830530032782664128530203002080344", hidden[1].toString())
        checkEq("E_T22", "6164285870955721082771365327359496898", hidden[7].toString())
        val visible = NormativeCore.buildVisibleDrops(counts, NormativeCore.STONES, hidden)
        checkEq("E_T23", "56644603826892212324764499696091907135", visible[1].toString())
        checkEq("E_T24", "141872771689426650819909896585756512282", visible[46].toString())

        val sauce = NormativeCore.sauce(NormativeCore.FOUNDATION_DAY, NormativeCore.FOUNDATION_DAY)
        checkExactArray(
            "E_T25",
            listOf(
                "0",
                "65286679584284972964194865805379907599",
                "127720283375330263615328810127751035299",
                "54364069496183805843611594721403108554",
                "93072329024469476118876155742008280619",
                "54867842942953573450868747713087920246",
                "111207247632761530752404582123499651367"
            ),
            sauce.bowls
        )
        checkArray("E_T26", intArrayOf(4, 5, 2, 3, 6, 1), sauce.orderAtDrop46)
        val stream = NormativeCore.askBowl(sauce, 1, NormativeCore.SEAL_GATE_GAP)
        checkEq("E_T27", "90411690289794975082828500805689671121", stream.first.toString())
        checkEq("E_T28", -1, stream.directionStep)
        checkEq("E_T29", 189, NormativeCore.chooseRankInt(stream, 922))
    }

    private fun combinatorialTests() {
        val bounded = NormativeCore.BoundedCompositionFamily(12, 3, 2, 6)
        checkEq("E_T30", "19", bounded.countAll().toString())
        checkArray("E_T31", intArrayOf(2, 4, 6), bounded.unrank1(ExactInt.ONE))
        checkArray("E_T32", intArrayOf(6, 4, 2), bounded.unrank1(bounded.countAll()))

        val cutlet = NormativeCore.CutletPartitionFamily(10, 4, 5)
        checkEq("E_T33", "28", cutlet.countAll().toString())
        checkArray("E_T34", intArrayOf(1, 1, 3, 5), cutlet.unrank1(ExactInt.ONE))
        checkArray("E_T35", intArrayOf(5, 3, 1, 1), cutlet.unrank1(cutlet.countAll()))

        val weave = NormativeCore.WeavingFamily(intArrayOf(0, 2, 2, 1))
        checkEq("E_T36", "2", weave.countAll().toString())
        checkArray("E_T37", intArrayOf(1, 1, 2, 2, 3), weave.unrank1(ExactInt.ONE))
        checkArray("E_T38", intArrayOf(1, 2, 1, 2, 3), weave.unrank1(weave.countAll()))

        checkArray("E_T39", intArrayOf(1, 2, 3, 4, 5, 6), NormativeCore.unrankDistinctIndices(17, 6, ExactInt.ONE))
        checkArray(
            "E_T40",
            intArrayOf(17, 16, 15, 14, 13, 12),
            NormativeCore.unrankDistinctIndices(17, 6, NormativeCore.fallingFactorial(17, 6))
        )
    }

    private fun selectorBoundaryTests() {
        val forward = NormativeCore.AnswerStream(ExactInt.ONE, 1)
        val backward = NormativeCore.AnswerStream(ExactInt.ONE, -1)
        checkEq("E_T41", "1", NormativeCore.chooseRankShort(forward, ExactInt.ONE).toString())
        checkEq("E_T42", "1", NormativeCore.chooseRankShort(forward, NormativeCore.M).toString())
        val mPlusOne = NormativeCore.M + 1L
        val wideRank = NormativeCore.chooseRankWide(forward, mPlusOne)
        check("E_T43", wideRank >= ExactInt.ONE && wideRank <= mPlusOne)
        checkEq("E_T44", NormativeCore.M.toString(), NormativeCore.answerAt(backward, 1).toString())
    }

    private fun catalogTests() {
        val catalog = SourceLanguageCatalog.data
        checkEq("E_T50", "cy-1.0.0", catalog.version)
        checkEq("E_T51", 17, catalog.cutlets.size)
        checkEq("E_T52", 47, catalog.months.size)
        checkArray("E_T53", (1..17).toList().toIntArray(), catalog.cutlets.map { it.canonicalIndex }.toIntArray())
        checkArray("E_T54", (1..47).toList().toIntArray(), catalog.months.map { it.canonicalIndex }.toIntArray())
        checkEq("E_T55", 17, catalog.cutlets.map { it.text }.toSet().size)
        checkEq("E_T56", 47, catalog.months.map { it.text }.toSet().size)
        checkEq("E_T57", "gwenith", SourceLanguageCatalog.cutlet(12))
        checkEq("E_T58", "halen", SourceLanguageCatalog.month(44))
    }

    private fun bootstrapTests() {
        val manager = MonsterBootstrapManager()
        val a = manager.prepare(ExactInt.of(10), ExactInt.of(20))
        val b = manager.prepare(ExactInt.of(10), ExactInt.of(20))
        checkEq("E_T60", "READY", a.status)
        checkEq("E_T61", listOf("BOOT"), a.branchTrace)
        checkEq("E_T62", listOf("BOOT"), b.branchTrace)
        check("E_T63", a !== b)
        checkEq("E_T64", 2L, manager.metrics.snapshot()["bootstrap.ready"] ?: 0L)
    }

    private fun gateAndYearFixtures() {
        val calendar = NormativeCalendar()
        checkEq("E_T70", 345, calendar.positiveGateGap(ExactInt.ONE))
        checkEq("E_T71", 503, calendar.negativeGateGap(ExactInt.ONE))
        val year = calendar.year5000(NormativeCore.FOUNDATION_DAY)
        checkEq("E_T72", "5000", year.number.toString())
        checkEq("E_T73", "-4", year.openGateIndex.toString())
        checkEq("E_T74", "4", year.closeGateIndex.toString())
        checkEq("E_T75", "-15057703", year.openGateDay.toString())
        checkEq("E_T76", "-15053459", year.closeGateDay.toString())
        check("E_T77", year.closeGateDay - year.openGateDay >= ExactInt.of(252) && year.closeGateDay - year.openGateDay <= ExactInt.of(5778))
    }

    @JvmStatic
    fun main(args: Array<String>) {
        exactIntegerTests()
        coreFixtureTests()
        combinatorialTests()
        selectorBoundaryTests()
        catalogTests()
        bootstrapTests()
        gateAndYearFixtures()
        println("STAGE01_PASS_$passed")
    }
}
