package pastafari

/** Cam 48: rhaid i gyfyngiad un-seiliedig ddefnyddio gwrthodiad. */
object Stage48StrictRedTests {
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val m=NormativeCore.M
        val n=3
        val legacy=LegacyYear5000FirstAnswerModuloAdapter()
        val old=legacy.rankFromFirstAnswer(m,n)
        val actual=NormativeCore.chooseRankShort(
            NormativeCore.AnswerStream(m,-1),ExactInt.of(n.toLong())).toIntExact()
        check(legacy.shouldRejectFirstAnswer(m,n))
        check(old==actual) { "E_DISCOVERY24_STRICT_MODULO_BIAS_RED" }
        error("E_DISCOVERY24_STRICT_RED_MISSING")
    }
}
