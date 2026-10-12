package pastafari

/** Mae'r ail stir yn methu'n fwriadol oherwydd cache stir 1. */
object Stage22StrictRedTests {
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY11_STRICT_ARGS"}
        val old=listOf(0L,101L,211L,307L,401L,503L,607L).map(ExactInt::of)
        val result=LegacyCachedStirAdapter().oldCachedPostStir12(old)
        check(result.steps.size==12 && result.cachedSumComputations==1 &&
            result.steps[1].savedSumUsed==result.steps[0].savedSumUsed &&
            result.steps[1].sumCacheOriginStir==1){
            "E_DISCOVERY11_STRICT_SCAR_MISSING"
        }
        println("STAGE22_STRICT_EXPECTED_FAILURE")
        var sum=ExactInt.ZERO
        for(id in 1..6)sum+=result.steps[0].newBowls[id]
        val fresh=NormativeCore.save(sum+ExactInt.of(298L))
        check(result.steps[1].savedSumUsed==fresh){
            "E_DISCOVERY11_STRICT_STIR2_STALE_RED"
        }
    }
}
