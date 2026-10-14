package pastafari

/** Stage 28 experimental historical direction mismatch.
 * This is an isolated hypothesis, not a claim about existing production defects.
 */
class LegacyNegativeGateDirectionAdapter {
    fun negativeGateFromPositiveGap(
        magnitude: ExactInt,
        previousNegativeGate: ExactInt,
        positiveGap: Int
    ): ExactInt {
        require(magnitude >= ExactInt.ONE)
        require(positiveGap in 42..963)
        return previousNegativeGate - ExactInt.of(positiveGap.toLong())
    }
}
