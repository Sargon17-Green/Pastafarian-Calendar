package pastafari

data class BaseMonsterContext(
    val calculationDay: ExactInt,
    val targetDay: ExactInt,
    var phase: String = "BOOT",
    var status: String = "NEW",
    val branchTrace: MutableList<String> = mutableListOf(),
    val diagnostics: MutableList<String> = mutableListOf(),
    var discovery01Input: ExactInt? = null,
    var discovery01Output: ExactInt? = null,
    var patch01Input: ExactInt? = null,
    var patch01LegacyOutput: ExactInt? = null,
    var patch01Output: ExactInt? = null,
    var discovery02Input: ExactInt? = null,
    var discovery02Output: ExactInt? = null,
    var patch02Input: ExactInt? = null,
    var patch02LegacyOutput: ExactInt? = null,
    var patch02Output: ExactInt? = null,
    var discovery03CalculationDay: ExactInt? = null,
    var discovery03TargetDay: ExactInt? = null,
    var discovery03Output: ExactInt? = null,
    var patch03CalculationDay: ExactInt? = null,
    var patch03TargetDay: ExactInt? = null,
    var patch03LegacyOutput: ExactInt? = null,
    var patch03ChronologicalBase: ExactInt? = null,
    var patch03SelectedBase: ExactInt? = null,
    var patch03ReplacementApplied: Boolean? = null,
    var patch03Output: ExactInt? = null,
    var discovery04LegacyStoneRows: List<MutableStoneRow>? = null,
    var discovery04BuiltRows: Int = 0,
    var patch04StoneRows: List<MutableStoneRow>? = null,
    var patch04LegacyGarbageRows: List<MutableStoneRow>? = null,
    var patch04BuiltRows: Int = 0,
    var patch04LegacyCalls: Int = 0,
    var discovery05PatchedStoneRows: List<MutableStoneRow>? = null,
    var discovery05Patch04LegacyCalls: Int = 0,
    var discovery05BackwardStorage: List<ExactInt>? = null,
    var discovery05HiddenCount: Int = 0,
    var discovery05RequestedK: Int? = null,
    var discovery05Actual: ExactInt? = null,
    var patch05PatchedStoneRows: List<MutableStoneRow>? = null,
    var patch05BackwardStorage: List<ExactInt>? = null,
    var patch05StoneLegacyCalls: Int = 0,
    var patch05HiddenCount: Int = 0,
    var patch05RequestedK: Int? = null,
    var patch05PhysicalSlot: Int? = null,
    var patch05LegacyDirectValue: ExactInt? = null,
    var patch05CorrectedValue: ExactInt? = null,
    var patch05Applied: Boolean = false,
    var patch05InvocationCount: Int = 0,
    var discovery06PriorI: Int? = null,
    var discovery06PriorBack: Int? = null,
    var discovery06PriorSlot: Int? = null,
    var discovery06PriorValue: ExactInt? = null,
    var discovery06VisibleStore: List<ExactInt?>? = null,
    var discovery06HiddenStorage: List<ExactInt>? = null,
    var discovery06Patch05HiddenOne: ExactInt? = null,
    var discovery06ErrorId: String? = null,
    var discovery06InvocationCount: Int = 0,
    var patch06PriorI: Int? = null,
    var patch06PriorBack: Int? = null,
    var patch06Slot: Int? = null,
    var patch06HiddenK: Int? = null,
    var patch06Source: String? = null,
    var patch06LegacyPriorCalled: Boolean? = null,
    var patch06Output: ExactInt? = null,
    var patch06VisibleStore: List<ExactInt?>? = null,
    var patch06HiddenStorage: List<ExactInt>? = null,
    var patch06Patch05HiddenOne: ExactInt? = null,
    var patch06StoneLegacyCalls: Int = 0,
    var patch06Applied: Boolean = false,
    var patch06InvocationCount: Int = 0,
    var discovery07RequestedGrind: Int? = null,
    var discovery07DirectIndex: Int? = null,
    var discovery07LegacyRow: VisibleGrindRow? = null,
    var discovery07Undefined: Boolean? = null,
    var discovery07PhysicalRows: List<VisibleGrindRow>? = null,
    var discovery07InvocationCount: Int = 0,
    var patch07RequestedGrind: Int? = null,
    var patch07LegacyDirectIndex: Int? = null,
    var patch07LegacyRow: VisibleGrindRow? = null,
    var patch07LegacyUndefined: Boolean? = null,
    var patch07PhysicalRows: List<VisibleGrindRow>? = null,
    var patch07SentinelRows: List<VisibleGrindRow?>? = null,
    var patch07TranslatedIndex: Int? = null,
    var patch07CorrectedRow: VisibleGrindRow? = null,
    var patch07Applied: Boolean = false,
    var patch07InvocationCount: Int = 0,
    var discovery08DropValue: ExactInt? = null,
    var discovery08OneBased: Int? = null,
    var discovery08PassedRank0: Int? = null,
    var discovery08LegacyOrder: List<Int>? = null,
    var discovery08Undefined: Boolean? = null,
    var discovery08ErrorId: String? = null,
    var discovery08LegacyCalls: Int = 0,
    var discovery08InvocationCount: Int = 0,
    var patch08DropValue: ExactInt? = null,
    var patch08OneBased: Int? = null,
    var patch08CorrectedRank0: Int? = null,
    var patch08LegacyPassedRank0: Int? = null,
    var patch08LegacyOrder: List<Int>? = null,
    var patch08LegacyUndefined: Boolean? = null,
    var patch08LegacyErrorId: String? = null,
    var patch08CorrectedOrder: List<Int>? = null,
    var patch08LegacyCalls: Int = 0,
    var patch08CorrectedCalls: Int = 0,
    var patch08Applied: Boolean = false,
    var patch08InvocationCount: Int = 0
)

class MonsterValidationException(val machineCode: String) : RuntimeException(machineCode)

class BaseValidationManager {
    fun requireBootstrapContext(context: BaseMonsterContext) {
        if (context.phase.isEmpty()) throw MonsterValidationException("E_BOOT_PHASE")
        if (context.status.isEmpty()) throw MonsterValidationException("E_BOOT_STATUS")
    }
}

class BaseMetricsManager {
    private val counters = linkedMapOf<String, Long>()

    fun bump(key: String) {
        counters[key] = (counters[key] ?: 0L) + 1L
    }

    fun snapshot(): Map<String, Long> = counters.toMap()
}

class BaseErrorWrapper {
    fun wrap(code: String, cause: Throwable): MonsterValidationException {
        val suffix = cause::class.simpleName ?: "Throwable"
        return MonsterValidationException("${code}_${suffix}")
    }
}

fun interface BasePhaseHandler {
    fun handle(context: BaseMonsterContext)
}

class BaseMonsterDispatcher(
    private val handlers: MutableMap<String, BasePhaseHandler> = linkedMapOf()
) {
    fun register(phase: String, handler: BasePhaseHandler) {
        handlers[phase] = handler
    }

    fun dispatch(context: BaseMonsterContext) {
        val handler = handlers[context.phase] ?: throw MonsterValidationException("E_BOOT_HANDLER")
        handler.handle(context)
    }
}

class MonsterBootstrapManager(
    val dispatcher: BaseMonsterDispatcher = BaseMonsterDispatcher(),
    val validation: BaseValidationManager = BaseValidationManager(),
    val metrics: BaseMetricsManager = BaseMetricsManager(),
    val errors: BaseErrorWrapper = BaseErrorWrapper(),
    val legacyRemainderAdapter: LegacyRemainderAdapter = LegacyRemainderAdapter(),
    val savePatchWrapper: SavePatchWrapper = SavePatchWrapper(),
    val legacyDayTagAdapter: LegacyDayTagAdapter = LegacyDayTagAdapter(),
    val dayTagPatchWrapper: DayTagPatchWrapper = DayTagPatchWrapper(),
    val legacyDistanceAdapter: LegacyDistanceAdapter = LegacyDistanceAdapter(),
    val distancePatchWrapper: DistancePatchWrapper = DistancePatchWrapper(),
    val legacyStoneBuilder: LegacyStoneBuilder = LegacyStoneBuilder(),
    val stonePatchWrapper: StonePatchWrapper = StonePatchWrapper(),
    val legacyHiddenDropAdapter: LegacyHiddenDropAdapter = LegacyHiddenDropAdapter(),
    val hiddenNearnessPatchWrapper: HiddenNearnessPatchWrapper = HiddenNearnessPatchWrapper(legacyHiddenDropAdapter),
    val legacyPriorAdapter: LegacyPriorAdapter = LegacyPriorAdapter(),
    val priorPatchWrapper: PriorPatchWrapper = PriorPatchWrapper(legacyPriorAdapter, hiddenNearnessPatchWrapper),
    val legacyGrindTableAdapter: LegacyGrindTableAdapter = LegacyGrindTableAdapter(),
    val grindPatchWrapper: GrindPatchWrapper = GrindPatchWrapper(legacyGrindTableAdapter),
    val legacyPermutationOrderAdapter: LegacyPermutationOrderAdapter = LegacyPermutationOrderAdapter(),
    val permutationPatchWrapper: PermutationPatchWrapper =
        PermutationPatchWrapper(legacyPermutationOrderAdapter)
) {
    init {
        dispatcher.register("BOOT") { context ->
            validation.requireBootstrapContext(context)
            context.branchTrace.add("BOOT")
            context.status = "READY"
            metrics.bump("bootstrap.ready")
        }
        dispatcher.register("DISCOVERY_01") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY01_CONTEXT_NOT_READY")
            val input = context.discovery01Input
                ?: throw MonsterValidationException("E_DISCOVERY01_NO_INPUT")
            // Galw'r graith go iawn; dim galwad at y cyfeirnod normadol.
            val legacy = legacyRemainderAdapter.oldRemainder(input)
            context.discovery01Output = legacy
            context.branchTrace.add("DISCOVERY_01")
            context.diagnostics.add("DISCOVERY_01_LEGACY_REMAINDER")
            context.status = "LEGACY_REMAINDER_OBSERVED"
            metrics.bump("discovery01.legacy")
        }
        dispatcher.register("DISCOVERY_02") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY02_CONTEXT_NOT_READY")
            val input = context.discovery02Input
                ?: throw MonsterValidationException("E_DISCOVERY02_NO_INPUT")
            // Galw'r hen dag yn union; rhaid cadw'r anghysondeb yn weithredol.
            val legacy = legacyDayTagAdapter.oldDayTag(input)
            context.discovery02Output = legacy
            context.branchTrace.add("DISCOVERY_02")
            context.diagnostics.add("DISCOVERY_02_LEGACY_DAY_TAG")
            context.status = "LEGACY_DAY_TAG_OBSERVED"
            metrics.bump("discovery02.legacy")
        }
        dispatcher.register("DISCOVERY_03") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY03_CONTEXT_NOT_READY")
            val calculation = context.discovery03CalculationDay
                ?: throw MonsterValidationException("E_DISCOVERY03_NO_CALCULATION_DAY")
            val target = context.discovery03TargetDay
                ?: throw MonsterValidationException("E_DISCOVERY03_NO_TARGET_DAY")
            if (calculation != context.calculationDay || target != context.targetDay) {
                throw MonsterValidationException("E_DISCOVERY03_CONTEXT_MISMATCH")
            }
            // Galw'r graith mewn cynhyrchu. Dim oracl, dim PATCH 03.
            val legacy = legacyDistanceAdapter.oldDistance(calculation, target)
            context.discovery03Output = legacy
            context.branchTrace.add("DISCOVERY_03")
            context.diagnostics.add("DISCOVERY_03_LEGACY_TAG_DISTANCE")
            context.status = "LEGACY_DISTANCE_OBSERVED"
            metrics.bump("discovery03.legacy")
        }
        dispatcher.register("DISCOVERY_04") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY04_CONTEXT_NOT_READY")
            // Galw'r adeiladwr diffygiol mewn cynhyrchu; dim oracl yma.
            val rows = legacyStoneBuilder.buildLegacyRows()
            check(rows.size == 47) { "E_DISCOVERY04_BUILDER_ROWS" }
            // Ymrwymo gyda'i gilydd ar ôl llwyddiant pob un o'r 46 rhes.
            context.discovery04LegacyStoneRows = rows
            context.discovery04BuiltRows = 46
            context.branchTrace.add("DISCOVERY_04")
            context.diagnostics.add("DISCOVERY_04_LEGACY_SEQUENTIAL_STONES")
            context.status = "LEGACY_STONES_OBSERVED"
            metrics.bump("discovery04.legacy.builds")
        }
        dispatcher.register("DISCOVERY_05") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY05_CONTEXT_NOT_READY")
            val k = context.discovery05RequestedK
                ?: throw MonsterValidationException("E_DISCOVERY05_NO_REQUESTED_K")
            if (k !in 1..7) throw MonsterValidationException("E_DISCOVERY05_INVALID_K")
            // Mae'r pedwar patch blaenorol yn cael eu defnyddio mewn cynhyrchu;
            // ni cheir galwad at yr oracl prawf yn y llwybr hwn.
            val c = context.calculationDay
            val t = context.targetDay
            val actionTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                c, legacyDayTagAdapter.oldDayTag(c))
            val targetTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                t, legacyDayTagAdapter.oldDayTag(t))
            val distance = distancePatchWrapper.patchDistance(
                c, t, legacyDistanceAdapter.oldDistance(c, t)).inclusiveDistance
            val direction = ExactInt.of(when {
                t < c -> 1L
                t == c -> 2L
                else -> 3L
            })
            val counts = HiddenWorkCounts(
                actionTag, targetTag, distance, actionTag + targetTag, direction)
            val stoneTable = stonePatchWrapper.buildPatchedRows()
            val physical = legacyHiddenDropAdapter.buildBackwardStorage(
                counts, stoneTable.rows)
            val wrongRead = legacyHiddenDropAdapter.legacyHiddenDirectByAssumedNearness(physical, k)
            // Cyflwyno'r cyflwr yn atomig dim ond ar ôl llwyddiant pob cam.
            context.discovery05PatchedStoneRows = stoneTable.rows
            context.discovery05Patch04LegacyCalls = stoneTable.legacyCalls
            context.discovery05BackwardStorage = physical
            context.discovery05HiddenCount = 7
            context.discovery05Actual = wrongRead
            context.branchTrace.add("DISCOVERY_05")
            context.diagnostics.add("DISCOVERY_05_BACKWARD_HIDDEN_DIRECT_ACCESS")
            context.status = "LEGACY_HIDDEN_OBSERVED"
            metrics.bump("discovery05.builds")
            metrics.bump("discovery05.legacy.direct.read")
        }
        dispatcher.register("DISCOVERY_06") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY06_CONTEXT_NOT_READY")
            val i = context.discovery06PriorI ?: throw MonsterValidationException("E_DISCOVERY06_MISSING_I")
            val back = context.discovery06PriorBack ?: throw MonsterValidationException("E_DISCOVERY06_MISSING_BACK")
            if (i < 1 || back !in 1..7) throw MonsterValidationException("E_DISCOVERY06_INVALID_HISTORY")
            // Mae'r llwybr dilys yn profi'r ddarllenydd hanesol go iawn.
            // Nid ydym yn adeiladu diferion gweledig eto.
            val c = context.calculationDay
            val t = context.targetDay
            val actionTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                c, legacyDayTagAdapter.oldDayTag(c))
            val targetTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                t, legacyDayTagAdapter.oldDayTag(t))
            val distance = distancePatchWrapper.patchDistance(
                c, t, legacyDistanceAdapter.oldDistance(c, t)).inclusiveDistance
            val direction = ExactInt.of(when {
                t < c -> 1L
                t == c -> 2L
                else -> 3L
            })
            val counts = HiddenWorkCounts(
                actionTag, targetTag, distance, actionTag + targetTag, direction)
            val stoneTable = stonePatchWrapper.buildPatchedRows()
            val physical = legacyHiddenDropAdapter.buildBackwardStorage(counts, stoneTable.rows)
            // PATCH 05: galw'r graith hidden direct cyn dychwelyd hidden1 cywir.
            val correctedHidden1 = hiddenNearnessPatchWrapper.patch(physical, 1).correctedValue
            // STOFFA PROFI YN UNIG: slot 1 yn weledig ac yn cynnwys gwerth
            // wedi'i wirio; nid yw'n dechrau'r algorithm diferion gweledig.
            val visibleProbe = listOf<ExactInt?>(null, correctedHidden1)
            // Y GRAITH STAGE 12: dim fallback i hiddenK ar slot<=0.
            val prior = legacyPriorAdapter.legacyPrior(visibleProbe, i, back)
            // Commidio ar ôl cyfrifiad llwyddiannus yn unig.
            context.discovery06VisibleStore = visibleProbe
            context.discovery06HiddenStorage = physical
            context.discovery06Patch05HiddenOne = correctedHidden1
            context.discovery06PriorSlot = prior.slot
            context.discovery06PriorValue = prior.value
            context.discovery06ErrorId =
                if (prior.slot <= 0) "E_DISCOVERY06_MISSING_HIDDEN_HISTORY" else null
            context.discovery06InvocationCount = 1
            context.branchTrace.add("DISCOVERY_06")
            context.diagnostics.add("DISCOVERY_06_VISIBLE_ONLY_LEGACY_PRIOR")
            context.status = "LEGACY_PRIOR_OBSERVED"
            metrics.bump("discovery06.legacy.prior.calls")
        }
        dispatcher.register("DISCOVERY_07") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_DISCOVERY07_CONTEXT_NOT_READY")
            val grind = context.discovery07RequestedGrind
                ?: throw MonsterValidationException("E_DISCOVERY07_NO_GRIND")
            if (grind !in 1..11) throw MonsterValidationException("E_DISCOVERY07_GRIND_RANGE")
            // Mae'n rhaid defnyddio'r hen helper yn wirioneddol, heb sentinel.
            val actual = legacyGrindTableAdapter.legacyGrindRow(grind)
            val physical = legacyGrindTableAdapter.physicalRows()
            check(physical.size == 11 && actual.directIndex == grind) {
                "E_DISCOVERY07_PHYSICAL_SHAPE"
            }
            // Dim cofnodi ar ôl methiant: yr holl werthoedd yng nghyd-destun y galwad.
            context.discovery07DirectIndex = actual.directIndex
            context.discovery07LegacyRow = actual.row
            context.discovery07Undefined = actual.undefined
            context.discovery07PhysicalRows = physical
            context.discovery07InvocationCount = 1
            context.branchTrace.add("DISCOVERY_07")
            context.diagnostics.add("DISCOVERY_07_ZERO_BASED_ORDINAL_INDEX")
            context.status = "LEGACY_GRIND_OBSERVED"
            metrics.bump("discovery07.legacy.grind.calls")
        }
        dispatcher.register("PATCH_08") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH08_CONTEXT_NOT_READY")
            val drop = context.patch08DropValue
                ?: throw MonsterValidationException("E_PATCH08_NO_DROP")
            // Cam 17: galw'r hen caller cyn tynnu un yn y wrapper.
            val outcome = permutationPatchWrapper.patch(drop)
            check(outcome.dropValue == drop &&
                outcome.oneBased in 1..720 &&
                outcome.correctedRank0 == outcome.oneBased - 1 &&
                outcome.legacyRead.legacyCalls == 1 &&
                outcome.correctedUnrankCalls == 1 &&
                outcome.correctedOrder.size == 6 &&
                outcome.correctedOrder != outcome.legacyRead.legacyOrder) {
                "E_PATCH08_RESULT_SHAPE"
            }
            // Ymrwymo'r holl feysydd ar ôl llwyddiant; dim cyflwr traws-alwad.
            context.patch08OneBased = outcome.oneBased
            context.patch08CorrectedRank0 = outcome.correctedRank0
            context.patch08LegacyPassedRank0 = outcome.legacyRead.passedRank0
            context.patch08LegacyOrder = outcome.legacyRead.legacyOrder?.toList()
            context.patch08LegacyUndefined = outcome.legacyRead.undefined
            context.patch08LegacyErrorId = outcome.legacyRead.errorId
            context.patch08CorrectedOrder = outcome.correctedOrder.toList()
            context.patch08LegacyCalls = outcome.legacyRead.legacyCalls
            context.patch08CorrectedCalls = outcome.correctedUnrankCalls
            context.patch08Applied = true
            context.patch08InvocationCount = 1
            context.branchTrace.add("PATCH_08")
            context.diagnostics.add("PATCH_08_ONE_BASED_TO_ZERO_BASED")
            context.status = "PATCHED_PERMUTATION"
            metrics.bump("patch08.legacy.wrong.calls")
            metrics.bump("patch08.corrected.unrank.calls")
            metrics.bump("patch08.applied")
        }
        dispatcher.register("DISCOVERY_08") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_DISCOVERY08_CONTEXT_NOT_READY")
            val drop = context.discovery08DropValue
                ?: throw MonsterValidationException("E_DISCOVERY08_NO_DROP")
            // Galw'r caller anghywir yn wirioneddol, heb gywiriad.
            val actual = legacyPermutationOrderAdapter.legacyPermutationOrderFromDropWrong(drop)
            check(actual.dropValue == drop && actual.oneBased in 1..720 &&
                actual.passedRank0 == actual.oneBased &&
                actual.legacyCalls == 1 &&
                actual.undefined == (actual.oneBased == 720) &&
                (actual.legacyOrder?.size == 6 || actual.undefined)) {
                "E_DISCOVERY08_PRODUCTION_SHAPE"
            }
            // Ymrwymo'n atomig, heb ollyngiad rhwng galwadau.
            context.discovery08OneBased = actual.oneBased
            context.discovery08PassedRank0 = actual.passedRank0
            context.discovery08LegacyOrder = actual.legacyOrder?.toList()
            context.discovery08Undefined = actual.undefined
            context.discovery08ErrorId = actual.errorId
            context.discovery08LegacyCalls = actual.legacyCalls
            context.discovery08InvocationCount = 1
            context.branchTrace.add("DISCOVERY_08")
            context.diagnostics.add("DISCOVERY_08_ONE_BASED_AS_RANK0")
            context.status = "LEGACY_PERMUTATION_OBSERVED"
            metrics.bump("discovery08.legacy.unrank.calls")
        }
        dispatcher.register("PATCH_07") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH07_CONTEXT_NOT_READY")
            val grind = context.patch07RequestedGrind
                ?: throw MonsterValidationException("E_PATCH07_NO_GRIND")
            if (grind !in 1..11)
                throw MonsterValidationException("E_PATCH07_GRIND_RANGE")
            val result = grindPatchWrapper.patch(grind)
            check(result.translatedIndex == grind &&
                result.sentinelRows.size == 12 &&
                result.sentinelRows[0] == null &&
                result.sentinelRows[grind] == result.correctedRow &&
                result.physicalRows.size == 11) { "E_PATCH07_TRANSLATION_SHAPE" }
            // Ymrwymo yn atomig: dim cyflwr wedi'i storio cyn llwyddiant.
            context.patch07LegacyDirectIndex = result.legacyRead.directIndex
            context.patch07LegacyRow = result.legacyRead.row
            context.patch07LegacyUndefined = result.legacyRead.undefined
            context.patch07PhysicalRows = result.physicalRows
            context.patch07SentinelRows = result.sentinelRows
            context.patch07TranslatedIndex = result.translatedIndex
            context.patch07CorrectedRow = result.correctedRow
            context.patch07Applied = true
            context.patch07InvocationCount = 1
            context.branchTrace.add("PATCH_07")
            context.diagnostics.add("PATCH_07_SENTINEL_TRANSLATOR")
            context.status = "PATCHED_GRIND"
            metrics.bump("patch07.legacy.grind.calls")
            metrics.bump("patch07.applied")
        }
        dispatcher.register("PATCH_06") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH06_CONTEXT_NOT_READY")
            val i = context.patch06PriorI ?: throw MonsterValidationException("E_PATCH06_NO_I")
            val back = context.patch06PriorBack ?: throw MonsterValidationException("E_PATCH06_NO_BACK")
            if (i < 1 || back !in 1..7) throw MonsterValidationException("E_PATCH06_INVALID_HISTORY")
            // Defnyddio'r un 5 patch blaenorol yn y llwybr cynhyrchu.
            val c = context.calculationDay
            val t = context.targetDay
            val actionTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                c, legacyDayTagAdapter.oldDayTag(c))
            val targetTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                t, legacyDayTagAdapter.oldDayTag(t))
            val distance = distancePatchWrapper.patchDistance(
                c, t, legacyDistanceAdapter.oldDistance(c, t)).inclusiveDistance
            val direction = ExactInt.of(when {
                t < c -> 1L
                t == c -> 2L
                else -> 3L
            })
            val counts = HiddenWorkCounts(
                actionTag, targetTag, distance, actionTag + targetTag, direction)
            val stoneTable = stonePatchWrapper.buildPatchedRows()
            val physical = legacyHiddenDropAdapter.buildBackwardStorage(counts, stoneTable.rows)
            val hiddenOne = hiddenNearnessPatchWrapper.patch(physical, 1).correctedValue
            // Storfa weledig PROFI yn unig: nid yw Cam 13 yn adeiladu
            // diferion gweledig nac yn dechrau Cam 14.
            val visibleProbe = listOf<ExactInt?>(null, hiddenOne)
            val result = priorPatchWrapper.priorPatch(visibleProbe, physical, i, back)
            check(stoneTable.legacyCalls == 45) { "E_PATCH06_STONE_CALL_COUNT" }
            // Cyflwr atomig sy'n perthyn i'r cyd-destun presennol yn unig.
            context.patch06Slot = result.slot
            context.patch06HiddenK = result.hiddenK
            context.patch06Source = result.source
            context.patch06LegacyPriorCalled = result.legacyPriorCalled
            context.patch06Output = result.correctedValue
            context.patch06VisibleStore = visibleProbe
            context.patch06HiddenStorage = physical
            context.patch06Patch05HiddenOne = hiddenOne
            context.patch06StoneLegacyCalls = stoneTable.legacyCalls
            context.patch06Applied = true
            context.patch06InvocationCount = 1
            context.branchTrace.add("PATCH_06")
            context.diagnostics.add("PATCH_06_PRIOR_VISIBLE_OR_HIDDEN")
            context.status = "PATCHED_PRIOR"
            metrics.bump("patch06.applied")
            if (result.legacyPriorCalled) metrics.bump("patch06.legacy.prior.calls")
            else metrics.bump("patch06.hidden.nearness.calls")
        }
        dispatcher.register("PATCH_05") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH05_CONTEXT_NOT_READY")
            val k = context.patch05RequestedK
                ?: throw MonsterValidationException("E_PATCH05_NO_REQUESTED_K")
            if (k !in 1..7) throw MonsterValidationException("E_PATCH05_INVALID_K")
            // Adeiladu'r un storfa gorfforol yn ôl â DISCOVERY 05:
            // PATCH 02 + PATCH 03 + PATCH 04, heb alw'r oracl prawf.
            val c = context.calculationDay
            val t = context.targetDay
            val actionTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                c, legacyDayTagAdapter.oldDayTag(c))
            val targetTag = dayTagPatchWrapper.dayTagWithFoundationScar(
                t, legacyDayTagAdapter.oldDayTag(t))
            val distance = distancePatchWrapper.patchDistance(
                c, t, legacyDistanceAdapter.oldDistance(c, t)).inclusiveDistance
            val direction = ExactInt.of(when {
                t < c -> 1L
                t == c -> 2L
                else -> 3L
            })
            val counts = HiddenWorkCounts(
                actionTag, targetTag, distance, actionTag + targetTag, direction)
            val stoneTable = stonePatchWrapper.buildPatchedRows()
            val physical = legacyHiddenDropAdapter.buildBackwardStorage(counts, stoneTable.rows)
            // Mae patch() yn galw'r hen ddarllenydd yn gyntaf, cyn trosi 8-k.
            val outcome = hiddenNearnessPatchWrapper.patch(physical, k)
            check(outcome.physicalSlot in 1..7 && stoneTable.legacyCalls == 45) {
                "E_PATCH05_BUILD_COUNTS"
            }
            // Ymrwymo'n atomig ar ôl llwyddiant yr holl gyfrifiad.
            context.patch05PatchedStoneRows = stoneTable.rows
            context.patch05BackwardStorage = physical
            context.patch05StoneLegacyCalls = stoneTable.legacyCalls
            context.patch05HiddenCount = 7
            context.patch05PhysicalSlot = outcome.physicalSlot
            context.patch05LegacyDirectValue = outcome.legacyDirectValue
            context.patch05CorrectedValue = outcome.correctedValue
            context.patch05Applied = true
            context.patch05InvocationCount = 1
            context.branchTrace.add("PATCH_05")
            context.diagnostics.add("PATCH_05_HIDDEN_NEARNESS_8_MINUS_K")
            context.status = "PATCHED_HIDDEN"
            metrics.bump("patch05.legacy.direct.calls")
            metrics.bump("patch05.applied")
        }
        dispatcher.register("PATCH_04") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH04_CONTEXT_NOT_READY")
            // Cadw'r hen nam trwy ei alw ar glon ar gyfer POB un o'r 45 rhes.
            val outcome = stonePatchWrapper.buildPatchedRows()
            check(outcome.rows.size == 47 && outcome.legacyGarbageRows.size == 47 &&
                outcome.legacyCalls == 45) { "E_PATCH04_BUILDER_COUNTS" }
            // Ymrwymo dim ond ar ol i'r holl gyfrifiadau lwyddo.
            context.patch04StoneRows = outcome.rows
            context.patch04LegacyGarbageRows = outcome.legacyGarbageRows
            context.patch04BuiltRows = 46
            context.patch04LegacyCalls = outcome.legacyCalls
            context.branchTrace.add("PATCH_04")
            context.diagnostics.add("PATCH_04_SNAPSHOT_STONE_SCAR")
            context.status = "PATCHED_STONES"
            metrics.bump("patch04.legacy.calls") // Yn ôl nifer galwadau'r mutator
            // Cofnodi'r gwahaniaeth yn fanwl yn hytrach na'i greu fel galwad sengl.
            context.patch04LegacyCalls.let { count ->
                repeat(count - 1) { metrics.bump("patch04.legacy.calls") }
            }
            metrics.bump("patch04.applied")
        }
        dispatcher.register("PATCH_03") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH03_CONTEXT_NOT_READY")
            val calculation = context.patch03CalculationDay
                ?: throw MonsterValidationException("E_PATCH03_NO_CALCULATION_DAY")
            val target = context.patch03TargetDay
                ?: throw MonsterValidationException("E_PATCH03_NO_TARGET_DAY")
            if (calculation != context.calculationDay || target != context.targetDay) {
                throw MonsterValidationException("E_PATCH03_CONTEXT_MISMATCH")
            }
            // Cam 7: galw'r union graith cyn unrhyw gywiriad.
            val legacy = legacyDistanceAdapter.oldDistance(calculation, target)
            val outcome = distancePatchWrapper.patchDistance(calculation, target, legacy)
            // Dim ymrwymiad cyn bod yr holl gyfrifiad wedi llwyddo.
            context.patch03LegacyOutput = legacy
            context.patch03ChronologicalBase = outcome.chronologicalBase
            context.patch03SelectedBase = outcome.selectedBase
            context.patch03ReplacementApplied = outcome.replacedLegacyBase
            context.patch03Output = outcome.inclusiveDistance
            context.branchTrace.add("PATCH_03")
            context.diagnostics.add("PATCH_03_CHRONOLOGICAL_INCLUSIVE_SCAR")
            context.status = "PATCHED_DISTANCE"
            metrics.bump("patch03.legacy.calls")
            metrics.bump("patch03.applied")
            if (outcome.replacedLegacyBase) metrics.bump("patch03.replaced")
        }
        dispatcher.register("PATCH_02") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH02_CONTEXT_NOT_READY")
            val input = context.patch02Input
                ?: throw MonsterValidationException("E_PATCH02_NO_INPUT")
            // Y graith gyntaf; ni ddylai'r patch alw'r oracl normadol.
            val legacy = legacyDayTagAdapter.oldDayTag(input)
            val patched = dayTagPatchWrapper.dayTagWithFoundationScar(input, legacy)
            // Ymrwymo atomig ar ôl i'r cyfrifiad cyfan lwyddo.
            context.patch02LegacyOutput = legacy
            context.patch02Output = patched
            context.branchTrace.add("PATCH_02")
            context.diagnostics.add("PATCH_02_FOUNDATION_SCAR_WRAPPER")
            context.status = "PATCHED_DAY_TAG"
            metrics.bump("patch02.legacy.calls")
            metrics.bump("patch02.applied")
        }
        dispatcher.register("PATCH_01") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY") throw MonsterValidationException("E_PATCH01_CONTEXT_NOT_READY")
            val input = context.patch01Input
                ?: throw MonsterValidationException("E_PATCH01_NO_INPUT")
            // Mae'r graith yn parhau'n fyw: galw'r hen addasydd yn gyntaf.
            val legacy = legacyRemainderAdapter.oldRemainder(input)
            val patched = savePatchWrapper.savePatch(legacy)
            // Ymrwymo'r canlyniadau gyda'i gilydd ar ôl cyfrifiad llwyddiannus.
            context.patch01LegacyOutput = legacy
            context.patch01Output = patched
            context.branchTrace.add("PATCH_01")
            context.diagnostics.add("PATCH_01_SAVE_WRAPPER")
            context.status = "PATCHED"
            metrics.bump("patch01.legacy.calls")
            metrics.bump("patch01.applied")
        }
    }

    fun prepare(calculationDay: ExactInt, targetDay: ExactInt): BaseMonsterContext {
        val context = BaseMonsterContext(calculationDay, targetDay)
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_BOOT_WRAP", e)
        }
    }

    /**
     * Llwybr cynhyrchu ar gyfer archwilio gwall Cam 2 yn unig.
     * Mae pob gwerth semantig yn perthyn i gyd-destun y galwad.
     */
    fun observeLegacyRemainder(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        value: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery01Input = value
        context.phase = "DISCOVERY_01"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY01_WRAP", e)
        }
    }

    /** Llwybr cynhyrchu Cam 4, heb weithredu PATCH 02. */
    fun observeLegacyDayTag(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        day: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery02Input = day
        context.phase = "DISCOVERY_02"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY02_WRAP", e)
        }
    }

    /** Cam 6: BOOT, yna pellter diffygiol o dagiau PATCH 02. */
    fun observeLegacyDistance(calculationDay: ExactInt, targetDay: ExactInt): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery03CalculationDay = calculationDay
        context.discovery03TargetDay = targetDay
        context.phase = "DISCOVERY_03"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY03_WRAP", e)
        }
    }

    /** Cam 7: BOOT, yr hen bellter, yna'r pellter cronolegol cynhwysol. */
    fun applyDistancePatch(calculationDay: ExactInt, targetDay: ExactInt): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.patch03CalculationDay = calculationDay
        context.patch03TargetDay = targetDay
        context.phase = "PATCH_03"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH03_WRAP", e)
        }
    }

    /** Cam 8: BOOT, yna'r adeiladwr cerrig hanesyddol. */
    fun observeLegacyStones(calculationDay: ExactInt, targetDay: ExactInt): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.phase = "DISCOVERY_04"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY04_WRAP", e)
        }
    }

    /** Cam 10: adeiladu hidden7 ... hidden1 a darllen y slot anghywir yn uniongyrchol. */
    fun observeLegacyHiddenDrop(
        calculationDay: ExactInt, targetDay: ExactInt, k: Int = 1
    ): BaseMonsterContext {
        require(k in 1..7) { "E_DISCOVERY05_K_RANGE" }
        val context = prepare(calculationDay, targetDay)
        context.discovery05RequestedK = k
        context.phase = "DISCOVERY_05"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY05_WRAP", e)
        }
    }

    /** Cam 14: ymholi am ordinal 1-based fel index zero-based heb ei gywiro. */
    fun observeLegacyGrind(
        calculationDay: ExactInt, targetDay: ExactInt, grind: Int = 1
    ): BaseMonsterContext {
        require(grind in 1..11) { "E_DISCOVERY07_GRIND_RANGE" }
        val context = prepare(calculationDay, targetDay)
        context.discovery07RequestedGrind = grind
        context.phase = "DISCOVERY_07"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY07_WRAP", e)
        }
    }

    /** Cam 17: cyfieithu one-based -> zero-based, cadw'r graith fyw. */
    fun applyPermutationPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        dropValue: ExactInt = ExactInt.ONE
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.patch08DropValue = dropValue
        context.phase = "PATCH_08"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH08_WRAP", e)
        }
    }

    /** Cam 16: cadw canlyniad anghywir y caller one-based, heb PATCH 08. */
    fun observeLegacyPermutation(
        calculationDay: ExactInt, targetDay: ExactInt,
        dropValue: ExactInt = ExactInt.ONE
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery08DropValue = dropValue
        context.phase = "DISCOVERY_08"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY08_WRAP", e)
        }
    }

    /** Cam 15: cynhyrchu'r rhes gywir â chyfieithydd sentinel; dim diferion gweledig. */
    fun applyGrindPatch(
        calculationDay: ExactInt, targetDay: ExactInt, grind: Int = 1
    ): BaseMonsterContext {
        require(grind in 1..11) { "E_PATCH07_GRIND_RANGE" }
        val context = prepare(calculationDay, targetDay)
        context.patch07RequestedGrind = grind
        context.phase = "PATCH_07"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH07_WRAP", e)
        }
    }

    /** Cam 13: cadw'r helper raw ar slot positif; hiddenByNearness ar slot<=0. */
    fun applyPriorPatch(
        calculationDay: ExactInt, targetDay: ExactInt, i: Int = 2, back: Int = 1
    ): BaseMonsterContext {
        require(i >= 1 && back in 1..7) { "E_PATCH06_PRIOR_RANGE" }
        val context = prepare(calculationDay, targetDay)
        context.patch06PriorI = i
        context.patch06PriorBack = back
        context.phase = "PATCH_06"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH06_WRAP", e)
        }
    }

    /** Cam 12: galwad legacyPrior o storfa WELEDIG yn unig. */
    fun observeLegacyPrior(
        calculationDay: ExactInt, targetDay: ExactInt, i: Int = 2, back: Int = 1
    ): BaseMonsterContext {
        require(i >= 1 && back in 1..7) { "E_DISCOVERY06_PRIOR_RANGE" }
        val context = prepare(calculationDay, targetDay)
        context.discovery06PriorI = i
        context.discovery06PriorBack = back
        context.phase = "DISCOVERY_06"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY06_WRAP", e)
        }
    }

    /** Cam 11: BOOT, hen ddarlleniad anghywir, yna slot 8-k cywir. */
    fun applyHiddenNearnessPatch(
        calculationDay: ExactInt, targetDay: ExactInt, k: Int = 1
    ): BaseMonsterContext {
        require(k in 1..7) { "E_PATCH05_K_RANGE" }
        val context = prepare(calculationDay, targetDay)
        context.patch05RequestedK = k
        context.phase = "PATCH_05"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH05_WRAP", e)
        }
    }

    /** Cam 9: BOOT, 45 galwad etifeddol ar glonau, yna tabl cywir. */
    fun applyStonePatch(calculationDay: ExactInt, targetDay: ExactInt): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.phase = "PATCH_04"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH04_WRAP", e)
        }
    }

    /** PATCH 02: BOOT, oldDayTag unwaith, yna'r amod Sylfaen. */
    fun applyDayTagPatch(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        day: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.patch02Input = day
        context.phase = "PATCH_02"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH02_WRAP", e)
        }
    }

    /** Galwad cynhyrchu Patch 01: BOOT, y graith, yna'r deunydd lapio SAVE. */
    fun applySavePatch(
        calculationDay: ExactInt,
        targetDay: ExactInt,
        value: ExactInt
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.patch01Input = value
        context.phase = "PATCH_01"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH01_WRAP", e)
        }
    }
}
