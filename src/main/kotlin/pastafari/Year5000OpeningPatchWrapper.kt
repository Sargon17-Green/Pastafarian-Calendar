package pastafari

/** Cam 31: canlyniad dewis ymgeisydd blwyddyn 5000; cedwir yr hen alwad. */
data class Year5000OpeningPatchOutcome(
    val openGateIndex: ExactInt,
    val closeGateIndex: ExactInt,
    val openGateDay: ExactInt,
    val closeGateDay: ExactInt,
    val calculationDay: ExactInt,
    val length: ExactInt,
    val legacyIncluded: Boolean,
    val correctedIncluded: Boolean,
    val correctionApplied: Boolean,
    val legacyCalls: Int,
    val correctedChecks: Int
)

/** Ffin agored y flwyddyn: open < c <= close.
 * Nid yw hwn yn gweithredu dewis ymgeiswyr na'r algorithm blwyddyn gyfan.
 */
class Year5000OpeningPatchWrapper(
    private val legacy: LegacyYear5000OpeningAdapter =
        LegacyYear5000OpeningAdapter()
) {
    fun patch(
        openGateIndex: ExactInt, closeGateIndex: ExactInt,
        openGateDay: ExactInt, closeGateDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000OpeningPatchOutcome {
        // Cadw'r graith trwy alw'r hen addasydd unwaith yn union.
        val old = legacy.acceptsCandidate(
            openGateIndex, closeGateIndex,
            openGateDay, closeGateDay, calculationDay)
        val length = closeGateDay - openGateDay
        val eligible = length >= ExactInt.of(252) &&
            length <= ExactInt.of(5778)
        val corrected = eligible &&
            openGateDay < calculationDay &&
            calculationDay <= closeGateDay
        val changed = old && !corrected
        check(changed == (eligible && calculationDay == openGateDay)) {
            "E_PATCH15_BOUNDARY_ONLY"
        }
        check(!corrected || old) { "E_PATCH15_NOT_SUBSET" }
        return Year5000OpeningPatchOutcome(
            openGateIndex, closeGateIndex, openGateDay,
            closeGateDay, calculationDay, length, old, corrected,
            changed, 1, 1)
    }
}

/** Cam 31: llwybr cynhyrchu ychwanegol, heb newid API Camau 1–30.
 * Y galwr sy'n darparu diwrnodau'r giatiau; rhaid profi'r tarddiad ar wahân.
 */
data class Year5000OpeningPatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000OpeningPatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val phase: String = "PATCH_15",
    val status: String = "PATCHED_YEAR5000_OPENING",
    val applied: Boolean = true,
    val invocationCount: Int = 1
)

class Year5000OpeningPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000OpeningPatchWrapper =
        Year5000OpeningPatchWrapper()
) {
    fun applyYear5000OpeningPatch(
        openGateIndex: ExactInt, closeGateIndex: ExactInt,
        openGateDay: ExactInt, closeGateDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000OpeningPatchSession {
        // Cyn gwneud unrhyw newidiadau i fesuryddion, gwirio'r holl ddata.
        val value = wrapper.patch(openGateIndex, closeGateIndex,
            openGateDay, closeGateDay, calculationDay)
        val context = BaseMonsterContext(calculationDay, calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status == "READY" && context.branchTrace == listOf("BOOT")) {
            "E_PATCH15_BOOT_SHAPE"
        }
        context.phase = "PATCH_15"
        context.status = "PATCHED_YEAR5000_OPENING"
        context.branchTrace.add("PATCH_15")
        context.diagnostics.add("PATCH_15_OPEN_STRICT_CLOSE_INCLUSIVE")
        val session = Year5000OpeningPatchSession(
            context, value, context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch15.legacy.calls")
        metrics.bump("patch15.corrected.checks")
        metrics.bump("patch15.applied")
        return session
    }

    fun rejectReplay(session: Year5000OpeningPatchSession) {
        if (session.context.phase != "BOOT" ||
            session.context.status != "NEW") {
            throw MonsterValidationException("E_PATCH15_CONTEXT_NOT_READY")
        }
        throw MonsterValidationException("E_PATCH15_REPLAY_NOT_SUPPORTED")
    }
}
