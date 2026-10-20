package pastafari

/** Cam 37: adfer terfyn cynhwysol 252; cedwir craith Cam 36 heb ei newid. */
data class Year5000MinInclusivePatchOutcome(
    val gateGaps: ExactInt,
    val yearDays: ExactInt,
    val legacyAccepted: Boolean,
    val correctedAccepted: Boolean,
    val correctionApplied: Boolean,
    val legacyCalls: Int = 1,
    val correctedChecks: Int = 1
)

/** Prawf arbrofol o gymhwysedd, nid newid i ddetholiad llawn blwyddyn 5000. */
class Year5000MinInclusivePatchWrapper(
    private val historical: LegacyYear5000MinExclusiveAdapter =
        LegacyYear5000MinExclusiveAdapter()
) {
    fun patch(
        openIndex: ExactInt, closeIndex: ExactInt,
        openDay: ExactInt, closeDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000MinInclusivePatchOutcome {
        val legacy = historical.acceptsCandidate(
            openIndex, closeIndex, openDay, closeDay, calculationDay)
        val gaps = closeIndex - openIndex
        val days = closeDay - openDay
        val validDate = openDay < calculationDay && calculationDay <= closeDay
        val corrected = gaps >= ExactInt.of(6) &&
            days >= ExactInt.of(252) && days <= ExactInt.of(5778) &&
            validDate
        val changed = corrected && !legacy
        check(!legacy || corrected) { "E_PATCH18_LEGACY_NOT_SUBSET" }
        check(changed == (
            gaps >= ExactInt.of(6) &&
            days == ExactInt.of(252) && validDate
        )) { "E_PATCH18_ONLY_MIN_BOUNDARY" }
        return Year5000MinInclusivePatchOutcome(
            gaps, days, legacy, corrected, changed)
    }
}

data class Year5000MinInclusivePatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000MinInclusivePatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true
)

/** Haen ategol: dim newidiadau i'r manager bootstrap hanesyddol. */
class Year5000MinInclusivePatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000MinInclusivePatchWrapper =
        Year5000MinInclusivePatchWrapper()
) {
    fun apply(
        openIndex: ExactInt, closeIndex: ExactInt,
        openDay: ExactInt, closeDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000MinInclusivePatchSession {
        // Gwirio cyn cyffwrdd â chyflwr neu fesuryddion.
        val out = wrapper.patch(
            openIndex, closeIndex, openDay, closeDay, calculationDay)
        val context = BaseMonsterContext(calculationDay, calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status == "READY" &&
            context.branchTrace == listOf("BOOT")) { "E_PATCH18_BOOT" }
        context.phase = "PATCH_18"
        context.status = "PATCHED_YEAR5000_MIN_INCLUSIVE"
        context.branchTrace.add("PATCH_18")
        context.diagnostics.add("PATCH_18_MIN_252_INCLUSIVE")
        val session = Year5000MinInclusivePatchSession(
            context, out, context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch18.historical.calls")
        metrics.bump("patch18.corrected.checks")
        metrics.bump("patch18.applied")
        return session
    }

    fun rejectReplay(session: Year5000MinInclusivePatchSession) {
        if (session.context.status != "NEW" ||
            session.context.phase != "BOOT"
        ) throw MonsterValidationException("E_PATCH18_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH18_REPLAY_NOT_SUPPORTED")
    }
}
