package pastafari

/**
 * Cam 16 — DISCOVERY 08: mae'r unranker ei hun yn gywir ar 0..719.
 * Mae'r caller etifeddol yn trosglwyddo 1..720 yn uniongyrchol.
 * Dim PATCH 08 na chyfrifiad diferion gweledig yn y cam hwn.
 */
data class LegacyPermutationRead(
    val dropValue: ExactInt,
    val oneBased: Int,
    val passedRank0: Int,
    val legacyOrder: List<Int>?,
    val undefined: Boolean,
    val errorId: String?,
    val legacyCalls: Int
)

class LegacyPermutationOrderAdapter {
    private fun factorial(n: Int): Int {
        require(n in 0..6) { "E_DISCOVERY08_FACTORIAL_RANGE" }
        var result = 1
        for (k in 2..n) result *= k
        return result
    }

    /** Helper zero-based cywir: 0 -> identity, 719 -> reverse. */
    fun oldPermutationUnrank0(rank0: Int): List<Int> {
        require(rank0 in 0..719) { "E_DISCOVERY08_RANK0_RANGE" }
        var rest = rank0
        val remaining = mutableListOf(1,2,3,4,5,6)
        val output = ArrayList<Int>(6)
        for (length in 6 downTo 1) {
            val block = factorial(length - 1)
            val index = rest / block
            rest %= block
            output.add(remaining.removeAt(index))
        }
        return output
    }

    /** Y nam: mae'r ordinal 1-based yn mynd i'r helper fel rank0. */
    fun legacyPermutationOrderFromDropWrong(dropValue: ExactInt): LegacyPermutationRead {
        val oneBased = ((dropValue - ExactInt.ONE)
            .euclideanMod(ExactInt.of(720L)) + ExactInt.ONE).toIntExact()
        var wrong: List<Int>? = null
        var errorId: String? = null
        try {
            // Rhaid galw'r helper hefyd ar ordinal 720 a chofnodi'r gwrthodiad.
            wrong = oldPermutationUnrank0(oneBased)
        } catch (e: IllegalArgumentException) {
            if (oneBased != 720 || e.message != "E_DISCOVERY08_RANK0_RANGE") throw e
            errorId = "E_DISCOVERY08_RANK0_RANGE"
        }
        return LegacyPermutationRead(
            dropValue, oneBased, oneBased, wrong, errorId != null, errorId, 1
        )
    }
}
