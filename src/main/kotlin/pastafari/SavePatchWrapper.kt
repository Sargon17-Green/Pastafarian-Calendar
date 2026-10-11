package pastafari

/**
 * Patch 01: addasu allbwn y gweddill etifeddol, nid disodli'r craith.
 * Rhaid i'r galwr gyfrifo oldRemainder yn gyntaf, union unwaith.
 */
class SavePatchWrapper {
    private val modulus = ExactInt.parse("170141183460469231731687303715884105727")

    fun savePatch(legacyRemainder: ExactInt): ExactInt {
        require(legacyRemainder >= ExactInt.ZERO && legacyRemainder < modulus) {
            "E_PATCH01_LEGACY_RANGE"
        }
        return if (legacyRemainder.isZero()) modulus else legacyRemainder
    }
}
