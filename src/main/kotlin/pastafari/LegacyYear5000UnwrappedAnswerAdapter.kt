package pastafari

/** Cam 50: nam arbrofol ar ymyl cylch y llif atebion.
 * Yn fwriadol, nid yw'r addasydd hwn yn lapio ateb M+1 i 1.
 * Ni honnir bod y nam yn bodoli yn y cynhyrchiad go iawn.
 */
class LegacyYear5000UnwrappedAnswerAdapter {
    companion object {
        val MODULUS: ExactInt =
            ExactInt.parse("170141183460469231731687303715884105727")
    }

    /** Mae null yn golygu nad oedd ateb derbyniol yn y gyllideb ymholiadau. */
    fun tryRank(
        firstAnswer: ExactInt,
        directionStep: Int,
        candidateCount: Int,
        maximumAnswers: Int
    ): Int? {
        require(firstAnswer>=ExactInt.ONE && firstAnswer<=MODULUS) {
            "E_DISCOVERY25_FIRST_ANSWER_RANGE"
        }
        require(directionStep==1 || directionStep == -1) {
            "E_DISCOVERY25_DIRECTION"
        }
        require(candidateCount>0) { "E_DISCOVERY25_EMPTY_CANDIDATES" }
        require(maximumAnswers>0) { "E_DISCOVERY25_MAXIMUM_ANSWERS" }
        val size=ExactInt.of(candidateCount.toLong())
        val ceiling=(MODULUS/size)*size
        for(index in 0 until maximumAnswers){
            val raw=firstAnswer+
                ExactInt.of(directionStep.toLong()*index.toLong())
            if(raw>=ExactInt.ONE && raw<=ceiling){
                return ((raw-ExactInt.ONE).euclideanMod(size)+ExactInt.ONE)
                    .toIntExact()
            }
        }
        return null
    }
}
