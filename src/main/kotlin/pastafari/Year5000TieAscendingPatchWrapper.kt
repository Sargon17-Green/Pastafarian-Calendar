package pastafari

/** Cam 41: cadw'r drefn hanesyddol anghywir ac ychwanegu'r cywiriad yn unig. */
data class Year5000TieAscendingPatchOutcome(
    val legacyOrder: List<Year5000TieCandidate>,
    val correctedOrder: List<Year5000TieCandidate>,
    val correctionApplied: Boolean,
    val legacyCalls: Int = 1,
    val correctedChecks: Int = 1
) {
    val candidateCount: Int get() = correctedOrder.size
}

/** Cymhwysedd yr hen addasydd sy'n penderfynu pwy sy'n ymgeisydd.
 * Dim math na rhestr oracl normadol yn y gweithrediad cynhyrchu.
 */
class Year5000TieAscendingPatchWrapper(
    private val legacy: LegacyYear5000TieBreakAdapter =
        LegacyYear5000TieBreakAdapter()
) {
    fun patch(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>
    ): Year5000TieAscendingPatchOutcome {
        // Un galwad union i'r llwybr arbrofol; cadw'r graith.
        val historical = legacy.order(calculationDay,candidates)
        val corrected = historical.sortedWith(
            compareBy<Year5000TieCandidate> { it.length }
                .thenBy { it.openGateDay }
        )
        check(corrected.size == historical.size &&
            corrected.toSet() == historical.toSet()) {
            "E_PATCH20_CANDIDATE_LOSS"
        }
        check(corrected.zipWithNext().all { (x,y) ->
            x.length < y.length ||
                (x.length == y.length && x.openGateDay <= y.openGateDay)
        }) { "E_PATCH20_ORDERING" }
        val changed = corrected != historical
        check(!changed || historical.indices.any { i ->
            historical[i] != corrected[i]
        }) { "E_PATCH20_FALSE_CORRECTION" }
        return Year5000TieAscendingPatchOutcome(
            historical.toList(),corrected.toList(),changed)
    }

    fun chooseAtRank(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000TieCandidate {
        val outcome = patch(calculationDay,candidates)
        require(oneBasedRank >= ExactInt.ONE &&
            oneBasedRank <= ExactInt.of(outcome.candidateCount.toLong())) {
            "E_PATCH20_RANK_RANGE"
        }
        return outcome.correctedOrder[(oneBasedRank-ExactInt.ONE).toIntExact()]
    }
}

data class Year5000TieAscendingPatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000TieAscendingPatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val status: String = "PATCHED_YEAR5000_TIE_ASCENDING",
    val phase: String = "PATCH_20",
    val applied: Boolean = true,
    val invocationCount: Int = 1
)

/** Llwybr ategol ar wahân, heb newid dosbarthwr na bootstrap Camau 1–40. */
class Year5000TieAscendingPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000TieAscendingPatchWrapper =
        Year5000TieAscendingPatchWrapper()
) {
    fun apply(
        calculationDay: ExactInt,
        candidates: List<Year5000TieCandidate>
    ): Year5000TieAscendingPatchSession {
        // Dilysu yn llwyr cyn cynyddu cyfrif neu greu cyflwr gweithredol.
        val result = wrapper.patch(calculationDay,candidates)
        val context = BaseMonsterContext(calculationDay,calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status == "READY" &&
            context.branchTrace == listOf("BOOT")) {
            "E_PATCH20_BOOT_SHAPE"
        }
        context.phase = "PATCH_20"
        context.status = "PATCHED_YEAR5000_TIE_ASCENDING"
        context.branchTrace.add("PATCH_20")
        context.diagnostics.add("PATCH_20_STABLE_ASCENDING_TIE_BREAK")
        val session = Year5000TieAscendingPatchSession(
            context,result,context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch20.legacy.calls")
        metrics.bump("patch20.corrected.checks")
        metrics.bump("patch20.applied")
        return session
    }

    fun rejectReplay(session: Year5000TieAscendingPatchSession) {
        if (session.context.status != "NEW" ||
            session.context.phase != "BOOT") {
            throw MonsterValidationException("E_PATCH20_CONTEXT_NOT_READY")
        }
        throw MonsterValidationException("E_PATCH20_REPLAY_NOT_SUPPORTED")
    }
}
