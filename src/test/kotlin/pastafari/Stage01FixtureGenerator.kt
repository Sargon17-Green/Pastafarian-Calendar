package pastafari

object Stage01FixtureGenerator {
    @JvmStatic
    fun main(args: Array<String>) {
        val c = NormativeCore.FOUNDATION_DAY
        val counts = NormativeCore.workCounts(c, c)
        val hidden = NormativeCore.buildHiddenDrops(counts)
        val visible = NormativeCore.buildVisibleDrops(counts, NormativeCore.STONES, hidden)
        val sauce = NormativeCore.sauce(c, c)
        val ask1 = NormativeCore.askBowl(sauce, 1, NormativeCore.SEAL_GATE_GAP)
        val bounded = NormativeCore.BoundedCompositionFamily(12, 3, 2, 6)
        val cutlet = NormativeCore.CutletPartitionFamily(10, 4, 5)
        val weave = NormativeCore.WeavingFamily(intArrayOf(0, 2, 2, 1))
        val calendar = NormativeCalendar()
        val year = calendar.year5000(c)

        val rows = listOf(
            "M" to NormativeCore.M.toString(),
            "SAVE_M" to NormativeCore.save(NormativeCore.M).toString(),
            "SAVE_2M" to NormativeCore.save(NormativeCore.M.multiplyByInt(2)).toString(),
            "SAVE_M_PLUS_1" to NormativeCore.save(NormativeCore.M + 1L).toString(),
            "DAY_FOUNDATION" to NormativeCore.dayCount(c).toString(),
            "DAY_FOUNDATION_MINUS_1" to NormativeCore.dayCount(c - 1).toString(),
            "DAY_FOUNDATION_PLUS_1" to NormativeCore.dayCount(c + 1).toString(),
            "STONE_2" to NormativeCore.STONES[2].joinToString(","),
            "STONE_46" to NormativeCore.STONES[46].joinToString(","),
            "HIDDEN_1" to hidden[1].toString(),
            "HIDDEN_7" to hidden[7].toString(),
            "VISIBLE_1" to visible[1].toString(),
            "VISIBLE_46" to visible[46].toString(),
            "SAUCE_BOWLS" to (1..6).joinToString(",") { sauce.bowls[it].toString() },
            "ORDER_46" to sauce.orderAtDrop46.joinToString(","),
            "ASK1_FIRST" to ask1.first.toString(),
            "ASK1_STEP" to ask1.directionStep.toString(),
            "PICK_922" to NormativeCore.chooseRankInt(ask1, 922).toString(),
            "BOUNDED_COUNT" to bounded.countAll().toString(),
            "BOUNDED_RANK_1" to bounded.unrank1(ExactInt.ONE).joinToString(","),
            "BOUNDED_RANK_LAST" to bounded.unrank1(bounded.countAll()).joinToString(","),
            "CUTLET_COUNT" to cutlet.countAll().toString(),
            "CUTLET_RANK_1" to cutlet.unrank1(ExactInt.ONE).joinToString(","),
            "CUTLET_RANK_LAST" to cutlet.unrank1(cutlet.countAll()).joinToString(","),
            "WEAVE_COUNT" to weave.countAll().toString(),
            "WEAVE_RANK_1" to weave.unrank1(ExactInt.ONE).joinToString(","),
            "WEAVE_RANK_LAST" to weave.unrank1(weave.countAll()).joinToString(","),
            "DISTINCT_17_6_FIRST" to NormativeCore.unrankDistinctIndices(17, 6, ExactInt.ONE).joinToString(","),
            "DISTINCT_17_6_LAST" to NormativeCore.unrankDistinctIndices(17, 6, NormativeCore.fallingFactorial(17, 6)).joinToString(","),
            "GATE_POS_1" to calendar.positiveGateGap(ExactInt.ONE).toString(),
            "GATE_NEG_1" to calendar.negativeGateGap(ExactInt.ONE).toString(),
            "YEAR5000_FOUNDATION" to listOf(year.number, year.openGateIndex, year.closeGateIndex, year.openGateDay, year.closeGateDay).joinToString(",")
        )
        for ((key, value) in rows) println("$key\t$value")
    }
}
