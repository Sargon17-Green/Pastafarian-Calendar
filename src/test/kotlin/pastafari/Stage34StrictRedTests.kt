package pastafari

/** Cam 34: rhaid i'r hen honiad fod yn goch ar y terfyn 5778. */
object Stage34StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty())
        val a=ExactInt.ZERO
        val b=ExactInt.of(6)
        val start=NormativeCore.FOUNDATION_DAY
        val end=start+5778L
        val c=start+1L
        val legacy=LegacyYear5000MaxExclusiveAdapter()
            .acceptsCandidate(a,b,start,end,c)
        val normative=(b-a>=ExactInt.of(6) &&
            end-start<=ExactInt.of(NormativeCore.YEAR_MAX_DAYS.toLong()) &&
            end-start>=ExactInt.of(NormativeCore.YEAR_MIN_DAYS.toLong()) &&
            start<c && c<=end)
        check(legacy==normative) { "E_DISCOVERY17_STRICT_MAX_5778_RED" }
        error("E_DISCOVERY17_STRICT_NO_RED")
    }
}
