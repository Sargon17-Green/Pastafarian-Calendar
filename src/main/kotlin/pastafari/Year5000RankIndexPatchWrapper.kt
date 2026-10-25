package pastafari

/**
 * Cam 55 — PATCH 27: trosi rank1 yn index0 trwy dynnu un.
 *
 * Mae'r graith arbrofol Cam 54 yn cael ei galw a'i chadw unwaith,
 * heb newid yr addasydd hanesyddol. Mae'r oracl normadol yn
 * aros o dan src/test yn unig. Nid dyma adeiladwr blwyddyn gyfan.
 */
data class Year5000RankIndexPatchOutcome(
    val historical: LegacyYear5000RankAsIndexRead,
    val correctedIndex0: Int,
    val correctedChosen: Year5000TieCandidate,
    val correctionApplied: Boolean,
    val historicalCalls: Int = 1,
    val correctedChecks: Int = 1
)

class Year5000RankIndexPatchWrapper(
    private val historicalAdapter: LegacyYear5000RankAsIndexAdapter =
        LegacyYear5000RankAsIndexAdapter()
) {
    fun patch(
        calculationDay: ExactInt,
        orderedCandidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000RankIndexPatchOutcome {
        // Mae'r hen lwybr yn dilysu'r rhestr cyn unrhyw gywiriad.
        val scar = historicalAdapter.oldChoose(
            calculationDay, orderedCandidates, oneBasedRank
        )
        val index0 = (oneBasedRank - ExactInt.ONE).toIntExact()
        check(index0 in orderedCandidates.indices &&
            scar.count == orderedCandidates.size &&
            scar.rank1 == oneBasedRank && scar.listReads == 1) {
            "E_PATCH27_CORRECTED_INDEX_SHAPE"
        }
        val chosen = orderedCandidates[index0]
        check(chosen == orderedCandidates[index0]) {
            "E_PATCH27_CORRECTED_SELECTION_SHAPE"
        }
        return Year5000RankIndexPatchOutcome(
            scar,index0,chosen,chosen != scar.wrongChosen
        )
    }
}

data class Year5000RankIndexPatchSession(
    val context: BaseMonsterContext,
    val outcome: Year5000RankIndexPatchOutcome,
    val trace: List<String>,
    val diagnostics: List<String>
)

/** Galwadau dilys yn unig sy'n effeithio ar fesuryddion neu gyd-destun. */
class Year5000RankIndexPatchManager(
    val bootstrap: MonsterBootstrapManager = MonsterBootstrapManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    private val wrapper: Year5000RankIndexPatchWrapper =
        Year5000RankIndexPatchWrapper()
) {
    fun apply(
        calculationDay: ExactInt,
        orderedCandidates: List<Year5000TieCandidate>,
        oneBasedRank: ExactInt
    ): Year5000RankIndexPatchSession {
        // Dilysu'r mewnbwn cyn creu cyd-destun gweithredol.
        val outcome = wrapper.patch(calculationDay,orderedCandidates,oneBasedRank)
        val context = BaseMonsterContext(calculationDay,calculationDay)
        bootstrap.dispatcher.dispatch(context)
        check(context.status=="READY" && context.branchTrace==listOf("BOOT")) {
            "E_PATCH27_BOOT"
        }
        context.phase="PATCH_27"
        context.status="PATCHED_YEAR5000_RANK_INDEX"
        context.branchTrace.add("PATCH_27")
        context.diagnostics.add("PATCH_27_SUBTRACT_ONE_FROM_RANK1")
        metrics.bump("patch27.historical.calls")
        metrics.bump("patch27.corrected.checks")
        metrics.bump("patch27.applied")
        return Year5000RankIndexPatchSession(
            context,outcome,context.branchTrace.toList(),
            context.diagnostics.toList()
        )
    }

    fun rejectReplay(session: Year5000RankIndexPatchSession): Nothing {
        if (session.context.phase!="BOOT" || session.context.status!="NEW")
            throw MonsterValidationException("E_PATCH27_CONTEXT_NOT_READY")
        throw MonsterValidationException("E_PATCH27_REPLAY_NOT_SUPPORTED")
    }
}
