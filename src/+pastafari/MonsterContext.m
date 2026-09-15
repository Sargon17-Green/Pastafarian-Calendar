classdef MonsterContext < handle
    % Kontekst jednego wywołania, rozbudowywany historycznie wraz z kolejnymi etapami.
    properties
        calculationDay
        targetDay
        phase
        subPhase
        mode
        status
        branchTrace
        metrics
        logs
        diagnostics
        lastError
        legacyRemainderInput
        legacyRemainderValue
        saveCandidate
        dayTagInput
        legacyDayTagValue
        dayTagCandidate
        actionCount
        targetCount
        legacyDistanceValue
        distanceCandidate
        connectionCount
        directionCount
        legacyStoneTable
        legacySecondStoneRow
        stoneTableCandidate
        hiddenBackward
        legacyHiddenLogicalCandidate
        hiddenLogicalCandidate
        legacyPriorRequestedSlots
        legacyPriorMissingMatrix
        legacyVisibleDrops
        visibleDropsCandidate
        preGrindVisibleDrops
        legacyGrindRequestedIndices
        legacyGrindResolvedIndices
        legacyGrindVisibleDrops
        grindVisibleCandidate
        permutationInput
        legacyPermutationRank0
        legacyPermutationOrder
        permutationRank1Candidate
        permutationDetourRank0
        permutationOrderCandidate
        initialBowlsCandidate
        legacyFirstRoundPours
        firstRoundPoursCandidate
        legacyFixedBowlFinalBowls
        bowlsCandidate
        currentBowlOrder
        preInPlaceBowlsCandidate
        legacyInPlaceFirstRoundBowls
        firstRoundStirCandidate
        legacyInPlaceFinalBowls
        stirBowlsCandidate
        prePostStirBowlsCandidate
        legacyOrderAtDrop46Observed
        legacyOverwritableOrderMemoryFinal
        legacyOrderMemoryWriteCount
        legacyOrderMemoryLastSource
        queriedOrderCandidate
        postStirBowlsCandidate
        successorOrderAt46
        successorQueriedBowlId
        legacyFixedNameSuccessor
        nextBowlCandidate
        answerRingFirst
        answerRingDirectionStep
        legacyBiasedPickInput
        legacyBiasedPickSize
        legacyBiasedPickRank
        smallPickCandidate
        legacyShortOnlyAssumed
        legacyGeneralSelectionRequestedSize
        legacyWideSelectionUnsupported
        legacyWideSelectionError
        legacyGeneralSelectionResult
        generalSelectionCandidate
        gateSignedStep
        legacyPositiveOnlyGateQuestionDay
        legacyPositiveOnlyGateGap
        gateQuestionDayCandidate
        gateGapCandidate
        legacyYearMaxDays
        legacyYearCandidateLengths
        legacyYearCandidatesAccepted
        yearCandidatesCandidate
        year5000InputCandidates
        legacyYear5000StableLengthOrder
        year5000CandidateOrder
        legacyYearJumpAnchorNumber
        legacyYearJumpAnchorOpenDay
        legacyYearJumpTargetDay
        legacyYearJumpDeltaDays
        legacyYearJumpOffset365
        legacyYearJumpGuessNumber
        legacyYearJumpGuessedYear
        targetYearCandidate
        legacyYearCacheKey
        legacyYearCacheHit
        legacyYearCacheEntryCalculationDayFingerprint
        legacyYearCacheEntryOpenGate
        legacyYearCacheEntryCloseGate
        legacyYearCacheRawValue
        legacyYearCacheProducerExecuted
        yearStructureCandidate
        structureSauceCalculationDay
        structureSauceOriginalTargetDay
        structureSauceYearFirstDay
        legacyStructureSauce
        legacyStructureSauceBowl2
        legacyStructureSauceOrderAt46
        structureSauceCandidate
        structureSauceBowl2Candidate
        cutletGapCount
        cutletCountCandidate
        cutletInternalGateOffset
        legacyPositiveCompositions
        legacyCutletPartitionFamilyCount
        legacyCutletPartitionRank
        legacyCutletPartition
        cutletPartitionCandidate
        cutletNameStreamFirst
        cutletNameStreamDirectionStep
        legacyCutletNameFamilyCount
        legacyCutletNameRank
        legacyNameCandidateIndices
        cutletNameIndicesCandidate
        distinctCutletNameFamilyCount
        distinctCutletNameRank
        monthNameStreamFirst
        monthNameStreamDirectionStep
        legacyMonthNameFamilyCount
        legacyMonthNameRank
        legacyMonthNameCandidateIndices
        distinctMonthNameFamilyCount
        distinctMonthNameRank
        monthNameIndicesCandidate
        monthLengthTotalDays
        monthLengthCountCandidate
        monthLengthStreamFirst
        monthLengthStreamDirectionStep
        legacyMonthLengthSafeCap
        legacyMonthLengthLowerBound
        legacyMonthLengthProofWidth
        legacyMonthLengthMaterializationAttempted
        legacyMonthLengthMaterializationBlocked
        legacyMonthLengthMaterializationError
        legacyMonthLengthConcreteCount
        legacyMonthLengthConcreteWays
        legacyMonthLengthRank
        monthLengthsCandidate
        monthWeavingLengthsInput
        monthWeavingStreamFirst
        monthWeavingStreamDirectionStep
        legacyDailyMonthRawProposals
        legacyDailyMonthWeaving
        legacyDailyMonthRemainingFinal
        monthWeavingCandidate
        wholeMonthWeavingFamilyCount
        wholeMonthWeavingRank
        wholeMonthWeavingDPResult
        wholeMonthWeavingReusedGhost
    end
    methods
        function obj = MonsterContext(calculationDay, targetDay)
            obj.calculationDay = calculationDay;
            obj.targetDay = targetDay;
            obj.phase = 'BOOTSTRAP_ENTRY';
            obj.subPhase = 0;
            obj.mode = 'BOOTSTRAP_NEUTRAL';
            obj.status = 'NEW';
            obj.branchTrace = {};
            obj.metrics = struct();
            obj.logs = {};
            obj.diagnostics = {};
            obj.lastError = [];
            obj.legacyRemainderInput = [];
            obj.legacyRemainderValue = [];
            obj.saveCandidate = [];
            obj.dayTagInput = [];
            obj.legacyDayTagValue = [];
            obj.dayTagCandidate = [];
            obj.actionCount = [];
            obj.targetCount = [];
            obj.legacyDistanceValue = [];
            obj.distanceCandidate = [];
            obj.connectionCount = [];
            obj.directionCount = [];
            obj.legacyStoneTable = [];
            obj.legacySecondStoneRow = [];
            obj.stoneTableCandidate = [];
            obj.hiddenBackward = [];
            obj.legacyHiddenLogicalCandidate = [];
            obj.hiddenLogicalCandidate = [];
            obj.legacyPriorRequestedSlots = [];
            obj.legacyPriorMissingMatrix = [];
            obj.legacyVisibleDrops = [];
            obj.visibleDropsCandidate = [];
            obj.preGrindVisibleDrops = [];
            obj.legacyGrindRequestedIndices = [];
            obj.legacyGrindResolvedIndices = [];
            obj.legacyGrindVisibleDrops = [];
            obj.grindVisibleCandidate = [];
            obj.permutationInput = [];
            obj.legacyPermutationRank0 = [];
            obj.legacyPermutationOrder = [];
            obj.permutationRank1Candidate = [];
            obj.permutationDetourRank0 = [];
            obj.permutationOrderCandidate = [];
            obj.initialBowlsCandidate = [];
            obj.legacyFirstRoundPours = [];
            obj.firstRoundPoursCandidate = [];
            obj.legacyFixedBowlFinalBowls = [];
            obj.bowlsCandidate = [];
            obj.currentBowlOrder = [];
            obj.preInPlaceBowlsCandidate = [];
            obj.legacyInPlaceFirstRoundBowls = [];
            obj.firstRoundStirCandidate = [];
            obj.legacyInPlaceFinalBowls = [];
            obj.stirBowlsCandidate = [];
            obj.prePostStirBowlsCandidate = [];
            obj.legacyOrderAtDrop46Observed = [];
            obj.legacyOverwritableOrderMemoryFinal = [];
            obj.legacyOrderMemoryWriteCount = [];
            obj.legacyOrderMemoryLastSource = '';
            obj.queriedOrderCandidate = [];
            obj.postStirBowlsCandidate = [];
            obj.successorOrderAt46 = [];
            obj.successorQueriedBowlId = [];
            obj.legacyFixedNameSuccessor = [];
            obj.nextBowlCandidate = [];
            obj.answerRingFirst = [];
            obj.answerRingDirectionStep = [];
            obj.legacyBiasedPickInput = [];
            obj.legacyBiasedPickSize = [];
            obj.legacyBiasedPickRank = [];
            obj.smallPickCandidate = [];
            obj.legacyShortOnlyAssumed = false;
            obj.legacyGeneralSelectionRequestedSize = [];
            obj.legacyWideSelectionUnsupported = false;
            obj.legacyWideSelectionError = '';
            obj.legacyGeneralSelectionResult = [];
            obj.generalSelectionCandidate = [];
            obj.gateSignedStep = [];
            obj.legacyPositiveOnlyGateQuestionDay = [];
            obj.legacyPositiveOnlyGateGap = [];
            obj.gateQuestionDayCandidate = [];
            obj.gateGapCandidate = [];
            obj.legacyYearMaxDays = [];
            obj.legacyYearCandidateLengths = [];
            obj.legacyYearCandidatesAccepted = {};
            obj.yearCandidatesCandidate = {};
            obj.year5000InputCandidates = {};
            obj.legacyYear5000StableLengthOrder = {};
            obj.year5000CandidateOrder = {};
            obj.legacyYearJumpAnchorNumber = [];
            obj.legacyYearJumpAnchorOpenDay = [];
            obj.legacyYearJumpTargetDay = [];
            obj.legacyYearJumpDeltaDays = [];
            obj.legacyYearJumpOffset365 = [];
            obj.legacyYearJumpGuessNumber = [];
            obj.legacyYearJumpGuessedYear = [];
            obj.targetYearCandidate = [];
            obj.legacyYearCacheKey = [];
            obj.legacyYearCacheHit = false;
            obj.legacyYearCacheEntryCalculationDayFingerprint = [];
            obj.legacyYearCacheEntryOpenGate = [];
            obj.legacyYearCacheEntryCloseGate = [];
            obj.legacyYearCacheRawValue = [];
            obj.legacyYearCacheProducerExecuted = false;
            obj.yearStructureCandidate = [];
            obj.structureSauceCalculationDay = [];
            obj.structureSauceOriginalTargetDay = [];
            obj.structureSauceYearFirstDay = [];
            obj.legacyStructureSauce = [];
            obj.legacyStructureSauceBowl2 = [];
            obj.legacyStructureSauceOrderAt46 = [];
            obj.structureSauceCandidate = [];
            obj.structureSauceBowl2Candidate = [];
            obj.cutletGapCount = [];
            obj.cutletCountCandidate = [];
            obj.cutletInternalGateOffset = [];
            obj.legacyPositiveCompositions = [];
            obj.legacyCutletPartitionFamilyCount = [];
            obj.legacyCutletPartitionRank = [];
            obj.legacyCutletPartition = [];
            obj.cutletPartitionCandidate = [];
            obj.cutletNameStreamFirst = [];
            obj.cutletNameStreamDirectionStep = [];
            obj.legacyCutletNameFamilyCount = [];
            obj.legacyCutletNameRank = [];
            obj.legacyNameCandidateIndices = [];
            obj.cutletNameIndicesCandidate = [];
            obj.distinctCutletNameFamilyCount = [];
            obj.distinctCutletNameRank = [];
            obj.monthNameStreamFirst = [];
            obj.monthNameStreamDirectionStep = [];
            obj.legacyMonthNameFamilyCount = [];
            obj.legacyMonthNameRank = [];
            obj.legacyMonthNameCandidateIndices = [];
            obj.distinctMonthNameFamilyCount = [];
            obj.distinctMonthNameRank = [];
            obj.monthNameIndicesCandidate = [];
            obj.monthLengthTotalDays = [];
            obj.monthLengthCountCandidate = [];
            obj.monthLengthStreamFirst = [];
            obj.monthLengthStreamDirectionStep = [];
            obj.legacyMonthLengthSafeCap = [];
            obj.legacyMonthLengthLowerBound = [];
            obj.legacyMonthLengthProofWidth = [];
            obj.legacyMonthLengthMaterializationAttempted = false;
            obj.legacyMonthLengthMaterializationBlocked = false;
            obj.legacyMonthLengthMaterializationError = '';
            obj.legacyMonthLengthConcreteCount = [];
            obj.legacyMonthLengthConcreteWays = {};
            obj.legacyMonthLengthRank = [];
            obj.monthLengthsCandidate = [];
            obj.monthWeavingLengthsInput = [];
            obj.monthWeavingStreamFirst = [];
            obj.monthWeavingStreamDirectionStep = [];
            obj.legacyDailyMonthRawProposals = [];
            obj.legacyDailyMonthWeaving = [];
            obj.legacyDailyMonthRemainingFinal = [];
            obj.monthWeavingCandidate = [];
            obj.wholeMonthWeavingFamilyCount = [];
            obj.wholeMonthWeavingRank = [];
            obj.wholeMonthWeavingDPResult = [];
            obj.wholeMonthWeavingReusedGhost = false;
        end
    end
end
