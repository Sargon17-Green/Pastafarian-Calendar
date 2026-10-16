package pastafari

/** Cam 33: cywiro'r trothwy saith bwlch i chwech heb ddileu'r graith. */
data class Year5000MinSixPatchOutcome(
    val gateGaps: ExactInt,
    val yearDays: ExactInt,
    val legacyAccepted: Boolean,
    val correctedAccepted: Boolean,
    val correctionApplied: Boolean,
    val legacyCalls: Int = 1,
    val correctedChecks: Int = 1
)

/** Mae'r hen addasydd yn ddamcaniaeth arbrofol, nid nam cynhyrchu profedig. */
class Year5000MinSixPatchWrapper(
    private val historical: LegacyYear5000MinSevenAdapter =
        LegacyYear5000MinSevenAdapter()
) {
    fun patch(openIndex:ExactInt, closeIndex:ExactInt,
              openDay:ExactInt, closeDay:ExactInt,
              calculationDay:ExactInt):Year5000MinSixPatchOutcome {
        // Mae'r hen lwybr yn aros yn weithredol.
        val old=historical.acceptsCandidate(
            openIndex,closeIndex,openDay,closeDay,calculationDay)
        val gaps=closeIndex-openIndex
        val days=closeDay-openDay
        val validLength=days>=ExactInt.of(252) &&
            days<=ExactInt.of(5778)
        val validDate=openDay<calculationDay && calculationDay<=closeDay
        val correct=gaps>=ExactInt.of(6) && validLength && validDate
        val changed=correct && !old
        check(!old || correct){"E_PATCH16_OLD_NOT_SUBSET"}
        check(changed==(gaps==ExactInt.of(6) &&
            validLength && validDate)){"E_PATCH16_ONLY_SIX_GAP_FIX"}
        return Year5000MinSixPatchOutcome(
            gaps,days,old,correct,changed)
    }
}

/** Haen ychwanegol, heb newid MonsterBootstrap o gamau blaenorol. */
data class Year5000MinSixPatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000MinSixPatchOutcome,
    val branchTrace: List<String>,
    val diagnostics: List<String>,
    val applied: Boolean = true
)
class Year5000MinSixPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper:Year5000MinSixPatchWrapper =
        Year5000MinSixPatchWrapper()
) {
    fun apply(openIndex:ExactInt,closeIndex:ExactInt,
              openDay:ExactInt,closeDay:ExactInt,
              calculationDay:ExactInt):Year5000MinSixPatchSession {
        // Pob dilysiad cyn ymrwymo na chyfrif.
        val out=wrapper.patch(openIndex,closeIndex,
            openDay,closeDay,calculationDay)
        val context=BaseMonsterContext(calculationDay,calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" &&
            context.branchTrace==listOf("BOOT")){"E_PATCH16_BOOT"}
        context.phase="PATCH_16"
        context.status="PATCHED_YEAR5000_MIN_SIX"
        context.branchTrace.add("PATCH_16")
        context.diagnostics.add("PATCH_16_MIN_SIX_GATE_GAPS")
        val session=Year5000MinSixPatchSession(
            context,out,context.branchTrace.toList(),
            context.diagnostics.toList())
        metrics.bump("patch16.historical.calls")
        metrics.bump("patch16.corrected.checks")
        metrics.bump("patch16.applied")
        return session
    }
    fun rejectReplay(session:Year5000MinSixPatchSession) {
        if(session.context.status!="NEW" ||
           session.context.phase!="BOOT")
            throw MonsterValidationException("E_PATCH16_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH16_REPLAY_NOT_SUPPORTED")
    }
}
