package pastafari

/** Rhaid methu: tyst o'r graith, nid gwall o fath arall. */
object Stage06StrictRedTests {
    @JvmStatic
    fun main(args: Array<String>) {
        val f = NormativeCore.FOUNDATION_DAY
        val legacy = MonsterBootstrapManager().observeLegacyDistance(f, f).discovery03Output
        check(legacy == ExactInt.ZERO) { "E_DISCOVERY03_STRICT_WRONG_SCAR" }
        println("STAGE06_STRICT_EXPECTED_FAILURE")
        check(legacy == NormativeCore.workCounts(f, f).distance) { "E_DISCOVERY03_STRICT_RED_EXPECTED" }
    }
}
