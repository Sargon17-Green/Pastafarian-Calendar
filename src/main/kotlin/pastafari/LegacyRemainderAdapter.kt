package pastafari

/**
 * Craith fwriadol Cam 2. Nid yw'r dull hwn yn defnyddio SAVE:
 * mae lluosrifau'r modwlws yn dychwelyd sero, nid y modwlws.
 * Cedwir y gwall hwn yn weithredol hyd at Gam 3.
 */
class LegacyRemainderAdapter {
    private val oldModulus: ExactInt = ExactInt.parse("170141183460469231731687303715884105727")

    fun oldRemainder(value: ExactInt): ExactInt = value.euclideanMod(oldModulus)
}
