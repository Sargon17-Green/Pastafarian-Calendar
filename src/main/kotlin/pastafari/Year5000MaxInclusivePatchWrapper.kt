package pastafari

/** Cam 35: adfer terfyn cynhwysol 5778; cedwir craith Cam 34 heb ei newid. */
data class Year5000MaxInclusivePatchOutcome(
    val gateGaps: ExactInt,
    val yearDays: ExactInt,
    val legacyAccepted: Boolean,
    val correctedAccepted: Boolean,
    val correctionApplied: Boolean,
    val legacyCalls: Int = 1,
    val correctedChecks: Int = 1
)

/** Prawf arbrofol o gymhwysedd, nid newid i ddetholiad llawn blwyddyn 5000. */
class Year5000MaxInclusivePatchWrapper(
    private val historical: LegacyYear5000MaxExclusiveAdapter =
        LegacyYear5000MaxExclusiveAdapter()
) {
    fun patch(
        openIndex: ExactInt, closeIndex: ExactInt,
        openDay: ExactInt, closeDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000MaxInclusivePatchOutcome {
        val legacy = historical.acceptsCandidate(
            openIndex, closeIndex, openDay, closeDay, calculationDay)
        val gaps = closeIndex - openIndex
        val days = closeDay - openDay
        val validDate = openDay < calculationDay && calculationDay <= closeDay
        val corrected = gaps >= ExactInt.of(6) &&
            days >= ExactInt.of(252) && days <= ExactInt.of(5778) &&
            validDate
        val changed = corrected && !legacy
        check(!legacy || corrected) { "E_PATCH17_LEGACY_NOT_SUBSET" }
        check(changed == (
            gaps >= ExactInt.of(6) &&
            days == ExactInt.of(5778) && validDate
        )) { "E_PATCH17_ONLY_MAX_BOUNDARY" }
        return Year5000MaxInclusivePatchOutcome(
            gaps, days, legacy, corrected, changed)
    }
}

data class Year5000MaxInclusivePatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000MaxInclusivePatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true
)

/** Haen ategol: dim newidiadau i'r manager bootstrap hanesyddol. */
class Year5000MaxInclusivePatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000MaxInclusivePatchWrapper =
        Year5000MaxInclusivePatchWrapper()
) {
    fun apply(
        openIndex: ExactInt, closeIndex: ExactInt,
        openDay: ExactInt, closeDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000MaxInclusivePatchSession {
        // Gwirio cyn cyffwrdd â chyflwr neu fesuryddion.
        val out = wrapper.patch(
            openIndex, closeIndex, openDay, closeDay, calculationDay)
        val context = BaseMonsterContext(calculationDay, calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status == "READY" &&
            context.branchTrace == listOf("BOOT")) { "E_PATCH17_BOOT" }
        context.phase = "PATCH_17"
        context.status = "PATCHED_YEAR5000_MAX_INCLUSIVE"
        context.branchTrace.add("PATCH_17")
        context.diagnostics.add("PATCH_17_MAX_5778_INCLUSIVE")
        val session = Year5000MaxInclusivePatchSession(
            context, out, context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch17.historical.calls")
        metrics.bump("patch17.corrected.checks")
        metrics.bump("patch17.applied")
        return session
    }

    fun rejectReplay(session: Year5000MaxInclusivePatchSession) {
        if (session.context.status != "NEW" ||
            session.context.phase != "BOOT"
        ) throw MonsterValidationException("E_PATCH17_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH17_REPLAY_NOT_SUPPORTED")
    }
}
