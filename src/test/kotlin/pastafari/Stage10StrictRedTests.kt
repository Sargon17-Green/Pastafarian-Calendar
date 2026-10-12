package pastafari

/** Yn fwriadol: rhaid i ddisgwyliad GREEN fethu ar yr hen ddarllenydd. */
object Stage10StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        val f = NormativeCore.FOUNDATION_DAY
        val actual = MonsterBootstrapManager().observeLegacyHiddenDrop(f, f).discovery05Actual
        val expected = NormativeCore.buildHiddenDrops(NormativeCore.workCounts(f, f))[1]
        check(actual != expected) { "E_DISCOVERY05_STRICT_WITNESS_NOT_RED" }
        println("STAGE10_STRICT_EXPECTED_FAILURE")
        check(actual == expected) { "E_DISCOVERY05_STRICT_K1_RED_CONFIRMED" }
    }
}
