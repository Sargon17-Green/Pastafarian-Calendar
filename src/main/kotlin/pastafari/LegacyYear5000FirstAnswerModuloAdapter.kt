package pastafari

/** Cam 48: arbrawf yn unig, nid diffyg mewn cod cynhyrchu.
 * Mae'r hen lwybr yn defnyddio'r ateb cyntaf yn uniongyrchol,
 * heb wrthod gwerth y tu hwnt i luosrif llawn nifer yr ymgeiswyr.
 */
class LegacyYear5000FirstAnswerModuloAdapter {
    companion object {
        val ANSWER_MODULUS: ExactInt =
            ExactInt.parse("170141183460469231731687303715884105727")
    }
    fun rankFromFirstAnswer(firstAnswer: ExactInt, candidateCount: Int): Int {
        require(candidateCount>0) { "E_DISCOVERY24_NO_CANDIDATES" }
        require(firstAnswer>=ExactInt.ONE && firstAnswer<=ANSWER_MODULUS) {
            "E_DISCOVERY24_ANSWER_RANGE"
        }
        return ((firstAnswer-ExactInt.ONE)
            .euclideanMod(ExactInt.of(candidateCount.toLong())) +
            ExactInt.ONE).toIntExact()
    }

    fun shouldRejectFirstAnswer(
        firstAnswer: ExactInt, candidateCount: Int
    ): Boolean {
        require(candidateCount>0) { "E_DISCOVERY24_NO_CANDIDATES" }
        require(firstAnswer>=ExactInt.ONE && firstAnswer<=ANSWER_MODULUS) {
            "E_DISCOVERY24_ANSWER_RANGE"
        }
        val n=ExactInt.of(candidateCount.toLong())
        val limit=(ANSWER_MODULUS/n)*n
        return firstAnswer>limit
    }
}
