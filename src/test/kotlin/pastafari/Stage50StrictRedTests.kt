package pastafari

/** Cam 50: methiant disgwyliedig gan nad yw M+1 yn lapio i 1. */
object Stage50StrictRedTests {
    @JvmStatic fun main(args:Array<String>) {
        require(args.isEmpty())
        val m=NormativeCore.M
        val legacy=LegacyYear5000UnwrappedAnswerAdapter()
        val expected=NormativeCore.chooseRankShort(
            NormativeCore.AnswerStream(m,1),ExactInt.of(3)).toIntExact()
        check(expected==1)
        check(legacy.tryRank(m,1,3,5)==expected) {
            "E_DISCOVERY25_STRICT_MISSING_MODULUS_WRAP_RED"
        }
        error("E_DISCOVERY25_STRICT_RED_MISSING")
    }
}
