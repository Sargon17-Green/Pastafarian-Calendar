package pastafari

/** Cam 52: methiant bwriadol os yw'r llwybr yn gwrthod y ffin. */
object Stage52StrictRedTests {
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty())
        val m=NormativeCore.M
        val n=ExactInt.of(3)
        val edge=(m/n)*n
        val historical=LegacyYear5000ExclusiveAcceptanceAdapter()
            .rankOrNull(edge,-1,3,3)
        val canonical=NormativeCore.chooseRankShort(
            NormativeCore.AnswerStream(edge,-1),n).toIntExact()
        check(canonical==3 && historical==2)
        check(historical==canonical) {
            "E_DISCOVERY26_STRICT_ACCEPTANCE_BOUNDARY_RED"
        }
        error("E_DISCOVERY26_STRICT_RED_MISSING")
    }
}
