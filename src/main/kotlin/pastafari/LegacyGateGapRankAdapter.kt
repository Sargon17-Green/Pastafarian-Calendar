package pastafari

/**
 * Cam 26 — DISCOVERY 13: hen caller gap y giât yn anghofio +1
 * ac yn methu cam gwrthod y stream cyn unrank1.
 *
 * Y stream cywir (bowls wedi eu holi gyda SEAL_GATE_GAP=1)
 * yw mewnbwn allanol yma: ni ddyfeisir adeiladwr sauce.
 */
data class LegacyGateGapRankRead(
    val gateIndex: ExactInt,
    val streamFirst: ExactInt,
    val streamDirectionStep: Int,
    val rank0Wrong: Int,
    val gateGapWrong: Int,
    val oneShotReads: Int,
    val rejectedCandidatesProcessed: Int,
    val seal: Int
)

class LegacyGateGapRankAdapter {
    private val modulus =
        ExactInt.parse("170141183460469231731687303715884105727")
    private val familySize = ExactInt.of(922L)

    fun oldGateGapWithoutRank1(
        gateIndex: ExactInt, streamFirst: ExactInt,
        directionStep: Int
    ): LegacyGateGapRankRead {
        require(gateIndex != ExactInt.ZERO) { "E_DISCOVERY13_ZERO_GATE_INDEX" }
        require(streamFirst >= ExactInt.ONE && streamFirst <= modulus) {
            "E_DISCOVERY13_STREAM_RANGE"
        }
        require(directionStep == 1 || directionStep == -1) {
            "E_DISCOVERY13_DIRECTION_STEP"
        }
        // Y GRAITH: cymryd ordinal 0-based o'r ateb cyntaf yn unig.
        // Mae'r norm yn 41 + unrank1(answerAt(k),922), gyda
        // gwrthod x > floor(M/922)*922. Ni wneir y naill gam.
        val rank0 = (streamFirst - ExactInt.ONE)
            .euclideanMod(familySize).toIntExact()
        val wrongGap = 41 + rank0
        check(wrongGap in 41..962)
        return LegacyGateGapRankRead(
            gateIndex,streamFirst,directionStep,rank0,wrongGap,1,0,1
        )
    }
}
