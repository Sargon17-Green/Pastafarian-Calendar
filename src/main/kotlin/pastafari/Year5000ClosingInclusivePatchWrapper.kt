package pastafari

/** Cam 39: adfer diwrnod cau cynhwysol; cedwir craith Cam 38 heb ei newid. */
data class Year5000ClosingInclusivePatchOutcome(
    val gateGaps: ExactInt,
    val yearDays: ExactInt,
    val legacyAccepted: Boolean,
    val correctedAccepted: Boolean,
    val correctionApplied: Boolean,
    val legacyCalls: Int = 1,
    val correctedChecks: Int = 1
)

/** Prawf arbrofol o gymhwysedd, nid newid i ddetholiad llawn blwyddyn 5000. */
class Year5000ClosingInclusivePatchWrapper(
    private val historical: LegacyYear5000ClosingExclusiveAdapter =
        LegacyYear5000ClosingExclusiveAdapter()
) {
    fun patch(
        openIndex: ExactInt, closeIndex: ExactInt,
        openDay: ExactInt, closeDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000ClosingInclusivePatchOutcome {
        val legacy = historical.acceptsCandidate(
            openIndex, closeIndex, openDay, closeDay, calculationDay)
        val gaps = closeIndex - openIndex
        val days = closeDay - openDay
        val validDate = openDay < calculationDay && calculationDay <= closeDay
        val corrected = gaps >= ExactInt.of(6) &&
            days >= ExactInt.of(252) && days <= ExactInt.of(5778) &&
            validDate
        val changed = corrected && !legacy
        check(!legacy || corrected) { "E_PATCH19_LEGACY_NOT_SUBSET" }
        check(changed == (
            gaps >= ExactInt.of(6) &&
            days >= ExactInt.of(252) && days <= ExactInt.of(5778) &&
            validDate && calculationDay == closeDay
        )) { "E_PATCH19_ONLY_CLOSE_BOUNDARY" }
        return Year5000ClosingInclusivePatchOutcome(
            gaps, days, legacy, corrected, changed)
    }
}

data class Year5000ClosingInclusivePatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000ClosingInclusivePatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true
)

/** Haen ategol: dim newidiadau i'r manager bootstrap hanesyddol. */
class Year5000ClosingInclusivePatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000ClosingInclusivePatchWrapper =
        Year5000ClosingInclusivePatchWrapper()
) {
    fun apply(
        openIndex: ExactInt, closeIndex: ExactInt,
        openDay: ExactInt, closeDay: ExactInt,
        calculationDay: ExactInt
    ): Year5000ClosingInclusivePatchSession {
        // Gwirio cyn cyffwrdd â chyflwr neu fesuryddion.
        val out = wrapper.patch(
            openIndex, closeIndex, openDay, closeDay, calculationDay)
        val context = BaseMonsterContext(calculationDay, calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status == "READY" &&
            context.branchTrace == listOf("BOOT")) { "E_PATCH19_BOOT" }
        context.phase = "PATCH_19"
        context.status = "PATCHED_YEAR5000_CLOSE_INCLUSIVE"
        context.branchTrace.add("PATCH_19")
        context.diagnostics.add("PATCH_19_CLOSE_INCLUSIVE")
        val session = Year5000ClosingInclusivePatchSession(
            context, out, context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch19.historical.calls")
        metrics.bump("patch19.corrected.checks")
        metrics.bump("patch19.applied")
        return session
    }

    fun rejectReplay(session: Year5000ClosingInclusivePatchSession) {
        if (session.context.status != "NEW" ||
            session.context.phase != "BOOT"
        ) throw MonsterValidationException("E_PATCH19_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH19_REPLAY_NOT_SUPPORTED")
    }
}
