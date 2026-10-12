package pastafari

/** Mae'r cymydog rhifol anghywir yn METHU'N FWRIADOL. */
object Stage24StrictRedTests {
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY12_STRICT_ARGS"}
        val bowls=listOf(0L,101L,211L,307L,401L,503L,607L)
            .map(ExactInt::of)
        val result=LegacyNumericNeighborAdapter().oldNumericNeighborQuestion(
            bowls,ExactInt.of(720L),6,31)
        check(result.drop46Order==listOf(6,5,4,3,2,1) &&
            result.queriedBowlId==6 &&
            result.actualNeighborIdWrong==1 &&
            result.positionalNeighborIdExpected==5 &&
            result.permutationPatchCalls==1){
            "E_DISCOVERY12_STRICT_SCAR_MISSING"
        }
        println("STAGE24_STRICT_EXPECTED_FAILURE")
        val actualNormative=NormativeCore.askBowl(
            NormativeCore.SauceResult(
                bowls.toTypedArray(),intArrayOf(6,5,4,3,2,1)),6,31)
        check(result.firstAnswer==actualNormative.first){
            "E_DISCOVERY12_STRICT_NUMERIC_NEIGHBOR_RED"
        }
    }
}
