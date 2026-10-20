package pastafari

/** Cam 36: rhaid i'r hen honiad fod yn goch ar y terfyn 252. */
object Stage36StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val a=ExactInt.ZERO
        val b=ExactInt.of(6)
        val start=NormativeCore.FOUNDATION_DAY
        val end=start+252L
        val c=start+1L
        val legacy=LegacyYear5000MinExclusiveAdapter()
            .acceptsCandidate(a,b,start,end,c)
        val normative=(b-a>=ExactInt.of(6) &&
            end-start<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            end-start>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            start<c && c<=end)
        check(legacy==normative) { "E_DISCOVERY18_STRICT_MIN_252_RED" }
        error("E_DISCOVERY18_STRICT_NO_RED")
    }
}
