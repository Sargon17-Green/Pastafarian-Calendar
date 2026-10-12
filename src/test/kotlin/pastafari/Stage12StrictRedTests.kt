package pastafari

/** Tyst diogel: disgwylir i gymhariaeth groen strict fethu ar slot 0. */
object Stage12StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY06_STRICT_ARGS" }
        val f = NormativeCore.FOUNDATION_DAY
        val expected = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f, f))[1]
        val ctx = MonsterBootstrapManager().observeLegacyPrior(f, f, 1, 1)
        val actual = ctx.discovery06PriorValue
        check(actual == null && ctx.discovery06PriorSlot == 0) {
            "E_DISCOVERY06_STRICT_SCAR_ABSENT"
        }
        println("STAGE12_STRICT_EXPECTED_FAILURE")
        check(actual == expected) { "E_DISCOVERY06_STRICT_HIDDEN_HISTORY_RED" }
    }
}
