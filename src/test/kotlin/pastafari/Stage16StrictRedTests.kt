package pastafari

/** Methu'n fwriadol os ceisir cyflwyno'r order anghywir fel GREEN. */
object Stage16StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY08_STRICT_ARGS" }
        val raw = LegacyPermutationOrderAdapter()
            .legacyPermutationOrderFromDropWrong(ExactInt.ONE)
        check(raw.oneBased == 1 && raw.passedRank0 == 1 &&
            raw.legacyOrder == listOf(1,2,3,4,6,5) &&
            !raw.undefined) { "E_DISCOVERY08_STRICT_SCAR_MISSING" }
        println("STAGE16_STRICT_EXPECTED_FAILURE")
        check(raw.legacyOrder == NormativeCore.bowlOrderFromDrop(ExactInt.ONE).toList()) {
            "E_DISCOVERY08_STRICT_RANK1_RED"
        }
    }
}
