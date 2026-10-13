package pastafari

/**
 * Cam 27 — PATCH 13. Cadw'r hen rank0, ond dewis unrank1 o
 * stream gap y giât â rejection gwirioneddol ar y terfyn.
 *
 * Nid yw'r cod cynhyrchu hwn yn defnyddio'r oracl NormativeCore.
 */
data class GateGapPatchOutcome(
    val gateIndex: ExactInt,
    val streamFirst: ExactInt,
    val directionStep: Int,
    val legacyRead: LegacyGateGapRankRead,
    val acceptedAnswer: ExactInt,
    val acceptedAnswerIndex0: Int,
    val rejectedCandidates: List<ExactInt>,
    val correctedRank1: Int,
    val correctedGateGap: Int,
    val legacyRank0Calls: Int,
    val correctedRankCalls: Int,
    val acceptedAnswerReads: Int,
    val rejectionChecks: Int,
    val seal: Int
)

class GateGapRankPatchWrapper(
    private val legacy: LegacyGateGapRankAdapter = LegacyGateGapRankAdapter()
) {
    private val m=ExactInt.parse("170141183460469231731687303715884105727")
    private val family=ExactInt.of(922L)
    private val upper=(m/family)*family

    fun patch(gateIndex:ExactInt,streamFirst:ExactInt,
              directionStep:Int):GateGapPatchOutcome {
        // Y caller hanesyddol yn gyntaf: rhaid cadw'r graith go iawn.
        val scar=legacy.oldGateGapWithoutRank1(
            gateIndex,streamFirst,directionStep)
        check(scar.oneShotReads==1 &&
            scar.rejectedCandidatesProcessed==0 &&
            scar.seal==1 &&
            scar.rank0Wrong in 0..921 &&
            scar.gateGapWrong==41+scar.rank0Wrong) {
            "E_PATCH13_LEGACY_SHAPE"
        }
        var answer=streamFirst
        val rejected=ArrayList<ExactInt>()
        // Normative answerAt(k) = 1 + (first-1 + step*k) mod M.
        // Y cam +1/-1 yw'r un cam stream, nid sample newydd annibynnol.
        while(answer>upper) {
            rejected.add(answer)
            require(rejected.size<=922){"E_PATCH13_REJECTION_BOUND"}
            answer=ExactInt.ONE+
                (answer-ExactInt.ONE+ExactInt.of(directionStep.toLong()))
                    .euclideanMod(m)
        }
        val rank=(answer-ExactInt.ONE).euclideanMod(family).toIntExact()+1
        val gap=41+rank
        check(rank in 1..922 && gap in 42..963 &&
            answer>=ExactInt.ONE && answer<=upper) {
            "E_PATCH13_CORRECTED_SHAPE"
        }
        return GateGapPatchOutcome(
            gateIndex,streamFirst,directionStep,scar,
            answer,rejected.size,rejected.toList(),
            rank,gap,1,1,rejected.size+1,rejected.size+1,1
        )
    }
}
