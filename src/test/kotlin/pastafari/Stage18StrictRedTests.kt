package pastafari

/** Mae cymharu'r arllwys etifeddol â'r un normadol yn methu'n fwriadol. */
object Stage18StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY09_STRICT_ARGS" }
        val old = listOf(0L,100L,200L,300L,400L,500L,600L).map(ExactInt::of)
        val row = MutableStoneRow(ExactInt.of(17),ExactInt.of(29),
            ExactInt.of(43),ExactInt.of(71),ExactInt.of(101))
        val read = LegacyFixedPourAdapter().oldFixedPour(ExactInt.of(720),1,old,row)
        check(read.sourceIdsWrong == listOf(1,2,3) &&
            read.sourceIdsByPosition == listOf(6,5,4)) {
            "E_DISCOVERY09_STRICT_SCAR_ABSENT"
        }
        println("STAGE18_STRICT_EXPECTED_FAILURE")
        val expected = NormativeCore.save(ExactInt.of(720).square() +
            row.wheat * old[6] + 3L)
        check(read.pours[1] == expected) {
            "E_DISCOVERY09_STRICT_REVERSED_SOURCES_RED"
        }
    }
}
