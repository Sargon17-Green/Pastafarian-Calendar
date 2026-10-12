package pastafari

/** Methiant BWRIADOL: ni ddylai'r mutator byw basio snapshot. */
object Stage20StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY10_STRICT_ARGS" }
        val old = listOf(0L,101L,211L,307L,401L,503L,607L)
            .map(ExactInt::of)
        val stone = MutableStoneRow(
            ExactInt.of(17L),ExactInt.of(29L),ExactInt.of(43L),
            ExactInt.of(71L),ExactInt.of(101L))
        val mutated = LegacyInPlaceBowlAdapter().mutateBowlsWrong(
            ExactInt.ONE,1,old,stone)
        check(mutated.writes.size == 6 &&
            mutated.writes[0].newValue == mutated.newBowls[1] &&
            mutated.writes[1].previousLiveRead ==
                mutated.writes[0].newValue &&
            mutated.writes[1].previousLiveRead != old[1]) {
            "E_DISCOVERY10_STRICT_SCAR_MISSING"
        }
        println("STAGE20_STRICT_EXPECTED_FAILURE")
        val order = NormativeCore.bowlOrderFromDrop(ExactInt.ONE)
        val patchedPour = mutated.pourPatch.correctedPours
        val id = order[1]
        val prev = order[0]
        val next = order[2]
        val base = old[id] + old[prev].multiplyByInt(2) +
            old[next].multiplyByInt(3) + patchedPour[2] +
            ExactInt.ONE + stone.barley
        val correct = NormativeCore.save(base.square() +
            (old[prev]*old[next]).multiplyByInt(5) + 2L)
        check(mutated.newBowls[id] == correct) {
            "E_DISCOVERY10_STRICT_INPLACE_POSITION2_RED"
        }
    }
}
