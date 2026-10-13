package pastafari

/** Prawf methiant BWRIADOL: rank0 nid yw unrank1 giât. */
object Stage26StrictRedTests {
    @JvmStatic fun main(args:Array<String>){
        require(args.isEmpty()){"E_DISCOVERY13_STRICT_ARGS"}
        val wrong=LegacyGateGapRankAdapter().oldGateGapWithoutRank1(
            ExactInt.ONE,ExactInt.ONE,1)
        check(wrong.rank0Wrong==0 && wrong.gateGapWrong==41 &&
            wrong.oneShotReads==1 && wrong.rejectedCandidatesProcessed==0){
            "E_DISCOVERY13_STRICT_SCAR_MISSING"
        }
        println("STAGE26_STRICT_EXPECTED_FAILURE")
        val norm=41+NormativeCore.chooseRankInt(
            NormativeCore.AnswerStream(ExactInt.ONE,1),922)
        check(wrong.gateGapWrong==norm){
            "E_DISCOVERY13_STRICT_GATE_RANK0_RED"
        }
    }
}
