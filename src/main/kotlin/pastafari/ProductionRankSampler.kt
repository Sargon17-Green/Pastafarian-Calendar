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
            // With a unit-step stream, jump exactly to the first accepted answer.
            // A reverse scan reaches limit; a forward scan wraps to 1.
            // This avoids potentially astronomical rejection loops.
            if(x>limit) x=if(stream.directionStep==-1) limit else ExactInt.ONE
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
        // The same exact jump applies to the widened answer ring.
        if(x>limit) x=if(stream.directionStep==-1) limit else ExactInt.ONE
        return (x-ExactInt.ONE).euclideanMod(n)+ExactInt.ONE
    }
}
