package pastafari

/** Production sealed-answer rank sampler; no test-oracle dependency. */
class ProductionRankSampler(private val maxRejections: Int = 100000) {
    private val m=ExactInt.parse("170141183460469231731687303715884105727")
    init { require(maxRejections in 1..1000000) { "E_RANK_BUDGET" } }
    private fun answerAt(stream:ProductionAnswerStream,j:Int):ExactInt =
        ExactInt.ONE + (stream.firstAnswer-ExactInt.ONE +
            ExactInt.of(j.toLong()).multiplyByInt(stream.directionStep)).euclideanMod(m)

    fun choose(stream:ProductionAnswerStream,n:ExactInt):ExactInt {
        require(n>=ExactInt.ONE) { "E_RANK_CHOICES" }
        require(stream.firstAnswer>=ExactInt.ONE && stream.firstAnswer<=m) { "E_RANK_ANSWER" }
        require(stream.directionStep==1 || stream.directionStep == -1) { "E_RANK_DIRECTION" }
        if(n<=m) {
            val limit=(m/n)*n
            var x=stream.firstAnswer
            var rejects=0
            while(x>limit) {
                check(rejects<maxRejections) { "E_RANK_REJECTION_BUDGET" }
                rejects++
                x=ExactInt.ONE+(x-ExactInt.ONE+
                    stream.directionStep.toLong()).euclideanMod(m)
            }
            return (x-ExactInt.ONE).euclideanMod(n)+ExactInt.ONE
        }
        var places=1
        var space=m
        while(space<n) {
            check(places<256) { "E_RANK_WIDE_DIGIT_BUDGET" }
            space*=m
            places++
        }
        var x=ExactInt.ONE
        var weight=ExactInt.ONE
        for(j in 0 until places) {
            x+=(answerAt(stream,j)-ExactInt.ONE)*weight
            weight*=m
        }
        val limit=(space/n)*n
        var rejects=0
        while(x>limit) {
            check(rejects<maxRejections) { "E_RANK_WIDE_REJECTION_BUDGET" }
            rejects++
            x=ExactInt.ONE+(x-ExactInt.ONE+
                stream.directionStep.toLong()).euclideanMod(space)
        }
        return (x-ExactInt.ONE).euclideanMod(n)+ExactInt.ONE
    }
}
