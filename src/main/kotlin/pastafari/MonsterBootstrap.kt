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
    var patch08InvocationCount: Int = 0,
    var discovery09VisibleDrops: List<ExactInt>? = null,
    var discovery09InitialBowls: List<ExactInt>? = null,
    var discovery09Steps: List<LegacyPourStep>? = null,
    var discovery09FinalBowls: List<ExactInt>? = null,
    var discovery09OrderAt46: List<Int>? = null,
    var discovery09FixedPourCalls: Int = 0,
    var discovery09PermutationPatchCalls: Int = 0,
    var discovery09InvocationCount: Int = 0,
    var patch09InitialBowls: List<ExactInt>? = null,
    var patch09VisibleDrops: List<ExactInt>? = null,
    var patch09Steps: List<PatchedPourStep>? = null,
    var patch09FinalBowls: List<ExactInt>? = null,
    var patch09OrderAt46: List<Int>? = null,
    var patch09LegacyFixedPourCalls: Int = 0,
    var patch09CorrectedPourCalls: Int = 0,
    var patch09PermutationPatchCalls: Int = 0,
    var patch09Applied: Boolean = false,
    var patch09InvocationCount: Int = 0,
    var discovery10InitialBowls: List<ExactInt>? = null,
    var discovery10VisibleDrops: List<ExactInt>? = null,
    var discovery10Steps: List<LegacyInPlaceBowlStep>? = null,
    var discovery10FinalBowls: List<ExactInt>? = null,
    var discovery10OrderAt46: List<Int>? = null,
    var discovery10PatchedPourCalls: Int = 0,
    var discovery10LegacyPourCalls: Int = 0,
    var discovery10PermutationPatchCalls: Int = 0,
    var discovery10InPlaceWrites: Int = 0,
    var discovery10InvocationCount: Int = 0,
    var patch10InitialBowls: List<ExactInt>? = null,
    var patch10VisibleDrops: List<ExactInt>? = null,
    var patch10Steps: List<SnapshotBowlPatchOutcome>? = null,
    var patch10FinalBowls: List<ExactInt>? = null,
    var patch10OrderAt46: List<Int>? = null,
    var patch10LegacyMutatorCalls: Int = 0,
    var patch10CorrectedSnapshotCalls: Int = 0,
    var patch10PatchedPourCalls: Int = 0,
    var patch10FixedPourCalls: Int = 0,
    var patch10PermutationPatchCalls: Int = 0,
    var patch10LegacyWrites: Int = 0,
    var patch10CorrectedWrites: Int = 0,
    var patch10Applied: Boolean = false,
    var patch10InvocationCount: Int = 0,
    var discovery11InitialBowls: List<ExactInt>? = null,
    var discovery11Steps: List<LegacyCachedStirStep>? = null,
    var discovery11FinalBowls: List<ExactInt>? = null,
    var discovery11CachedSum: ExactInt? = null,
    var discovery11CacheComputations: Int = 0,
    var discovery11PermutationPatchCalls: Int = 0,
    var discovery11InvocationCount: Int = 0,
    var patch11InitialBowls: List<ExactInt>? = null,
    var patch11Steps: List<FreshStirStep>? = null,
    var patch11LegacyRun: LegacyCachedStirRun? = null,
    var patch11FinalBowls: List<ExactInt>? = null,
    var patch11LegacyCacheComputations: Int = 0,
    var patch11FreshSumComputations: Int = 0,
    var patch11LegacyPermutationCalls: Int = 0,
    var patch11CorrectedPermutationCalls: Int = 0,
    var patch11Applied: Boolean = false,
    var patch11InvocationCount: Int = 0,
    var discovery12FinalBowls: List<ExactInt>? = null,
    var discovery12Drop46: ExactInt? = null,
    var discovery12QueryBowl: Int? = null,
    var discovery12Seal: Int? = null,
    var discovery12Read: LegacyNumericNeighborRead? = null,
    var discovery12ActualNumericNeighbor: Int? = null,
    var discovery12ExpectedPositionalNeighbor: Int? = null,
    var discovery12FirstAnswer: ExactInt? = null,
    var discovery12DirectionStep: Int? = null,
    var discovery12PermutationCalls: Int = 0,
    var discovery12NumericNeighborCalls: Int = 0,
    var discovery12InvocationCount: Int = 0,
    var patch12FinalBowls: List<ExactInt>? = null,
    var patch12Drop46: ExactInt? = null,
    var patch12QueryBowl: Int? = null,
    var patch12Seal: Int? = null,
    var patch12Outcome: PositionalNeighborPatchOutcome? = null,
    var patch12CorrectedNeighborId: Int? = null,
    var patch12CorrectedFirstAnswer: ExactInt? = null,
    var patch12CorrectedDirectionNumber: ExactInt? = null,
    var patch12CorrectedDirectionStep: Int? = null,
    var patch12LegacyNumericNeighborCalls: Int = 0,
    var patch12CorrectedNeighborCalls: Int = 0,
    var patch12PermutationPatchCalls: Int = 0,
    var patch12Applied: Boolean = false,
    var patch12InvocationCount: Int = 0,
    var discovery13GateIndex: ExactInt? = null,
    var discovery13StreamFirst: ExactInt? = null,
    var discovery13DirectionStep: Int? = null,
    var discovery13LegacyRead: LegacyGateGapRankRead? = null,
    var discovery13WrongGap: Int? = null,
    var discovery13OneShotReads: Int = 0,
    var discovery13RejectedCandidatesProcessed: Int = 0,
    var discovery13InvocationCount: Int = 0,
    var patch13GateIndex: ExactInt? = null,
    var patch13StreamFirst: ExactInt? = null,
    var patch13DirectionStep: Int? = null,
    var patch13Outcome: GateGapPatchOutcome? = null,
    var patch13CorrectedRank1: Int? = null,
    var patch13CorrectedGateGap: Int? = null,
    var patch13AcceptedAnswer: ExactInt? = null,
    var patch13RejectedCandidates: List<ExactInt>? = null,
    var patch13LegacyRank0Calls: Int = 0,
    var patch13CorrectedRankCalls: Int = 0,
    var patch13AcceptedAnswerReads: Int = 0,
    var patch13RejectionChecks: Int = 0,
    var patch13Applied: Boolean = false,
    var patch13InvocationCount: Int = 0,
    var patch14Magnitude: ExactInt? = null,
    var patch14PreviousNegativeGate: ExactInt? = null,
    var patch14PositiveGap: Int? = null,
    var patch14NegativeStreamFirst: ExactInt? = null,
    var patch14NegativeStreamStep: Int? = null,
    var patch14Outcome: NegativeGateDirectionPatchOutcome? = null,
    var patch14CorrectedNegativeGate: ExactInt? = null,
    var patch14LegacyNegativeGate: ExactInt? = null,
    var patch14CorrectedNegativeGap: Int? = null,
    var patch14Applied: Boolean = false,
    var patch14InvocationCount: Int = 0
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
        PermutationPatchWrapper(legacyPermutationOrderAdapter),
    val legacyFixedPourAdapter: LegacyFixedPourAdapter =
        LegacyFixedPourAdapter(permutationPatchWrapper),
    val pourPatchWrapper: PourPatchWrapper =
        PourPatchWrapper(legacyFixedPourAdapter),
    val legacyInPlaceBowlAdapter: LegacyInPlaceBowlAdapter =
        LegacyInPlaceBowlAdapter(pourPatchWrapper),
    val bowlSnapshotPatchWrapper: BowlSnapshotPatchWrapper =
        BowlSnapshotPatchWrapper(legacyInPlaceBowlAdapter),
    val legacyCachedStirAdapter: LegacyCachedStirAdapter =
        LegacyCachedStirAdapter(permutationPatchWrapper),
    val freshStirPatchWrapper: FreshStirPatchWrapper =
        FreshStirPatchWrapper(legacyCachedStirAdapter, permutationPatchWrapper),
    val legacyNumericNeighborAdapter: LegacyNumericNeighborAdapter =
        LegacyNumericNeighborAdapter(permutationPatchWrapper),
    val positionalNeighborPatchWrapper: PositionalNeighborPatchWrapper =
        PositionalNeighborPatchWrapper(legacyNumericNeighborAdapter),
    val legacyGateGapRankAdapter: LegacyGateGapRankAdapter =
        LegacyGateGapRankAdapter(),
    val gateGapRankPatchWrapper: GateGapRankPatchWrapper =
        GateGapRankPatchWrapper(legacyGateGapRankAdapter),
    val negativeGateDirectionPatchWrapper: NegativeGateDirectionPatchWrapper =
        NegativeGateDirectionPatchWrapper()
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
        dispatcher.register("PATCH_14") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH14_CONTEXT_NOT_READY")
            val magnitude = context.patch14Magnitude
                ?: throw MonsterValidationException("E_PATCH14_NO_MAGNITUDE")
            val previous = context.patch14PreviousNegativeGate
                ?: throw MonsterValidationException("E_PATCH14_NO_PREVIOUS_GATE")
            val positiveGap = context.patch14PositiveGap
                ?: throw MonsterValidationException("E_PATCH14_NO_POSITIVE_GAP")
            val first = context.patch14NegativeStreamFirst
                ?: throw MonsterValidationException("E_PATCH14_NO_NEGATIVE_FIRST")
            val step = context.patch14NegativeStreamStep
                ?: throw MonsterValidationException("E_PATCH14_NO_NEGATIVE_DIRECTION")
            // Cwblhau'r cyfrifiad cyn ymrwymo: dim cyflwr rhannol os oes eithriad.
            val result = negativeGateDirectionPatchWrapper.patch(
                magnitude, previous, positiveGap, first, step)
            check(result.correctedNegativeGate ==
                previous - ExactInt.of(result.negativeGap.toLong()) &&
                result.legacyNegativeGate ==
                previous - ExactInt.of(positiveGap.toLong()) &&
                result.legacyCalls == 1 && result.correctedCalls == 1) {
                "E_PATCH14_RESULT_SHAPE"
            }
            context.patch14Outcome = result
            context.patch14LegacyNegativeGate = result.legacyNegativeGate
            context.patch14CorrectedNegativeGate = result.correctedNegativeGate
            context.patch14CorrectedNegativeGap = result.negativeGap
            context.patch14Applied = true
            context.patch14InvocationCount = 1
            context.branchTrace.add("PATCH_14")
            context.diagnostics.add("PATCH_14_NEGATIVE_SAUCE_DIRECTION")
            context.status = "PATCHED_NEGATIVE_GATE_DIRECTION"
            metrics.bump("patch14.experimental.legacy.calls")
            metrics.bump("patch14.corrected.negative.calls")
            metrics.bump("patch14.applied")
        }
        dispatcher.register("PATCH_13") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH13_CONTEXT_NOT_READY")
            val index = context.patch13GateIndex
                ?: throw MonsterValidationException("E_PATCH13_NO_INDEX")
            val first = context.patch13StreamFirst
                ?: throw MonsterValidationException("E_PATCH13_NO_FIRST")
            val direction = context.patch13DirectionStep
                ?: throw MonsterValidationException("E_PATCH13_NO_DIRECTION")
            val outcome=gateGapRankPatchWrapper.patch(index,first,direction)
            check(outcome.gateIndex==index &&
                outcome.streamFirst==first &&
                outcome.directionStep==direction &&
                outcome.correctedRank1 in 1..922 &&
                outcome.correctedGateGap==41+outcome.correctedRank1 &&
                outcome.correctedGateGap in 42..963 &&
                outcome.rejectedCandidates.size==outcome.acceptedAnswerIndex0 &&
                outcome.acceptedAnswerReads==outcome.acceptedAnswerIndex0+1 &&
                outcome.rejectionChecks==outcome.acceptedAnswerReads &&
                outcome.legacyRank0Calls==1 &&
                outcome.correctedRankCalls==1 &&
                outcome.legacyRead.gateGapWrong==
                    41+outcome.legacyRead.rank0Wrong &&
                outcome.legacyRead.oneShotReads==1 &&
                outcome.seal==1){"E_PATCH13_RESULT_SHAPE"}
            context.patch13Outcome=outcome.copy(
                rejectedCandidates=outcome.rejectedCandidates.toList())
            context.patch13CorrectedRank1=outcome.correctedRank1
            context.patch13CorrectedGateGap=outcome.correctedGateGap
            context.patch13AcceptedAnswer=outcome.acceptedAnswer
            context.patch13RejectedCandidates=outcome.rejectedCandidates.toList()
            context.patch13LegacyRank0Calls=1
            context.patch13CorrectedRankCalls=1
            context.patch13AcceptedAnswerReads=outcome.acceptedAnswerReads
            context.patch13RejectionChecks=outcome.rejectionChecks
            context.patch13Applied=true
            context.patch13InvocationCount=1
            context.branchTrace.add("PATCH_13")
            context.diagnostics.add("PATCH_13_UNRANK1_AND_REJECTION")
            context.status="PATCHED_GATE_GAP_RANK1"
            metrics.bump("patch13.legacy.gate.gap.calls")
            metrics.bump("patch13.corrected.gate.gap.calls")
            metrics.bump("patch13.applied")
        }
        dispatcher.register("DISCOVERY_13") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_DISCOVERY13_CONTEXT_NOT_READY")
            val index = context.discovery13GateIndex
                ?: throw MonsterValidationException("E_DISCOVERY13_NO_INDEX")
            val first = context.discovery13StreamFirst
                ?: throw MonsterValidationException("E_DISCOVERY13_NO_FIRST")
            val direction = context.discovery13DirectionStep
                ?: throw MonsterValidationException("E_DISCOVERY13_NO_DIRECTION")
            val scar = legacyGateGapRankAdapter.oldGateGapWithoutRank1(
                index,first,direction)
            check(scar.gateIndex == index &&
                scar.streamFirst == first &&
                scar.streamDirectionStep == direction &&
                scar.rank0Wrong in 0..921 &&
                scar.gateGapWrong == 41 + scar.rank0Wrong &&
                scar.gateGapWrong in 41..962 &&
                scar.oneShotReads == 1 &&
                scar.rejectedCandidatesProcessed == 0 &&
                scar.seal == 1) {
                "E_DISCOVERY13_RESULT_SHAPE"
            }
            context.discovery13LegacyRead = scar
            context.discovery13WrongGap = scar.gateGapWrong
            context.discovery13OneShotReads = scar.oneShotReads
            context.discovery13RejectedCandidatesProcessed =
                scar.rejectedCandidatesProcessed
            context.discovery13InvocationCount = 1
            context.branchTrace.add("DISCOVERY_13")
            context.diagnostics.add("DISCOVERY_13_GATE_GAP_RANK0_NO_REJECTION")
            context.status = "LEGACY_GATE_GAP_RANK0_OBSERVED"
            metrics.bump("discovery13.gate.gap.rank0.calls")
        }
        dispatcher.register("PATCH_12") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH12_CONTEXT_NOT_READY")
            val bowls = context.patch12FinalBowls
                ?: throw MonsterValidationException("E_PATCH12_NO_BOWLS")
            val drop = context.patch12Drop46
                ?: throw MonsterValidationException("E_PATCH12_NO_DROP46")
            val query = context.patch12QueryBowl
                ?: throw MonsterValidationException("E_PATCH12_NO_QUERY")
            val seal = context.patch12Seal
                ?: throw MonsterValidationException("E_PATCH12_NO_SEAL")
            val result = positionalNeighborPatchWrapper.patch(
                bowls,drop,query,seal)
            check(result.drop46 == drop && result.queriedBowlId == query &&
                result.seal == seal &&
                result.drop46Order.sorted() == listOf(1,2,3,4,5,6) &&
                result.correctedNeighborId ==
                    result.drop46Order[
                        (result.drop46Order.indexOf(query) + 1) % 6] &&
                result.legacyRead.actualNeighborIdWrong ==
                    (if (query == 6) 1 else query + 1) &&
                result.legacyRead.positionalNeighborIdExpected ==
                    result.correctedNeighborId &&
                result.correctedDirectionStep in listOf(-1,1) &&
                result.legacyNumericNeighborCalls == 1 &&
                result.correctedNeighborCalls == 1 &&
                result.patchedPermutationCalls == 1) {
                "E_PATCH12_RESULT_SHAPE"
            }
            context.patch12Outcome = result.copy(
                drop46Order = result.drop46Order.toList(),
                legacyRead = result.legacyRead.copy(
                    drop46Order = result.legacyRead.drop46Order.toList()))
            context.patch12CorrectedNeighborId = result.correctedNeighborId
            context.patch12CorrectedFirstAnswer = result.correctedFirstAnswer
            context.patch12CorrectedDirectionNumber =
                result.correctedDirectionNumber
            context.patch12CorrectedDirectionStep = result.correctedDirectionStep
            context.patch12LegacyNumericNeighborCalls = 1
            context.patch12CorrectedNeighborCalls = 1
            context.patch12PermutationPatchCalls = 1
            context.patch12Applied = true
            context.patch12InvocationCount = 1
            context.branchTrace.add("PATCH_12")
            context.diagnostics.add("PATCH_12_DROP46_POSITIONAL_NEXT_BOWL")
            context.status = "PATCHED_POSITIONAL_NEIGHBOR"
            metrics.bump("patch12.legacy.numeric.neighbor.calls")
            metrics.bump("patch12.corrected.positional.neighbor.calls")
            metrics.bump("patch12.applied")
        }
        dispatcher.register("DISCOVERY_12") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_DISCOVERY12_CONTEXT_NOT_READY")
            val bowls = context.discovery12FinalBowls
                ?: throw MonsterValidationException("E_DISCOVERY12_NO_BOWLS")
            val drop = context.discovery12Drop46
                ?: throw MonsterValidationException("E_DISCOVERY12_NO_DROP46")
            val query = context.discovery12QueryBowl
                ?: throw MonsterValidationException("E_DISCOVERY12_NO_QUERY")
            val seal = context.discovery12Seal
                ?: throw MonsterValidationException("E_DISCOVERY12_NO_SEAL")
            val result = legacyNumericNeighborAdapter.oldNumericNeighborQuestion(
                bowls,drop,query,seal)
            check(result.drop46 == drop &&
                result.queriedBowlId == query && result.seal == seal &&
                result.drop46Order.sorted() == listOf(1,2,3,4,5,6) &&
                result.positionalNeighborIdExpected ==
                    result.drop46Order[
                        (result.drop46Order.indexOf(query) + 1) % 6] &&
                result.actualNeighborIdWrong ==
                    (if (query == 6) 1 else query + 1) &&
                result.permutationPatchCalls == 1 &&
                result.numericNeighborCalls == 1 &&
                result.directionStep in listOf(-1,1)) {
                "E_DISCOVERY12_RESULT_SHAPE"
            }
            context.discovery12Read = result.copy(
                drop46Order = result.drop46Order.toList())
            context.discovery12ActualNumericNeighbor = result.actualNeighborIdWrong
            context.discovery12ExpectedPositionalNeighbor =
                result.positionalNeighborIdExpected
            context.discovery12FirstAnswer = result.firstAnswer
            context.discovery12DirectionStep = result.directionStep
            context.discovery12PermutationCalls = 1
            context.discovery12NumericNeighborCalls = 1
            context.discovery12InvocationCount = 1
            context.branchTrace.add("DISCOVERY_12")
            context.diagnostics.add("DISCOVERY_12_NUMERIC_ID_NOT_DROP46_NEXT")
            context.status = "LEGACY_NUMERIC_NEIGHBOR_OBSERVED"
            metrics.bump("discovery12.numeric.neighbor.calls")
        }
        dispatcher.register("PATCH_11") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH11_CONTEXT_NOT_READY")
            val initial = context.patch11InitialBowls
                ?: throw MonsterValidationException("E_PATCH11_NO_INITIAL")
            val run = freshStirPatchWrapper.patch(initial)
            check(run.steps.size == 12 && run.finalBowls.size == 7 &&
                run.legacyRun.steps.size == 12 && run.legacyRuns == 1 &&
                run.legacyCacheComputations == 1 &&
                run.correctedSumComputations == 12 &&
                run.legacyPermutationCalls == 12 &&
                run.correctedPermutationCalls == 12 &&
                run.steps.map { it.stir } == (1..12).toList() &&
                run.steps.all { it.permutationPatchCalls == 1 &&
                    it.correctedPermutationOrder.sorted() ==
                        listOf(1,2,3,4,5,6) } &&
                run.legacyRun.steps.all {
                    it.savedSumUsed == run.legacyRun.originalCachedSum }) {
                "E_PATCH11_RUN_SHAPE"
            }
            // Cadw pob maes dim ond ar ôl llwyddo'n llwyr.
            context.patch11Steps = run.steps.toList()
            context.patch11LegacyRun = run.legacyRun
            context.patch11FinalBowls = run.finalBowls.toList()
            context.patch11LegacyCacheComputations = run.legacyCacheComputations
            context.patch11FreshSumComputations = run.correctedSumComputations
            context.patch11LegacyPermutationCalls = run.legacyPermutationCalls
            context.patch11CorrectedPermutationCalls = run.correctedPermutationCalls
            context.patch11Applied = true
            context.patch11InvocationCount = 1
            context.branchTrace.add("PATCH_11")
            context.diagnostics.add("PATCH_11_FRESH_SUM_EACH_STIR")
            context.status = "PATCHED_FRESH_STIR_SUM"
            metrics.bump("patch11.legacy.cached.stir.runs")
            metrics.bump("patch11.corrected.fresh.stir.runs")
            metrics.bump("patch11.applied")
        }
        dispatcher.register("DISCOVERY_11") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_DISCOVERY11_CONTEXT_NOT_READY")
            val initial = context.discovery11InitialBowls
                ?: throw MonsterValidationException("E_DISCOVERY11_NO_INITIAL")
            val result = legacyCachedStirAdapter.oldCachedPostStir12(initial)
            check(result.totalStirs == 12 &&
                result.steps.size == 12 &&
                result.finalBowls.size == 7 &&
                result.cachedSumComputations == 1 &&
                result.permutationPatchCalls == 12 &&
                result.steps.map { it.stir } == (1..12).toList() &&
                result.steps.all { step ->
                    step.savedSumUsed == result.originalCachedSum &&
                    step.sumCacheOriginStir == 1 &&
                    step.correctedPermutationOrder.sorted() ==
                        listOf(1,2,3,4,5,6) &&
                    step.patchedPermutationCalls == 1
                }) { "E_DISCOVERY11_RUN_SHAPE" }
            context.discovery11Steps = result.steps.toList()
            context.discovery11FinalBowls = result.finalBowls.toList()
            context.discovery11CachedSum = result.originalCachedSum
            context.discovery11CacheComputations = result.cachedSumComputations
            context.discovery11PermutationPatchCalls = result.permutationPatchCalls
            context.discovery11InvocationCount = 1
            context.branchTrace.add("DISCOVERY_11")
            context.diagnostics.add("DISCOVERY_11_STALE_STIR1_SAVED_BOWL_SUM")
            context.status = "LEGACY_CACHED_STIR_OBSERVED"
            metrics.bump("discovery11.cached.poststir.runs")
        }
        dispatcher.register("PATCH_10") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH10_CONTEXT_NOT_READY")
            val initial = context.patch10InitialBowls
                ?: throw MonsterValidationException("E_PATCH10_NO_INITIAL")
            val visible = context.patch10VisibleDrops
                ?: throw MonsterValidationException("E_PATCH10_NO_VISIBLE")
            // Y mutator hanesyddol yn gyntaf ar glôn; snapshot wedyn.
            val result = bowlSnapshotPatchWrapper.runPatchedSnapshots(
                initial,visible)
            check(result.steps.size == 46 &&
                result.finalBowls.size == 7 &&
                result.orderAt46.sorted() == listOf(1,2,3,4,5,6) &&
                result.legacyMutatorCalls == 46 &&
                result.correctedSnapshotCalls == 46 &&
                result.patchedPourCalls == 46 &&
                result.preservedFixedPourCalls == 46 &&
                result.permutationPatchCalls == 46 &&
                result.preservedLegacyWrites == 276 &&
                result.correctedWrites == 276 &&
                result.steps.all { step ->
                    step.correctedWrites.map { it.position } == (1..6).toList() &&
                    step.legacyStep.writes.size == 6 &&
                    step.legacyStep.pourPatch.sourceIdsByPosition ==
                        step.legacyStep.pourPatch.order.take(3)
                }) { "E_PATCH10_RUN_SHAPE" }
            // Dylai'r context aros yn wag tan llwyddiant pob cam.
            context.patch10Steps = result.steps.toList()
            context.patch10FinalBowls = result.finalBowls.toList()
            context.patch10OrderAt46 = result.orderAt46.toList()
            context.patch10LegacyMutatorCalls = result.legacyMutatorCalls
            context.patch10CorrectedSnapshotCalls = result.correctedSnapshotCalls
            context.patch10PatchedPourCalls = result.patchedPourCalls
            context.patch10FixedPourCalls = result.preservedFixedPourCalls
            context.patch10PermutationPatchCalls = result.permutationPatchCalls
            context.patch10LegacyWrites = result.preservedLegacyWrites
            context.patch10CorrectedWrites = result.correctedWrites
            context.patch10Applied = true
            context.patch10InvocationCount = 1
            context.branchTrace.add("PATCH_10")
            context.diagnostics.add("PATCH_10_ALL_SIX_FROM_SAME_SNAPSHOT")
            context.status = "PATCHED_BOWL_SNAPSHOT"
            metrics.bump("patch10.legacy.inplace.calls")
            metrics.bump("patch10.corrected.snapshot.calls")
            metrics.bump("patch10.applied")
        }
        dispatcher.register("DISCOVERY_10") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_DISCOVERY10_CONTEXT_NOT_READY")
            val initial = context.discovery10InitialBowls
                ?: throw MonsterValidationException("E_DISCOVERY10_NO_INITIAL")
            val visible = context.discovery10VisibleDrops
                ?: throw MonsterValidationException("E_DISCOVERY10_NO_VISIBLE")
            // Mae pour PATCH 09 yn gywir; darlleniadau byw yw'r unig nam.
            val result = legacyInPlaceBowlAdapter.runWrongInPlace(initial, visible)
            check(result.steps.size == 46 &&
                result.finalBowls.size == 7 &&
                result.orderAt46.sorted() == listOf(1,2,3,4,5,6) &&
                result.patchedPourCalls == 46 &&
                result.preservedLegacyPourCalls == 46 &&
                result.permutationPatchCalls == 46 &&
                result.inPlaceWrites == 276 &&
                result.steps.all { step ->
                    step.writes.map { it.position } == (1..6).toList() &&
                    step.pourPatch.sourceIdsByPosition ==
                        step.pourPatch.order.take(3)
                }) { "E_DISCOVERY10_RUN_SHAPE" }
            // Dim ymrwymo nes bod pob un o'r 46 cymysgiad wedi llwyddo.
            context.discovery10Steps = result.steps.toList()
            context.discovery10FinalBowls = result.finalBowls.toList()
            context.discovery10OrderAt46 = result.orderAt46.toList()
            context.discovery10PatchedPourCalls = result.patchedPourCalls
            context.discovery10LegacyPourCalls = result.preservedLegacyPourCalls
            context.discovery10PermutationPatchCalls = result.permutationPatchCalls
            context.discovery10InPlaceWrites = result.inPlaceWrites
            context.discovery10InvocationCount = 1
            context.branchTrace.add("DISCOVERY_10")
            context.diagnostics.add("DISCOVERY_10_IN_PLACE_LIVE_BOWL_READS")
            context.status = "LEGACY_IN_PLACE_BOWLS_OBSERVED"
            metrics.bump("discovery10.inplace.runs")
        }
        dispatcher.register("PATCH_09") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_PATCH09_CONTEXT_NOT_READY")
            val initial = context.patch09InitialBowls
                ?: throw MonsterValidationException("E_PATCH09_NO_INITIAL")
            val visible = context.patch09VisibleDrops
                ?: throw MonsterValidationException("E_PATCH09_NO_VISIBLE")
            // Cywiro'r IDau ffynhonnell drwy'r order; galw'r graith gyntaf.
            val run = pourPatchWrapper.runPatchedPours(initial, visible)
            check(run.steps.size == 46 &&
                run.finalBowls.size == 7 &&
                run.orderAt46.sorted() == listOf(1,2,3,4,5,6) &&
                run.legacyFixedPourCalls == 46 &&
                run.correctedPourCalls == 46 &&
                run.permutationPatchCalls == 46 &&
                run.steps.all { step ->
                    step.pourPatch.legacyRead.sourceIdsWrong == listOf(1,2,3) &&
                    step.pourPatch.sourceIdsByPosition == step.order.take(3)
                }) { "E_PATCH09_RUN_SHAPE" }
            // Ymrwymo'n atomig ar ôl cwblhau pob cam.
            context.patch09Steps = run.steps.toList()
            context.patch09FinalBowls = run.finalBowls.toList()
            context.patch09OrderAt46 = run.orderAt46.toList()
            context.patch09LegacyFixedPourCalls = run.legacyFixedPourCalls
            context.patch09CorrectedPourCalls = run.correctedPourCalls
            context.patch09PermutationPatchCalls = run.permutationPatchCalls
            context.patch09Applied = true
            context.patch09InvocationCount = 1
            context.branchTrace.add("PATCH_09")
            context.diagnostics.add("PATCH_09_ORDER_POSITION_SOURCE_IDS")
            context.status = "PATCHED_POURS"
            metrics.bump("patch09.legacy.fixed.pour.calls")
            metrics.bump("patch09.corrected.pour.calls")
            metrics.bump("patch09.applied")
        }
        dispatcher.register("DISCOVERY_09") { context ->
            validation.requireBootstrapContext(context)
            if (context.status != "READY")
                throw MonsterValidationException("E_DISCOVERY09_CONTEXT_NOT_READY")
            val initial = context.discovery09InitialBowls
                ?: throw MonsterValidationException("E_DISCOVERY09_NO_INITIAL")
            val visible = context.discovery09VisibleDrops
                ?: throw MonsterValidationException("E_DISCOVERY09_NO_VISIBLE")
            // Y nam yw'r dair ffynhonnell sefydlog, nid y cymysgiad.
            val result = legacyFixedPourAdapter.runWrongPours(initial, visible)
            check(result.steps.size == 46 && result.finalBowls.size == 7 &&
                result.orderAt46.size == 6 &&
                result.fixedPourCalls == 46 &&
                result.permutationPatchCalls == 46 &&
                result.steps.all { it.fixedPour.sourceIdsWrong == listOf(1,2,3) }) {
                "E_DISCOVERY09_RUN_SHAPE"
            }
            // Ymrwymo dim ond ar ôl llwyddiant holl 46 cylch.
            context.discovery09Steps = result.steps.toList()
            context.discovery09FinalBowls = result.finalBowls.toList()
            context.discovery09OrderAt46 = result.orderAt46.toList()
            context.discovery09FixedPourCalls = result.fixedPourCalls
            context.discovery09PermutationPatchCalls = result.permutationPatchCalls
            context.discovery09InvocationCount = 1
            context.branchTrace.add("DISCOVERY_09")
            context.diagnostics.add("DISCOVERY_09_FIXED_IDS_NOT_ORDER_POSITIONS")
            context.status = "LEGACY_FIXED_POURS_OBSERVED"
            metrics.bump("discovery09.fixed.pour.calls")
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

    /** Cam 29: defnyddio stream negyddol canonaidd, gan gadw graith Cam 28. */
    fun applyNegativeGateDirectionPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        magnitude: ExactInt, previousNegativeGate: ExactInt,
        positiveGap: Int, negativeStreamFirst: ExactInt,
        negativeStreamStep: Int
    ): BaseMonsterContext {
        val context = prepare(calculationDay,targetDay)
        context.patch14Magnitude = magnitude
        context.patch14PreviousNegativeGate = previousNegativeGate
        context.patch14PositiveGap = positiveGap
        context.patch14NegativeStreamFirst = negativeStreamFirst
        context.patch14NegativeStreamStep = negativeStreamStep
        context.phase = "PATCH_14"
        return try {
            dispatcher.dispatch(context)
            context
        } catch(e:MonsterValidationException) {
            throw e
        } catch(e:Throwable) {
            throw errors.wrap("E_PATCH14_WRAP",e)
        }
    }

    /** Cam 27: galw'r hen rank0 cyn gwir unrank1 â rejection. */
    fun applyGateGapRankPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        gateIndex: ExactInt, streamFirst: ExactInt,
        directionStep: Int
    ): BaseMonsterContext {
        val context=prepare(calculationDay,targetDay)
        context.patch13GateIndex=gateIndex
        context.patch13StreamFirst=streamFirst
        context.patch13DirectionStep=directionStep
        context.phase="PATCH_13"
        return try {
            dispatcher.dispatch(context)
            context
        } catch(e:MonsterValidationException) {
            throw e
        } catch(e:Throwable) {
            throw errors.wrap("E_PATCH13_WRAP",e)
        }
    }

    /** Cam 26: gweld hen ordinal rank0 o stream gap y giât. */
    fun observeLegacyGateGapRank(
        calculationDay: ExactInt, targetDay: ExactInt,
        gateIndex: ExactInt, streamFirst: ExactInt,
        directionStep: Int
    ): BaseMonsterContext {
        val context = prepare(calculationDay,targetDay)
        context.discovery13GateIndex = gateIndex
        context.discovery13StreamFirst = streamFirst
        context.discovery13DirectionStep = directionStep
        context.phase = "DISCOVERY_13"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY13_WRAP",e)
        }
    }

    /** Cam 25: cywiro'r cymydog yn ôl trefn gwirioneddol diferyn 46. */
    fun applyPositionalNeighborPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        finalBowls: List<ExactInt>, drop46: ExactInt,
        queriedBowlId: Int, seal: Int
    ): BaseMonsterContext {
        val context = prepare(calculationDay,targetDay)
        context.patch12FinalBowls = finalBowls.toList()
        context.patch12Drop46 = drop46
        context.patch12QueryBowl = queriedBowlId
        context.patch12Seal = seal
        context.phase = "PATCH_12"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH12_WRAP",e)
        }
    }

    /** Cam 24: cofnodi next bowl anghywir yn ôl ID rhifol. */
    fun observeLegacyNumericNeighbor(
        calculationDay: ExactInt, targetDay: ExactInt,
        finalBowls: List<ExactInt>, drop46: ExactInt,
        queriedBowlId: Int, seal: Int
    ): BaseMonsterContext {
        val context = prepare(calculationDay,targetDay)
        context.discovery12FinalBowls = finalBowls.toList()
        context.discovery12Drop46 = drop46
        context.discovery12QueryBowl = queriedBowlId
        context.discovery12Seal = seal
        context.phase = "DISCOVERY_12"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY12_WRAP",e)
        }
    }

    /** Cam 23: 12 saved sums cywir a graith cache Cam 22 yn fyw. */
    fun applyFreshStirPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        initialAfterDrops: List<ExactInt>
    ): BaseMonsterContext {
        val context = prepare(calculationDay,targetDay)
        context.patch11InitialBowls = initialAfterDrops.toList()
        context.phase = "PATCH_11"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH11_WRAP",e)
        }
    }

    /** Cam 22: arsylwi hen cached sum mewn 12 stir ar ôl 46 diferion. */
    fun observeLegacyCachedStir(
        calculationDay: ExactInt, targetDay: ExactInt,
        initialAfterDrops: List<ExactInt>
    ): BaseMonsterContext {
        val context = prepare(calculationDay,targetDay)
        context.discovery11InitialBowls = initialAfterDrops.toList()
        context.phase = "DISCOVERY_11"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY11_WRAP",e)
        }
    }

    /** Cam 21: cywiro chwe bowl ar snapshot, cadw mutator byw ar glôn. */
    fun applyBowlSnapshotPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        initialBowls: List<ExactInt>, visibleDrops: List<ExactInt>
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.patch10InitialBowls = initialBowls.toList()
        context.patch10VisibleDrops = visibleDrops.toList()
        context.phase = "PATCH_10"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH10_WRAP", e)
        }
    }

    /** Cam 20: archwilio chwe diweddariad byw fesul un o'r 46 diferion. */
    fun observeLegacyInPlaceBowls(
        calculationDay: ExactInt, targetDay: ExactInt,
        initialBowls: List<ExactInt>, visibleDrops: List<ExactInt>
    ): BaseMonsterContext {
        val context = prepare(calculationDay, targetDay)
        context.discovery10InitialBowls = initialBowls.toList()
        context.discovery10VisibleDrops = visibleDrops.toList()
        context.phase = "DISCOVERY_10"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY10_WRAP", e)
        }
    }

    /** Cam 19: cadw'r arllwys anghywir, cywiro drwy safleoedd yr order. */
    fun applyPourPatch(
        calculationDay: ExactInt, targetDay: ExactInt,
        initialBowls: List<ExactInt>, visibleDrops: List<ExactInt>
    ): BaseMonsterContext {
        // Nid yw adeiladwr diferion gweledig yn rhan o Gam 19.
        val context = prepare(calculationDay, targetDay)
        context.patch09InitialBowls = initialBowls.toList()
        context.patch09VisibleDrops = visibleDrops.toList()
        context.phase = "PATCH_09"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_PATCH09_WRAP", e)
        }
    }

    /** Cam 18: arsylwi 46 arllwys â ffynonellau 1,2,3 sefydlog. */
    fun observeLegacyFixedPours(
        calculationDay: ExactInt, targetDay: ExactInt,
        initialBowls: List<ExactInt>, visibleDrops: List<ExactInt>
    ): BaseMonsterContext {
        // Nid yw adeiladwr diferion gweledig yn rhan o Gam 18.
        val context = prepare(calculationDay, targetDay)
        context.discovery09InitialBowls = initialBowls.toList()
        context.discovery09VisibleDrops = visibleDrops.toList()
        context.phase = "DISCOVERY_09"
        return try {
            dispatcher.dispatch(context)
            context
        } catch (e: MonsterValidationException) {
            throw e
        } catch (e: Throwable) {
            throw errors.wrap("E_DISCOVERY09_WRAP", e)
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
