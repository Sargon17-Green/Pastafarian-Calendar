package pastafari

/** Cam 52: diffyg derbyn ar union ffin samplu, arbrawf yn unig.
 * Mae x == floor(M/n)*n yn dderbyniol; mae'r llwybr arbrofol
 * yn ei wrthod, gan symud y dewis i'r ateb nesaf.
 * Nid yw hwn yn nam sydd wedi'i brofi yn y cynhyrchiad.
 */
class LegacyYear5000ExclusiveAcceptanceAdapter {
    companion object {
        val MODULUS = ExactInt.parse("170141183460469231731687303715884105727")
    }

    fun rankOrNull(
        firstAnswer: ExactInt,
        directionStep: Int,
        candidateCount: Int,
        maximumAnswers: Int
    ): Int? {
        require(firstAnswer>=ExactInt.ONE && firstAnswer<=MODULUS) {
            "E_DISCOVERY26_FIRST_ANSWER_RANGE"
        }
        require(directionStep==1 || directionStep == -1) {
            "E_DISCOVERY26_DIRECTION"
        }
        require(candidateCount>0) { "E_DISCOVERY26_CANDIDATE_COUNT" }
        require(maximumAnswers>0) { "E_DISCOVERY26_BUDGET" }
        val n=ExactInt.of(candidateCount.toLong())
        val limit=(MODULUS/n)*n
        for(k in 0 until maximumAnswers) {
            val answer=ExactInt.ONE + (
                firstAnswer-ExactInt.ONE + ExactInt.of(directionStep.toLong()*k.toLong())
                ).euclideanMod(MODULUS)
            // Craith arbrofol: dylai hwn ddefnyddio <=, nid <.
            if(answer < limit) {
                return ((answer-ExactInt.ONE).euclideanMod(n)+ExactInt.ONE)
                    .toIntExact()
            }
        }
        return null
    }
}
