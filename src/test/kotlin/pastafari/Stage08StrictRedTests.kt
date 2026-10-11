package pastafari

/** Y methiant bwriadol yn unig; ni ddylai'r strict oracle basio eto. */
object Stage08StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val actual = MonsterBootstrapManager().observeLegacyStones(ExactInt.ZERO, ExactInt.ZERO)
            .discovery04LegacyStoneRows ?: error("E_DISCOVERY04_STRICT_NO_ROWS")
        val expected = NormativeCore.STONES
        val mismatch = (2..46).sumOf { i -> (0..4).count { k ->
            actual[i].components()[k] != expected[i][k]
        } }
        check(mismatch == 224) { "E_DISCOVERY04_STRICT_WRONG_CAUSE_$mismatch" }
        println("STAGE08_STRICT_EXPECTED_FAILURE")
        throw IllegalStateException("E_DISCOVERY04_STRICT_EXPECTED_RED_224")
    }
}
