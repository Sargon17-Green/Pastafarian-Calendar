'use strict';

const { SourceLanguageCatalog, textByCanonicalIndex } = require('./source-language-catalog');

const M_OLD = (1n << 127n) - 1n;
const FOUNDATION_DAY_OLD = -15055671n;

class BootstrapStageError extends Error {
  constructor(message) {
    super(message);
    this.name = 'BootstrapStageError';
  }
}

class BaseMonsterContext {
  constructor(calculationDay, targetDay) {
    this.calculationDay = calculationDay;
    this.targetDay = targetDay;
    this.phase = 'BOOTSTRAP';
    this.status = 'NEW';
    this.currentHandler = null;
    this.previousHandler = null;
    this.branchTrace = [];
    this.metrics = Object.create(null);
    this.logs = [];
    this.diagnostics = [];
    this.lastError = null;
    this.legacyRemainderInput = null;
    this.legacyRemainderOutput = null;
    this.patch01Input = null;
    this.patch01Output = null;
    this.patch01LegacyWasZero = false;
    this.legacyDayTagInput = null;
    this.legacyDayTagOutput = null;
    this.patch02Input = null;
    this.patch02Output = null;
    this.patch02AddedParityUnit = false;
    this.patch02FoundationGuardChecked = false;
    this.legacyDistanceCalculationDay = null;
    this.legacyDistanceTargetDay = null;
    this.legacyDistanceCalculationTag = null;
    this.legacyDistanceTargetTag = null;
    this.legacyDistanceOutput = null;
    this.patch03CalculationDay = null;
    this.patch03TargetDay = null;
    this.patch03ChronologicalDistance = null;
    this.patch03LegacyReplaced = false;
    this.patch03DistanceBeforeInclusive = null;
    this.patch03Output = null;
    this.legacyStoneIndex = null;
    this.legacyStoneInputBefore = null;
    this.legacyStoneWorkingState = null;
    this.legacyStoneOutput = null;
    this.legacyStoneReturnedSameObject = false;
    this.patch04Index = null;
    this.patch04OldSnapshot = null;
    this.patch04LegacyGarbageBeforeOverwrite = null;
    this.patch04Output = null;
    this.patch04LegacyCallPreserved = false;
    this.legacyHiddenCounts = null;
    this.legacyHiddenStorage = null;
    this.legacyHiddenNearestReadAsSlotOne = null;
    this.legacyHiddenFarthestReadAsSlotSeven = null;
    this.patch05RequestedNearness = null;
    this.patch05PhysicalSlot = null;
    this.patch05Output = null;
    this.patch05StoragePreserved = false;
    this.legacyPriorDropStore = null;
    this.legacyPriorVisibleIndex = null;
    this.legacyPriorBack = null;
    this.legacyPriorSlot = null;
    this.legacyPriorSlotIsVisible = false;
    this.legacyPriorOutput = null;
    this.patch06HiddenStorage = null;
    this.patch06PriorSlot = null;
    this.patch06HiddenNearness = null;
    this.patch06LegacyVisibleCallUsed = false;
    this.patch06Output = null;
    this.legacyGrindRequestedIndex = null;
    this.legacyGrindPhysicalIndex = null;
    this.legacyGrindOutput = null;
    this.legacyGrindMissing = false;
    this.patch07RequestedIndex = null;
    this.patch07PhysicalIndex = null;
    this.patch07SentinelPreserved = false;
    this.patch07Output = null;
    this.legacyPermutationDrop = null;
    this.legacyPermutationOneBased = null;
    this.legacyPermutationRankPassedToUnrank0 = null;
    this.legacyPermutationOutput = null;
    this.patch08Drop = null;
    this.patch08OneBased = null;
    this.patch08LegacyRank0 = null;
    this.patch08Output = null;
    this.legacyPourDrop = null;
    this.legacyPourIndex = null;
    this.legacyPourOrder = null;
    this.legacyPourFixedBowlIds = null;
    this.legacyPourOldBowls = null;
    this.legacyPourStoneRow = null;
    this.legacyPourOutput = null;
    this.patch09BowlAlias = null;
    this.patch09AliasedBowlIds = null;
    this.patch09LegacyCallPreserved = false;
    this.patch09Output = null;
    this.legacyBowlRoundDrop = null;
    this.legacyBowlRoundIndex = null;
    this.legacyBowlRoundOrder = null;
    this.legacyBowlRoundPours = null;
    this.legacyBowlRoundInputBefore = null;
    this.legacyBowlRoundWorkingState = null;
    this.legacyBowlRoundOutput = null;
    this.legacyBowlRoundReturnedSameObject = false;
    this.patch10LegacyGarbage = null;
    this.patch10LegacyCallPreserved = false;
    this.patch10VaultOld = null;
    this.patch10Pending = null;
    this.patch10CommitAfterAllSix = false;
    this.patch10Output = null;
    this.legacyOrderMemory = null;
    this.legacyOrderMemoryWriteCount = 0;
    this.legacyOrderMemoryLastSource = null;
    this.legacyDrop46OrderDiagnostic = null;
    this.legacyLastPostStirOrder = null;
    this.legacyLastPostStirSavedSum = null;
    this.legacyDiscovery11Drops = null;
    this.legacyDiscovery11BowlsAfterDrops = null;
    this.legacyDiscovery11FinalBowls = null;
    this.legacyQueryOrder = null;
    this.patch11LegacyCallPreserved = false;
    this.patch11LegacyGarbage = null;
    this.patch11OrderAt46Latch = null;
    this.patch11OrderAt46LatchWriteCount = 0;
    this.patch11OrderAt46LatchSource = null;
    this.patch11LegacyOrderMemory = null;
    this.patch11LegacyOrderMemoryWriteCount = 0;
    this.patch11LegacyOrderMemoryLastSource = null;
    this.patch11LastPostStirOrder = null;
    this.patch11FinalBowls = null;
    this.patch11QueryOrder = null;
    this.legacyNextBowlOrderAt46Latch = null;
    this.legacyNextBowlQueriedId = null;
    this.legacyNextBowlOutput = null;
    this.patch12OrderAt46Latch = null;
    this.patch12QueriedId = null;
    this.patch12QueriedPosition = null;
    this.patch12LegacyDiagnostic = null;
    this.patch12LegacyDiagnosticPreserved = false;
    this.patch12Output = null;
    this.legacySelectionSeal = null;
    this.legacySelectionStreamFirst = null;
    this.legacySelectionDirectionStep = null;
    this.legacySelectionN = null;
    this.legacySelectionInitialAnswer = null;
    this.legacySelectionOutput = null;
    this.patch13AcceptanceLimit = null;
    this.patch13AcceptedOffset = null;
    this.patch13AcceptedAnswer = null;
    this.patch13LegacyCallPreserved = false;
    this.patch13Output = null;
    this.legacyWideSelectionSeal = null;
    this.legacyWideSelectionStreamFirst = null;
    this.legacyWideSelectionDirectionStep = null;
    this.legacyWideSelectionN = null;
    this.legacyWideSelectionAssumedShort = false;
    this.legacyWideSelectionFailed = false;
    this.legacyWideSelectionErrorName = null;
    this.legacyWideSelectionErrorMessage = null;
    this.legacyWideSelectionOutput = null;
    this.patch14Mode = null;
    this.patch14LegacyDiagnosticPreserved = false;
    this.patch14LegacyDiagnosticFailed = false;
    this.patch14LegacyDiagnosticErrorName = null;
    this.patch14LegacyDiagnosticOutput = null;
    this.patch14Places = null;
    this.patch14Space = null;
    this.patch14Digits = null;
    this.patch14DigitReadCount = null;
    this.patch14InitialWide = null;
    this.patch14AcceptanceLimit = null;
    this.patch14AcceptedWide = null;
    this.patch14RejectionSteps = null;
    this.patch14Output = null;
    this.legacyGateSignedStep = null;
    this.legacyGateMagnitude = null;
    this.legacyGateQuestionDay = null;
    this.legacyGateQuestionAskedPositiveSide = false;
    this.patch15SignedStep = null;
    this.patch15Magnitude = null;
    this.patch15LegacyDiagnostic = null;
    this.patch15LegacyDiagnosticPreserved = false;
    this.patch15NegativeDetourUsed = false;
    this.patch15Output = null;
    this.legacyYearCandidateInput = null;
    this.legacyYearCandidatePreSortFamily = null;
    this.legacyYearCandidateSortedFamily = null;
    this.legacyYearCandidateSelectionFamilySize = null;
    this.legacyYearCandidateSelectionStream = null;
    this.legacyYearCandidateSelectedOrdinal = null;
    this.legacyYearCandidateSelected = null;
    this.legacyYearCandidateOverlongLengths = null;
    this.patch16LegacyPreSortFamily = null;
    this.patch16LegacyCallsPreserved = false;
    this.patch16RejectedOverlongLengths = null;
    this.patch16FilteredPreSortFamily = null;
    this.patch16SortedFamily = null;
    this.patch16SelectionFamilySize = null;
    this.patch16SelectionStream = null;
    this.patch16SelectedOrdinal = null;
    this.patch16Selected = null;
    this.discovery17Year5000CalculationDay = null;
    this.discovery17PreparedForSelection = null;
    this.discovery17WitnessCandidateLength = null;
    this.discovery17WitnessFamilySize = null;
    this.discovery17OpeningOrder = null;
    this.discovery17SelectedOrdinal = null;
    this.discovery17Selected = null;
    this.discovery17StableLengthOnlyScarPreserved = false;
    this.patch17LegacyLengthSortedFamily = null;
    this.patch17LegacySelectedDiagnostic = null;
    this.patch17LegacyDiagnosticPreserved = false;
    this.patch17EqualLengthRunCount = null;
    this.patch17RepairedFamily = null;
    this.patch17SelectionFamilySize = null;
    this.patch17SelectionStream = null;
    this.patch17SelectedOrdinal = null;
    this.patch17Selected = null;
    this.legacyJumpAnchorNumber = null;
    this.legacyJumpAnchorOpenDay = null;
    this.legacyJumpAnchorFirstDay = null;
    this.legacyJumpAnchorCloseDay = null;
    this.legacyJumpTargetDay = null;
    this.legacyJumpDeltaFromFirstDay = null;
    this.legacyJumpGuess = null;
    this.legacyJumpSemanticYearNumber = null;
    this.legacyJumpGuessUsedAsSemantic = false;
    this.patch18LegacyGuessDiagnostic = null;
    this.patch18LegacyDiagnosticPreserved = false;
    this.patch18GuessIgnoredForSemantics = false;
    this.patch18WalkDirection = null;
    this.patch18WalkStepCount = null;
    this.patch18WalkTrace = null;
    this.patch18ResolvedYear = null;
    this.patch18SemanticYearNumber = null;
    this.legacyYearCacheKey = null;
    this.legacyYearCacheRequestActionDay = null;
    this.legacyYearCacheRequestOpeningDay = null;
    this.legacyYearCacheRequestClosingDay = null;
    this.legacyYearCacheFreshValue = null;
    this.legacyYearCacheHit = false;
    this.legacyYearCacheStoredBefore = null;
    this.legacyYearCacheOutput = null;
    this.legacyYearCacheOnlyNumberKeyPreserved = false;
    this.patch19LegacyLookupDiagnostic = null;
    this.patch19LegacyDiagnosticPreserved = false;
    this.patch19CacheKey = null;
    this.patch19CalculationDayFingerprint = null;
    this.patch19OpenGate = null;
    this.patch19CloseGate = null;
    this.patch19GuardedEntryBefore = null;
    this.patch19GuardMismatchReason = null;
    this.patch19CacheHit = false;
    this.patch19Recomputed = false;
    this.patch19EntryAfter = null;
    this.patch19Output = null;
    this.patch19OnlyNumberKeyPreserved = false;
    this.legacyStructureSauceCalculationDay = null;
    this.legacyStructureSauceOriginalTargetDay = null;
    this.legacyStructureSauceYearFirstDay = null;
    this.legacyStructureSauceTargetsDiffer = false;
    this.legacyStructureSauceBowls = null;
    this.legacyStructureSauceOrderAt46Latch = null;
    this.legacyStructureSelectorToken = null;
    this.legacyStructureSelectorUsedOriginalTargetSauce = false;
    this.patch20GhostCalculationDay = null;
    this.patch20GhostOriginalTargetDay = null;
    this.patch20YearFirstDay = null;
    this.patch20TargetsDiffer = false;
    this.patch20GhostSauceBowls = null;
    this.patch20GhostOrderAt46Latch = null;
    this.patch20GhostExecuted = false;
    this.patch20GhostIgnoredForSelector = false;
    this.patch20SemanticSauceBowls = null;
    this.patch20SemanticOrderAt46Latch = null;
    this.patch20SemanticSelectorToken = null;
    this.patch20SelectorUsedYearFirstDaySauce = false;
    this.legacyCutletGapCount = null;
    this.legacyCutletCountCandidates = null;
    this.legacyCutletCountStream = null;
    this.legacyCutletCountSelectedOrdinal = null;
    this.legacyCutletCount = null;
    this.legacyCutletInternalGateIndex = null;
    this.legacyCutletInternalGateOffset = null;
    this.legacyCutletFamilyCount = null;
    this.legacyCutletPartitionStream = null;
    this.legacyCutletSelectedRank = null;
    this.legacyCutletSelectedPartition = null;
    this.legacyCutletPrefixSums = null;
    this.legacyCutletInternalBoundaryHit = null;
    this.legacyCutletIgnoredInternalGate = false;
    this.patch21LegacyDiagnosticPreserved = false;
    this.patch21LegacyFamilyCountDiagnostic = null;
    this.patch21LegacySelectedRankDiagnostic = null;
    this.patch21LegacyPartitionDiagnostic = null;
    this.patch21LegacyPrefixSumsDiagnostic = null;
    this.patch21LegacyBoundaryHitDiagnostic = null;
    this.patch21FilteredFamilyUsed = false;
    this.patch21RawLegacyPassedThrough = false;
    this.patch21SemanticPartitionStream = null;
    this.patch21SemanticFamilyCount = null;
    this.patch21SemanticSelectedRank = null;
    this.patch21SemanticPartition = null;
    this.patch21SemanticPrefixSums = null;
    this.patch21SemanticBoundaryHit = null;
    this.patch21SelectionChangedFromLegacy = false;
    this.legacyCutletNameMasterIndices = null;
    this.legacyCutletNameCount = null;
    this.legacyCutletNameFamilyCount = null;
    this.legacyCutletNameStream = null;
    this.legacyCutletNameSelectedRank = null;
    this.legacyCutletNameIndices = null;
    this.legacyCutletNameHasRepeatedCanonicalIndex = false;
    this.legacyCutletNameUsedSemanticStructureSauce = false;
    this.legacyRepeatedNameGeneratorExecuted = false;
  }
}

class BaseValidationManager {
  requireExactInteger(value) {
    if (typeof value !== 'bigint') {
      throw new TypeError('Un valore integer exact deve esser representat quam BigInt.');
    }
  }

  requireDiscreteDay(value) {
    this.requireExactInteger(value);
  }

  requireStoneState(state) {
    if (!state || typeof state !== 'object') {
      throw new TypeError('Un statu de stones deve esser un object con quin integers BigInt.');
    }
    for (const key of ['w', 'b', 's', 'm', 'r']) {
      this.requireExactInteger(state[key]);
    }
  }

  requireHiddenCounts(counts) {
    if (!counts || typeof counts !== 'object') {
      throw new TypeError('Li comptes por hidden drops deve esser un object exact.');
    }
    for (const key of ['action', 'target', 'distance', 'connection', 'direction']) {
      this.requireExactInteger(counts[key]);
    }
  }

  requireStoneTableForHidden(stones) {
    if (!Array.isArray(stones) || stones.length < 7) {
      throw new TypeError('Li table de stones por hidden drops deve contener adminim sett rows.');
    }
    for (let index = 0; index < stones.length; index += 1) {
      this.requireStoneState(stones[index]);
    }
  }

  requireDropStore(dropStore) {
    if (!dropStore || typeof dropStore !== 'object') {
      throw new TypeError('Li storage legacy de visible drops deve esser un object indexabil.');
    }
  }

  requireHistoryIndex(value, label) {
    if (!Number.isInteger(value) || value < 1) {
      throw new RangeError(label + ' deve esser un integer positiv.');
    }
  }

  requireFreshContext(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'NEW') {
      throw new BootstrapStageError('Li context de invocation ne es in un statu inicial valid.');
    }
  }

  requireHistoricReadyContext(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'READY_FOR_HISTORIC_DEVELOPMENT') {
      throw new BootstrapStageError('Li context ne es pret por un passu historic de discovery.');
    }
  }

  requireDiscovery01Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_01_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 01.');
    }
  }

  requireDiscovery02Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_02_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 02.');
    }
  }

  requireDiscovery03Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_03_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 03.');
    }
  }

  requireDiscovery04Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_04_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 04.');
    }
  }

  requireDiscovery05Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_05_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un storage legacy valid por Patch 05.');
    }
  }

  requireDiscovery06Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_06_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 06.');
    }
  }

  requireDiscovery07Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_07_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 07.');
    }
  }

  requireDiscovery08Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_08_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 08.');
    }
  }

  requireDiscovery09Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_09_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un resultate legacy valid por Patch 09.');
    }
  }

  requireDiscovery10Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_10_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un bowl-round legacy valid por Patch 10.');
    }
  }

  requireDiscovery11Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_11_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un sauce legacy valid por Patch 11.');
    }
  }

  requirePatch11Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_11_RESULT') {
      throw new BootstrapStageError('Li context ne contene un latch valid de Patch 11 por Discovery 12.');
    }
  }

  requireDiscovery12Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_12_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un next-bowl legacy valid por Patch 12.');
    }
  }

  requirePatch12Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_12_RESULT') {
      throw new BootstrapStageError('Li context ne contene un next-bowl reparat valid por Discovery 13.');
    }
  }

  requireAnswerRing(stream) {
    if (!stream || typeof stream !== 'object') {
      throw new TypeError('Un answer ring deve esser un object con first e directionStep.');
    }
    this.requireExactInteger(stream.first);
    this.requireExactInteger(stream.directionStep);
    if (stream.first < 1n || stream.first > M_OLD) {
      throw new RangeError('Li prim answer deve esser inter 1 e M.');
    }
    if (stream.directionStep !== 1n && stream.directionStep !== -1n) {
      throw new RangeError('Li directionStep del answer ring deve esser +1 o -1.');
    }
  }

  requireShortFamilySize(value) {
    this.requireExactInteger(value);
    if (value < 1n || value > M_OLD) {
      throw new RangeError('Li familie legacy curt deve haver un grandore inter 1 e M.');
    }
  }

  requirePositiveFamilySize(value) {
    this.requireExactInteger(value);
    if (value < 1n) {
      throw new RangeError('Li familie legacy deve haver un grandore positiv.');
    }
  }

  requireDiscovery14Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_14_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un diagnostic legacy valid por Patch 14.');
    }
  }

  requireSignedGateStep(value) {
    this.requireExactInteger(value);
  }

  requireGateMagnitude(value) {
    this.requireExactInteger(value);
    if (value < 0n) {
      throw new RangeError('Li magnitude legacy del passu de gate ne posse esser negativ.');
    }
  }

  requireDiscovery15Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_15_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un question legacy valid por Patch 15.');
    }
  }

  requirePatch15Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_15_RESULT') {
      throw new BootstrapStageError('Li context ne contene un question de gate reparat valid por Discovery 16.');
    }
  }

  requirePatch16Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_16_RESULT') {
      throw new BootstrapStageError('Li context ne contene un familie de year candidates reparat valid por Discovery 17.');
    }
  }

  requireDiscovery17Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_17_LEGACY_TIE_RESULT') {
      throw new BootstrapStageError('Li context ne contene un tie legacy valid de Year 5000 por Patch 17.');
    }
  }

  requirePatch17Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_17_RESULT') {
      throw new BootstrapStageError('Li context ne contene un Year 5000 reparat valid por Discovery 18.');
    }
  }

  requireYearJumpAnchor(anchor) {
    if (!anchor || typeof anchor !== 'object') {
      throw new TypeError('Li anchor de Year 5000 por li jump legacy deve esser un object.');
    }
    for (const key of ['number', 'openDay', 'firstDay', 'closeDay']) {
      this.requireExactInteger(anchor[key]);
    }
    if (anchor.number !== 5000n) {
      throw new RangeError('Discovery 18 exige exactmen li anchor de Year 5000.');
    }
    if (anchor.firstDay !== anchor.openDay + 1n || anchor.closeDay < anchor.firstDay) {
      throw new RangeError('Li interval del anchor de Year 5000 es invalid.');
    }
  }

  requireDiscovery18Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_18_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un jump legacy valid por Patch 18.');
    }
  }

  requirePatch18Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_18_RESULT') {
      throw new BootstrapStageError('Li context ne contene un year resoluet per caminada valid por Discovery 19.');
    }
  }

  requirePatch19Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_19_RESULT') {
      throw new BootstrapStageError('Li context ne contene un cache guardat valid por Discovery 20.');
    }
  }

  requirePatch20Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_20_RESULT') {
      throw new BootstrapStageError('Li context ne contene un structure sauce reparat valid por Discovery 21.');
    }
  }

  requireDiscovery21Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_21_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un cutlet partition legacy valid por Patch 21.');
    }
  }

  requirePatch21Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_21_RESULT') {
      throw new BootstrapStageError('Li context ne contene un cutlet partition reparat valid por Discovery 22.');
    }
  }

  requireDiscovery22Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_22_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un candidate legacy de nomes valid por Patch 22.');
    }
  }

  requirePatch22Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_22_RESULT') {
      throw new BootstrapStageError('Li context ne contene un selection de nomes distinct valid por Discovery 23.');
    }
  }

  requireDiscovery23Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_23_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un attempt legacy de materialisation valid por Patch 23.');
    }
  }

  requirePatch23Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_23_RESULT') {
      throw new BootstrapStageError('Li context ne contene un liste virtual de longores valid por Discovery 24.');
    }
  }

  requireDiscovery24Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_24_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un ghost legacy de intertexe valid por Patch 24.');
    }
  }

  requirePatch24Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_24_RESULT') {
      throw new BootstrapStageError('Li context ne contene un intertexe semantic valid por Discovery 25.');
    }
  }

  requireDiscovery25Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_25_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un guess legacy de day-in-month valid por Patch 25.');
    }
  }

  requirePatch25Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'PATCH_25_RESULT') {
      throw new BootstrapStageError('Li context ne contene un day-in-month reparat valid por Discovery 26.');
    }
  }

  requireDiscovery26Result(context) {
    if (!(context instanceof BaseMonsterContext) || context.status !== 'DISCOVERY_26_LEGACY_RESULT') {
      throw new BootstrapStageError('Li context ne contene un ownership legacy del opening gate valid por Patch 26.');
    }
  }

  requireStructureSauceResult(result) {
    if (!result || typeof result !== 'object' || !Array.isArray(result.bowls) || result.bowls.length < 7 ||
        !Array.isArray(result.orderAt46Latch) || result.orderAt46Latch.length !== 6) {
      throw new TypeError('Li structure sauce legacy deve contener bowls 1..6 e li orderAt46Latch exact.');
    }
    for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
      this.requireExactInteger(result.bowls[bowlId]);
    }
    this.requireLatchedBowlOrder(result.orderAt46Latch);
  }

  requireYearCacheRecord(year) {
    if (!year || typeof year !== 'object') {
      throw new TypeError('Li year por li cache legacy deve esser un object.');
    }
    for (const key of ['number', 'openDay', 'closeDay']) {
      this.requireExactInteger(year[key]);
    }
    if (year.closeDay <= year.openDay) {
      throw new RangeError('Li year por li cache legacy deve haver un interval positiv.');
    }
  }

  requireYearWalkSource(yearWalkSource) {
    if (!yearWalkSource || typeof yearWalkSource !== 'object') {
      throw new TypeError('Li fonte de caminada annual deve esser un object con nextYear e previousYear.');
    }
    if (typeof yearWalkSource.nextYear !== 'function' || typeof yearWalkSource.previousYear !== 'function') {
      throw new TypeError('Li fonte de caminada annual deve exposer nextYear e previousYear quam functiones.');
    }
  }

  requireYearGateStore(gates) {
    if (!gates || typeof gates !== 'object') {
      throw new TypeError('Li storage legacy de gates por year candidates deve esser un object indexabil.');
    }
  }

  requireYearCandidatePairs(candidatePairs) {
    if (!Array.isArray(candidatePairs) || candidatePairs.length < 1) {
      throw new TypeError('Li familie legacy de year candidates deve contener adminim un pare de gates.');
    }
    for (const pair of candidatePairs) {
      if (!pair || typeof pair !== 'object' || !Number.isInteger(pair.openIndex) || !Number.isInteger(pair.closeIndex)) {
        throw new TypeError('Chascun year candidate legacy deve contener openIndex e closeIndex integers.');
      }
      if (pair.closeIndex <= pair.openIndex) {
        throw new RangeError('Li closeIndex de un year candidate legacy deve esser plu grand quam openIndex.');
      }
    }
  }

  requireBowlId(value) {
    if (!Number.isInteger(value) || value < 1 || value > 6) {
      throw new RangeError('Li ID de bowl questionat deve esser un integer inter 1 e 6.');
    }
  }

  requireLatchedBowlOrder(order) {
    if (!Array.isArray(order) || order.length !== 6) {
      throw new TypeError('Li order latchet deve contener exactmen six bowl IDs.');
    }
    const seen = new Set();
    for (const id of order) {
      this.requireBowlId(id);
      if (seen.has(id)) {
        throw new RangeError('Li order latchet ne posse contener IDs duplicat.');
      }
      seen.add(id);
    }
  }

  requireStoneTableForOrderMemory(stones) {
    if (!Array.isArray(stones) || stones.length < 46) {
      throw new TypeError('Li table de stones por li memorie de order deve contener 46 rows.');
    }
    for (let index = 0; index < 46; index += 1) {
      this.requireStoneState(stones[index]);
    }
  }

  requireVisibleGrindIndex(value) {
    if (!Number.isInteger(value) || value < 1 || value > 11) {
      throw new RangeError('Li ordinal de grind visibil deve esser un integer inter 1 e 11.');
    }
  }

  requireBowlVector(bowls) {
    if (!Array.isArray(bowls) || bowls.length < 7) {
      throw new TypeError('Li vector de bowls deve conservar indices 1..6.');
    }
    for (let id = 1; id <= 6; id += 1) {
      this.requireExactInteger(bowls[id]);
    }
  }

  requirePourStoneRow(row) {
    if (!row || typeof row !== 'object') {
      throw new TypeError('Li row de stones por un pour deve esser un object.');
    }
    for (const key of ['w', 'b', 's']) {
      this.requireExactInteger(row[key]);
    }
  }

  requireVisibleDropIndex(index) {
    this.requireExactInteger(index);
    if (index < 1n || index > 46n) {
      throw new RangeError('Li index del visible drop deve esser inter 1 e 46.');
    }
  }
}

class BaseMetricsManager {
  bump(context, key) {
    const oldValue = Object.prototype.hasOwnProperty.call(context.metrics, key) ? context.metrics[key] : 0n;
    context.metrics[key] = oldValue + 1n;
  }
}

class BaseErrorWrapper {
  wrap(error, phase) {
    const wrapped = new BootstrapStageError('Errore durant li fase historic: ' + phase + '.');
    wrapped.cause = error;
    return wrapped;
  }
}

class BaseDispatcher {
  constructor(validationManager, metricsManager, errorWrapper) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.errorWrapper = errorWrapper;
  }

  dispatch(context) {
    this.validationManager.requireFreshContext(context);
    this.validationManager.requireDiscreteDay(context.calculationDay);
    this.validationManager.requireDiscreteDay(context.targetDay);
    context.phase = 'BOOTSTRAP_VALIDATED';
    context.status = 'READY_FOR_HISTORIC_DEVELOPMENT';
    context.branchTrace.push('BOOTSTRAP_VALIDATED');
    this.metricsManager.bump(context, 'bootstrap.validations');
    return context;
  }
}

function regularMod(value, divisor) {
  if (typeof value !== 'bigint' || typeof divisor !== 'bigint' || divisor < 1n) {
    throw new TypeError('regularMod exige integers BigInt e un divisor positiv.');
  }
  const remainder = value % divisor;
  return remainder < 0n ? remainder + divisor : remainder;
}

function oldRemainder(value) {
  return regularMod(value, M_OLD);
}

function savePatch(value) {
  let remainder = oldRemainder(value);
  // Li defect legacy resta intact: li patch remappa solmen li residu zero al valore reservat M.
  if (remainder === 0n) {
    remainder = M_OLD;
  }
  return remainder;
}

function oldDayTag(day) {
  const distance = day >= FOUNDATION_DAY_OLD
    ? day - FOUNDATION_DAY_OLD
    : FOUNDATION_DAY_OLD - day;
  return 2n * distance;
}

function dayTagWithFoundationScar(day) {
  let n = oldDayTag(day);
  // Li defect legacy resta intact quam scar historic; it ne es correctet in su fonte.
  // Ante li Foundation it es ja exact; al o pos li Foundation li diferentie normativ es precis +1.
  if (day >= FOUNDATION_DAY_OLD) {
    n += 1n;
  }
  // Ti guard redundant resta quam scar del prim correction del Foundation.
  if (day === FOUNDATION_DAY_OLD && n !== 1n) {
    n = 1n;
  }
  return n;
}

function oldDistance(calculationDay, targetDay) {
  const calculationTag = dayTagWithFoundationScar(calculationDay);
  const targetTag = dayTagWithFoundationScar(targetDay);
  return calculationTag >= targetTag
    ? calculationTag - targetTag
    : targetTag - calculationTag;
}

function distanceWithChronologyDetour(calculationDay, targetDay) {
  let legacy = oldDistance(calculationDay, targetDay);
  const chronological = targetDay >= calculationDay
    ? targetDay - calculationDay
    : calculationDay - targetDay;
  // Li valore legacy ne es reparat in su fonte: li wrapper substitue solmen si li mesure de tags diverge del distance cronologic.
  if (legacy !== chronological) {
    legacy = chronological;
  }
  const distance = legacy + 1n;
  return distance;
}

function mutateStonesWrong(index, state) {
  // Ti operation legacy muta li object in-place e usa immediatmen valores ja mutat in li passus sequent.
  state.w = savePatch(state.w * state.w + 3n * state.b + index);
  state.b = savePatch(state.b * state.b + 5n * state.s + state.w);
  state.s = savePatch(state.s * state.s + 7n * state.m + state.b);
  state.m = savePatch(state.m * state.m + 11n * state.r + state.s);
  state.r = savePatch(state.r * state.r + 13n * state.w + state.m);
  return state;
}

function cloneStoneState(state) {
  return { w: state.w, b: state.b, s: state.s, m: state.m, r: state.r };
}

function stonePatch(index, state) {
  const old = cloneStoneState(state);
  // Li call legacy resta real e intentional; su resultate es poy totalmen superscrit ex li snapshot old.
  const garbage = mutateStonesWrong(index, cloneStoneState(state));
  garbage.w = savePatch(old.w * old.w + 3n * old.b + index);
  garbage.b = savePatch(old.b * old.b + 5n * old.s + old.w);
  garbage.s = savePatch(old.s * old.s + 7n * old.m + old.b);
  garbage.m = savePatch(old.m * old.m + 11n * old.r + old.s);
  garbage.r = savePatch(old.r * old.r + 13n * old.w + old.m);
  return garbage;
}

function getStoneTableThroughLegacyBuilder() {
  let state = { w: 17n, b: 29n, s: 43n, m: 71n, r: 101n };
  const table = [cloneStoneState(state)];
  let index = 2n;
  while (index <= 46n) {
    state = stonePatch(index, state);
    table.push(cloneStoneState(state));
    index += 1n;
  }
  return table;
}

const LEGACY_HIDDEN_COEFF_REVERSED = Object.freeze([
  null,
  Object.freeze([15n, 22n, 30n, 32n]),
  Object.freeze([13n, 19n, 26n, 28n]),
  Object.freeze([11n, 16n, 22n, 24n]),
  Object.freeze([9n, 13n, 18n, 20n]),
  Object.freeze([7n, 10n, 14n, 16n]),
  Object.freeze([5n, 7n, 10n, 12n]),
  Object.freeze([3n, 4n, 6n, 8n])
]);

const HIDDEN_STONE_KIND_STRANGE = Object.freeze([null, 'w', 'b', 's', 'm', 'r', 'w', 'b']);

function requireHiddenOrdinal(value, label) {
  if (!Number.isInteger(value) || value < 1 || value > 7) {
    throw new RangeError(label + ' deve esser un index integer inter 1 e 7.');
  }
}

function coeffForHidden(k) {
  requireHiddenOrdinal(k, 'Li ordinal de hidden drop');
  // Li table legacy es fisicmen inversat; ti lookup conserva su orientation historic.
  return LEGACY_HIDDEN_COEFF_REVERSED[8 - k];
}

function hiddenStoneKind(grind) {
  requireHiddenOrdinal(grind, 'Li ordinal de grind por hidden drop');
  return HIDDEN_STONE_KIND_STRANGE[grind];
}

function makeHiddenPatched(k, counts, stones) {
  requireHiddenOrdinal(k, 'Li ordinal de hidden drop');
  const [a, b, c, d] = coeffForHidden(k);
  const row = stones[k - 1];
  let x = counts.action
    + a * counts.target
    + b * counts.distance
    + c * counts.connection
    + d * counts.direction;
  // Li checksum legacy resta quam un loop generic super li quin species de stone.
  for (const kind of ['w', 'b', 's', 'm', 'r']) {
    x += row[kind];
  }
  x = savePatch(x);
  let grind = 1;
  while (grind <= 7) {
    const beforeSquare = x;
    x = savePatch(
      beforeSquare * beforeSquare
      + 3n * beforeSquare
      + row[hiddenStoneKind(grind)]
      + BigInt(grind)
    );
    grind += 1;
  }
  return x;
}

function buildHiddenWithBackwardStorage(counts, stones) {
  // Index 0 resta vacui por conservar li convention historic 1..7.
  const legacyHidden = new Array(8).fill(null);
  for (let k = 1; k <= 7; k += 1) {
    legacyHidden[8 - k] = makeHiddenPatched(k, counts, stones);
  }
  return legacyHidden;
}

function hiddenByNearness(legacyHidden, k) {
  requireHiddenOrdinal(k, 'Li ordinal de hidden drop');
  if (!Array.isArray(legacyHidden) || legacyHidden.length < 8) {
    throw new TypeError('Li storage legacy de hidden drops deve conservar slots 1..7.');
  }
  // Li array ne es reversat: li translator historic converte proximity k al slot fisic 8-k.
  return legacyHidden[8 - k];
}

function legacyPrior(dropStore, i, back) {
  if (!dropStore || typeof dropStore !== 'object') {
    throw new TypeError('Li storage legacy de visible drops deve esser un object indexabil.');
  }
  if (!Number.isInteger(i) || i < 1 || !Number.isInteger(back) || back < 1) {
    throw new RangeError('Li indices legacy de history deve esser integers positiv.');
  }
  // Li scar historic conosse solmen li storage de visible drops e tenta leer directmen i-back.
  return dropStore[i - back];
}

function priorPatch(dropStore, legacyHidden, i, back) {
  if (!Number.isInteger(i) || i < 1 || !Number.isInteger(back) || back < 1) {
    throw new RangeError('Li indices de history reparat deve esser integers positiv.');
  }
  const slot = i - back;
  if (slot >= 1) {
    // Por history visibil li call legacy resta real e decide li valore retornat.
    return legacyPrior(dropStore, i, back);
  }
  const k = 1 - slot;
  // Por slots 0..-6 li patch traducte al proximity hidden, sin inventar slots negativ in dropStore.
  return hiddenByNearness(legacyHidden, k);
}

const LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED = Object.freeze([
  Object.freeze({ kind: 'w', a: 3n, b: 5n, c: 7n, d: 11n }),
  Object.freeze({ kind: 'b', a: 5n, b: 7n, c: 11n, d: 13n }),
  Object.freeze({ kind: 's', a: 7n, b: 11n, c: 13n, d: 17n }),
  Object.freeze({ kind: 'm', a: 11n, b: 13n, c: 17n, d: 19n }),
  Object.freeze({ kind: 'r', a: 13n, b: 17n, c: 19n, d: 23n }),
  Object.freeze({ kind: 'w', a: 17n, b: 19n, c: 23n, d: 29n }),
  Object.freeze({ kind: 'b', a: 19n, b: 23n, c: 29n, d: 31n }),
  Object.freeze({ kind: 's', a: 23n, b: 29n, c: 31n, d: 37n }),
  Object.freeze({ kind: 'm', a: 29n, b: 31n, c: 37n, d: 41n }),
  Object.freeze({ kind: 'r', a: 31n, b: 37n, c: 41n, d: 43n }),
  Object.freeze({ kind: 'w', a: 37n, b: 41n, c: 43n, d: 47n })
]);

function legacyGrindRow(grind) {
  if (!Number.isInteger(grind) || grind < 1 || grind > 11) {
    throw new RangeError('Li ordinal legacy de grind visibil deve esser inter 1 e 11.');
  }
  // Li table es zero-based, ma li caller historic continua usar ordinals 1..11 directmen.
  return LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED[grind];
}

const GRIND_TABLE_WITH_SENTINEL = Object.freeze([
  null,
  ...LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED
]);

function grindRowWithSentinel(grind) {
  if (!Number.isInteger(grind) || grind < 1 || grind > 11) {
    throw new RangeError('Li ordinal reparat de grind visibil deve esser inter 1 e 11.');
  }
  // Li caller conserva su index one-based; li sentinel ocupa fisicmen index 0 e ne es removet.
  return GRIND_TABLE_WITH_SENTINEL[grind];
}

const LEGACY_BOWL_FACTORIALS = Object.freeze([1n, 1n, 2n, 6n, 24n, 120n, 720n]);

function oldPermutationUnrank0(rank0) {
  if (typeof rank0 !== 'bigint' || rank0 < 0n || rank0 >= 720n) {
    throw new RangeError('Li rank0 legacy de permutation deve esser inter 0 e 719.');
  }
  let residual = rank0;
  const remaining = [1, 2, 3, 4, 5, 6];
  const order = [];
  for (let slotsLeft = 6; slotsLeft >= 1; slotsLeft -= 1) {
    const block = LEGACY_BOWL_FACTORIALS[slotsLeft - 1];
    const q = residual / block;
    residual %= block;
    order.push(remaining.splice(Number(q), 1)[0]);
  }
  return order;
}

function legacyBowlOrderFromDrop(drop) {
  if (typeof drop !== 'bigint') {
    throw new TypeError('Un drop por li permutation legacy deve esser un BigInt exact.');
  }
  const oneBased = regularMod(drop - 1n, 720n) + 1n;
  // Li caller historic confunde li ordinal 1..720 con li contract rank0 0..719.
  return oldPermutationUnrank0(oneBased);
}

function orderPatchFromValue(value) {
  if (typeof value !== 'bigint') {
    throw new TypeError('Un valore por li permutation reparat deve esser un BigInt exact.');
  }
  const oneBased = regularMod(value - 1n, 720n) + 1n;
  // Li helper legacy resta intact: li defect es in li caller, ne in oldPermutationUnrank0.
  const legacyRank0 = oneBased - 1n;
  // Li bridge -1 ... +1 ... -1 resta intentionalmen visibil e rende exactmen li rank0 normativ.
  return oldPermutationUnrank0(legacyRank0);
}

function legacyPoursToFixedBowlIds(drop, index, oldBowls, stoneRow) {
  if (typeof drop !== 'bigint' || typeof index !== 'bigint') {
    throw new TypeError('Li drop e su index por pours legacy deve esser BigInt exact.');
  }
  if (index < 1n || index > 46n) {
    throw new RangeError('Li index legacy del visible drop deve esser inter 1 e 46.');
  }
  if (!Array.isArray(oldBowls) || oldBowls.length < 7) {
    throw new TypeError('Li bowls legacy deve conservar indices 1..6.');
  }
  for (let id = 1; id <= 6; id += 1) {
    if (typeof oldBowls[id] !== 'bigint') {
      throw new TypeError('Chascun bowl legacy deve esser un BigInt exact.');
    }
  }
  if (!stoneRow || typeof stoneRow.w !== 'bigint' || typeof stoneRow.b !== 'bigint' || typeof stoneRow.s !== 'bigint') {
    throw new TypeError('Li row legacy de stones deve contener w, b e s quam BigInt.');
  }
  const order = orderPatchFromValue(drop);
  const pours = [null, 0n, 0n, 0n, 0n, 0n, 0n];
  // Li scar historic ignora li IDs in order por li tri pours e tracta positions 1,2,3 quam bowls fix 1,2,3.
  pours[1] = savePatch(drop * drop + stoneRow.w * oldBowls[1] + 3n * index);
  pours[2] = savePatch(drop * drop + stoneRow.b * oldBowls[2] + 5n * index);
  pours[3] = savePatch(drop * drop + stoneRow.s * oldBowls[3] + 7n * index);
  return { order, pours };
}

function installBowlAlias(order) {
  if (!Array.isArray(order) || order.length !== 6) {
    throw new TypeError('Li order de bowls por alias deve contener exactmen six IDs.');
  }
  const seen = new Set();
  const bowlAlias = new Array(7).fill(null);
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    if (!Number.isInteger(bowlId) || bowlId < 1 || bowlId > 6 || seen.has(bowlId)) {
      throw new RangeError('Li order de bowls deve esser un permutation exact de IDs 1..6.');
    }
    seen.add(bowlId);
    // Ti scar deve restar explicit: li position historic es traductet al bowl ID current per bowlAlias[position].
    bowlAlias[position] = bowlId;
  }
  return bowlAlias;
}

function bowlAtLegacyPosition(oldBowls, bowlAlias, position) {
  if (!Number.isInteger(position) || position < 1 || position > 6) {
    throw new RangeError('Li position legacy de bowl deve esser inter 1 e 6.');
  }
  if (!Array.isArray(oldBowls) || oldBowls.length < 7 || !Array.isArray(bowlAlias) || bowlAlias.length < 7) {
    throw new TypeError('Li bowls e bowlAlias deve conservar indices 1..6.');
  }
  const bowlId = bowlAlias[position];
  if (!Number.isInteger(bowlId) || bowlId < 1 || bowlId > 6 || typeof oldBowls[bowlId] !== 'bigint') {
    throw new TypeError('Li alias de bowl deve resolver a un bowl BigInt valid.');
  }
  return oldBowls[bowlId];
}

function poursThroughBowlAlias(drop, index, oldBowls, stoneRow) {
  // Li routine legacy resta intact e es realmen vocat; su pours fix es conservabil quam scar ma ne decide li output semantic.
  const garbage = legacyPoursToFixedBowlIds(drop, index, oldBowls, stoneRow);
  const order = garbage.order.slice();
  const bowlAlias = installBowlAlias(order);
  const pours = garbage.pours.slice();
  // Li defect legacy ne es correctet in-place: chascun read semantic de bowl passa explicitmen per bowlAlias[position].
  pours[1] = savePatch(drop * drop + stoneRow.w * bowlAtLegacyPosition(oldBowls, bowlAlias, 1) + 3n * index);
  pours[2] = savePatch(drop * drop + stoneRow.b * bowlAtLegacyPosition(oldBowls, bowlAlias, 2) + 5n * index);
  pours[3] = savePatch(drop * drop + stoneRow.s * bowlAtLegacyPosition(oldBowls, bowlAlias, 3) + 7n * index);
  return { order, bowlAlias, pours };
}

const BOWL_STIR_STONE_BY_POSITION_LEGACY = Object.freeze([null, 'w', 'b', 's', 'm', 'r', 'w']);

function legacyStirOneDropInPlace(drop, index, bowls, stoneRow) {
  if (typeof drop !== 'bigint' || typeof index !== 'bigint') {
    throw new TypeError('Li drop e su index por li bowl-round legacy deve esser BigInt exact.');
  }
  if (index < 1n || index > 46n) {
    throw new RangeError('Li index legacy del bowl-round deve esser inter 1 e 46.');
  }
  if (!Array.isArray(bowls) || bowls.length < 7) {
    throw new TypeError('Li bowls legacy del round deve conservar indices 1..6.');
  }
  for (let id = 1; id <= 6; id += 1) {
    if (typeof bowls[id] !== 'bigint') {
      throw new TypeError('Chascun bowl del round legacy deve esser un BigInt exact.');
    }
  }
  if (!stoneRow || typeof stoneRow !== 'object') {
    throw new TypeError('Li row de stones por li bowl-round legacy deve esser un object.');
  }
  for (const key of ['w', 'b', 's', 'm', 'r']) {
    if (typeof stoneRow[key] !== 'bigint') {
      throw new TypeError('Li row de stones por li bowl-round legacy deve contener quin BigInt.');
    }
  }
  const poured = poursThroughBowlAlias(drop, index, bowls, stoneRow);
  const order = poured.order.slice();
  const pours = poured.pours.slice();
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    const prevId = order[(position + 4) % 6];
    const nextId = order[position % 6];
    const stoneKind = BOWL_STIR_STONE_BY_POSITION_LEGACY[position];
    // Li scar historic scri directmen in bowls; li passus posterior lee dunque valores ja mutat del sam round.
    const s = bowls[bowlId]
      + 2n * bowls[prevId]
      + 3n * bowls[nextId]
      + pours[position]
      + drop
      + stoneRow[stoneKind];
    bowls[bowlId] = savePatch(
      s * s
      + 5n * bowls[prevId] * bowls[nextId]
      + index * BigInt(position)
    );
  }
  return { order, pours, bowls };
}

function stirOneDropViaShadow(drop, index, bowls, stoneRow) {
  if (typeof drop !== 'bigint' || typeof index !== 'bigint') {
    throw new TypeError('Li drop e su index por li bowl-round reparat deve esser BigInt exact.');
  }
  if (index < 1n || index > 46n) {
    throw new RangeError('Li index reparat del bowl-round deve esser inter 1 e 46.');
  }
  if (!Array.isArray(bowls) || bowls.length < 7) {
    throw new TypeError('Li bowls del round reparat deve conservar indices 1..6.');
  }
  for (let id = 1; id <= 6; id += 1) {
    if (typeof bowls[id] !== 'bigint') {
      throw new TypeError('Chascun bowl del round reparat deve esser un BigInt exact.');
    }
  }
  if (!stoneRow || typeof stoneRow !== 'object') {
    throw new TypeError('Li row de stones por li bowl-round reparat deve esser un object.');
  }
  for (const key of ['w', 'b', 's', 'm', 'r']) {
    if (typeof stoneRow[key] !== 'bigint') {
      throw new TypeError('Li row de stones por li bowl-round reparat deve contener quin BigInt.');
    }
  }

  // Li helper legacy resta intact e es realmen executet sur un clone separat; su contamination resta observabil quam garbage historic.
  const legacyGarbage = legacyStirOneDropInPlace(drop, index, bowls.slice(), stoneRow);
  // Patch 10 exige un snapshot fisic. Omni read semantic posterior veni exclusivmen ex vaultOld.
  const vaultOld = bowls.slice();
  const poured = poursThroughBowlAlias(drop, index, vaultOld, stoneRow);
  const order = poured.order.slice();
  const pours = poured.pours.slice();
  // Null output es commitet durante li loop: omni six writes va solmen in pending.
  const pending = new Array(7).fill(null);
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    const prevId = order[(position + 4) % 6];
    const nextId = order[position % 6];
    const stoneKind = BOWL_STIR_STONE_BY_POSITION_LEGACY[position];
    const s = vaultOld[bowlId]
      + 2n * vaultOld[prevId]
      + 3n * vaultOld[nextId]
      + pours[position]
      + drop
      + stoneRow[stoneKind];
    pending[bowlId] = savePatch(
      s * s
      + 5n * vaultOld[prevId] * vaultOld[nextId]
      + index * BigInt(position)
    );
  }
  // Li commit semantic evene solmen pos que omni six positions ha plenat pending.
  const committed = pending.slice();
  return {
    order,
    pours,
    vaultOld,
    pending,
    bowls: committed,
    legacyGarbage: {
      order: legacyGarbage.order.slice(),
      pours: legacyGarbage.pours.slice(),
      bowls: legacyGarbage.bowls.slice()
    }
  };
}

const DISCOVERY11_BOWL_PRIMES = Object.freeze([null, 17n, 19n, 23n, 29n, 31n, 37n]);

function initialBowlsForOrderMemoryDiscovery(counts) {
  if (!counts || typeof counts !== 'object') {
    throw new TypeError('Li comptes por li bowls inicial deve esser un object exact.');
  }
  for (const key of ['action', 'target', 'distance', 'connection', 'direction']) {
    if (typeof counts[key] !== 'bigint') {
      throw new TypeError('Li comptes por li bowls inicial deve contener BigInt exact.');
    }
  }
  const bowls = new Array(7).fill(null);
  for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
    const prime = DISCOVERY11_BOWL_PRIMES[bowlId];
    const seed = counts.action
      + counts.target * BigInt(bowlId)
      + counts.distance
      + counts.connection
      + counts.direction
      + prime * prime;
    bowls[bowlId] = savePatch(seed * seed + BigInt(bowlId));
  }
  return bowls;
}

function visibleDropThroughCurrentLayers(index, counts, stones, dropStore, legacyHidden) {
  if (!Number.isInteger(index) || index < 1 || index > 46) {
    throw new RangeError('Li index del visible drop complet deve esser inter 1 e 46.');
  }
  if (!Array.isArray(stones) || stones.length < 46) {
    throw new TypeError('Li table complet de stones deve contener 46 rows.');
  }
  const row = stones[index - 1];
  if (!row || typeof row !== 'object') {
    throw new TypeError('Li row del visible drop deve esser un object de stones.');
  }
  const prev1 = priorPatch(dropStore, legacyHidden, index, 1);
  const prev3 = priorPatch(dropStore, legacyHidden, index, 3);
  const prev7 = priorPatch(dropStore, legacyHidden, index, 7);
  let x = savePatch(
    row.w * counts.action
    + row.b * counts.target
    + row.s * counts.distance
    + row.m * counts.connection
    + row.r * counts.direction
    + prev1
    + 3n * prev3
    + 5n * prev7
    + BigInt(index)
  );
  for (let grind = 1; grind <= 11; grind += 1) {
    const rule = grindRowWithSentinel(grind);
    const oldX = x;
    x = savePatch(
      oldX * oldX
      + rule.a * oldX
      + rule.b * prev1
      + rule.c * prev3
      + rule.d * prev7
      + row[rule.kind]
    );
  }
  return x;
}

function postStirOneForOrderMemoryDiscovery(stirNumber, bowls) {
  if (!Number.isInteger(stirNumber) || stirNumber < 1 || stirNumber > 12) {
    throw new RangeError('Li ordinal del post-stir deve esser inter 1 e 12.');
  }
  if (!Array.isArray(bowls) || bowls.length < 7) {
    throw new TypeError('Li bowls del post-stir deve conservar indices 1..6.');
  }
  const old = bowls.slice();
  let rawSum = 0n;
  for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
    if (typeof old[bowlId] !== 'bigint') {
      throw new TypeError('Chascun bowl del post-stir deve esser un BigInt exact.');
    }
    rawSum += old[bowlId];
  }
  const savedStirSum = savePatch(rawSum + 149n * BigInt(stirNumber));
  const order = orderPatchFromValue(savedStirSum);
  const pending = new Array(7).fill(null);
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    const prevId = order[(position + 4) % 6];
    const nextId = order[position % 6];
    const z = old[bowlId]
      + 3n * old[prevId]
      + 5n * old[nextId]
      + savedStirSum
      + BigInt(stirNumber)
      + BigInt(position * position);
    pending[bowlId] = savePatch(z * z + 7n * old[prevId] * old[nextId]);
  }
  return { bowls: pending.slice(), order: order.slice(), savedStirSum };
}

function createStage56PostStirContext() {
  return {
    oldResult: null,
    correctedResult: null,
    rawBowlSum: null,
    savedOrderNumber: null,
    stirIndex: 0,
    appliedCount: 0,
    appliedFlag: false,
    legacyScarCallCount: 0,
    history: []
  };
}

function snapshotStage56PostStirContext(context) {
  if (!context || typeof context !== 'object') {
    throw new TypeError('Li context de Stage 56 deve esser un object invocation-local.');
  }
  return Object.freeze({
    oldResult: context.oldResult,
    correctedResult: context.correctedResult,
    rawBowlSum: context.rawBowlSum,
    savedOrderNumber: context.savedOrderNumber,
    stirIndex: context.stirIndex,
    appliedCount: context.appliedCount,
    appliedFlag: context.appliedFlag,
    legacyScarCallCount: context.legacyScarCallCount,
    history: Object.freeze(context.history.slice())
  });
}

function stage56RawBowlSumPostStirDetour(stirNumber, bowls, legacyRound, context) {
  if (!Number.isInteger(stirNumber) || stirNumber < 1 || stirNumber > 12) {
    throw new RangeError('Li ordinal del detour Stage 56 deve esser inter 1 e 12.');
  }
  if (!Array.isArray(bowls) || bowls.length < 7) {
    throw new TypeError('Li detour Stage 56 exige six bowls in indices 1..6.');
  }
  if (!legacyRound || !Array.isArray(legacyRound.bowls) || !Array.isArray(legacyRound.order) ||
      typeof legacyRound.savedStirSum !== 'bigint') {
    throw new TypeError('Li detour Stage 56 exige li resultate real del scar legacy precedent.');
  }
  if (!context || typeof context !== 'object' || !Array.isArray(context.history)) {
    throw new TypeError('Li detour Stage 56 exige un context invocation-local explicit.');
  }
  const old = bowls.slice();
  let rawBowlSum = 0n;
  for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
    if (typeof old[bowlId] !== 'bigint') {
      throw new TypeError('Chascun bowl del detour Stage 56 deve esser un BigInt exact.');
    }
    rawBowlSum += old[bowlId];
  }
  const savedOrderNumber = savePatch(rawBowlSum + 149n * BigInt(stirNumber));
  const order = orderPatchFromValue(savedOrderNumber);
  if (legacyRound.savedStirSum !== savedOrderNumber || !stage54ArraysEqual(legacyRound.order, order)) {
    throw new BootstrapStageError('Stage 56 refusa mutar orderNumber o permutation; solmen rawBowlSum posse diferer in u.');
  }
  const pending = new Array(7).fill(null);
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    const prevId = order[(position + 4) % 6];
    const nextId = order[position % 6];
    const u = old[bowlId]
      + 3n * old[prevId]
      + 5n * old[nextId]
      + rawBowlSum
      + BigInt(stirNumber)
      + BigInt(position * position);
    pending[bowlId] = savePatch(u * u + 7n * old[prevId] * old[nextId]);
  }
  const oldResult = Object.freeze({
    bowls: Object.freeze(legacyRound.bowls.slice()),
    order: Object.freeze(legacyRound.order.slice()),
    savedOrderNumber: legacyRound.savedStirSum
  });
  const correctedResult = Object.freeze({
    bowls: Object.freeze(pending.slice()),
    order: Object.freeze(order.slice()),
    savedOrderNumber
  });
  const historyRow = Object.freeze({
    oldResult,
    correctedResult,
    rawBowlSum,
    savedOrderNumber,
    stirIndex: stirNumber,
    appliedCount: context.appliedCount + 1,
    appliedFlag: true,
    legacyScarCallCount: context.legacyScarCallCount
  });
  context.oldResult = oldResult;
  context.correctedResult = correctedResult;
  context.rawBowlSum = rawBowlSum;
  context.savedOrderNumber = savedOrderNumber;
  context.stirIndex = stirNumber;
  context.appliedCount += 1;
  context.appliedFlag = true;
  context.history.push(historyRow);
  return { bowls: pending.slice(), order: order.slice(), rawBowlSum, savedOrderNumber };
}

function legacySauceWithOverwritableOrderMemory(counts, stones) {
  if (!counts || typeof counts !== 'object' || !Array.isArray(stones) || stones.length < 46) {
    throw new TypeError('Li path legacy de order-memory exige comptes e 46 rows de stones.');
  }
  const legacyHidden = buildHiddenWithBackwardStorage(counts, stones);
  const drops = new Array(47).fill(null);
  let bowls = initialBowlsForOrderMemoryDiscovery(counts);
  let legacyOrderMemory = null;
  let orderWriteCount = 0;
  let lastSource = null;
  let drop46OrderDiagnostic = null;

  for (let index = 1; index <= 46; index += 1) {
    const drop = visibleDropThroughCurrentLayers(index, counts, stones, drops, legacyHidden);
    drops[index] = drop;
    const round = stirOneDropViaShadow(drop, BigInt(index), bowls, stones[index - 1]);
    bowls = round.bowls.slice();
    // Li scar de Discovery 11 usa un unic memorie general: chascun drop superscri li order anterior.
    legacyOrderMemory = round.order.slice();
    orderWriteCount += 1;
    lastSource = { kind: 'drop', ordinal: index };
    if (index === 46) {
      // Ti copie es diagnostic solmen; li query semantic legacy ne lee it.
      drop46OrderDiagnostic = round.order.slice();
    }
  }

  const bowlsAfterDrops = bowls.slice();
  let lastPostStirOrder = null;
  let lastPostStirSavedSum = null;
  for (let stir = 1; stir <= 12; stir += 1) {
    const round = postStirOneForOrderMemoryDiscovery(stir, bowls);
    bowls = round.bowls.slice();
    // Li sam memorie general es superscrit denov per chascun post-stir; li order de drop 46 es dunque perdit por query.
    legacyOrderMemory = round.order.slice();
    orderWriteCount += 1;
    lastSource = { kind: 'post-stir', ordinal: stir };
    lastPostStirOrder = round.order.slice();
    lastPostStirSavedSum = round.savedStirSum;
  }

  return {
    hiddenBackward: legacyHidden.slice(),
    drops: drops.slice(),
    bowlsAfterDrops,
    bowls: bowls.slice(),
    drop46OrderDiagnostic: drop46OrderDiagnostic.slice(),
    lastPostStirOrder: lastPostStirOrder.slice(),
    lastPostStirSavedSum,
    legacyOrderMemory: legacyOrderMemory.slice(),
    orderWriteCount,
    lastSource,
    queryOrder: legacyOrderMemory.slice()
  };
}

function createOrderAt46LatchState() {
  return { orderAt46Latch: null, writeCount: 0, source: null };
}

function writeOrderAt46LatchOnce(latchState, order) {
  if (!latchState || typeof latchState !== 'object') {
    throw new TypeError('Li statu del latch de order 46 deve esser un object invocation-local.');
  }
  if (!Array.isArray(order) || order.length !== 6) {
    throw new TypeError('Li order por li latch de drop 46 deve contener exactmen six bowl IDs.');
  }
  if (latchState.orderAt46Latch !== null || latchState.writeCount !== 0) {
    throw new BootstrapStageError('Li latch de order 46 es single-write e ne posse esser superscrit.');
  }
  // Li scar legacy resta separat: ti latch nasce exactmen un vez, pos drop 46 e ante li prim post-stir.
  latchState.orderAt46Latch = order.slice();
  latchState.writeCount = 1;
  latchState.source = { kind: 'drop', ordinal: 46 };
  return latchState.orderAt46Latch.slice();
}

function readOrderAt46Latch(latchState) {
  if (!latchState || !Array.isArray(latchState.orderAt46Latch) || latchState.writeCount !== 1) {
    throw new BootstrapStageError('Li latch de order 46 ne contene ancor un valore valid single-write.');
  }
  return latchState.orderAt46Latch.slice();
}

function sauceWithOrderAt46Latch(counts, stones) {
  if (!counts || typeof counts !== 'object' || !Array.isArray(stones) || stones.length < 46) {
    throw new TypeError('Li path reparat de order-latch exige comptes e 46 rows de stones.');
  }

  // Li call legacy resta real e intentional; su query superscrit es conservat quam garbage historic.
  const legacyGarbage = legacySauceWithOverwritableOrderMemory(counts, stones);
  const legacyHidden = buildHiddenWithBackwardStorage(counts, stones);
  const drops = new Array(47).fill(null);
  let bowls = initialBowlsForOrderMemoryDiscovery(counts);
  let legacyOrderMemory = null;
  let orderWriteCount = 0;
  let lastSource = null;
  const latchState = createOrderAt46LatchState();

  for (let index = 1; index <= 46; index += 1) {
    const drop = visibleDropThroughCurrentLayers(index, counts, stones, drops, legacyHidden);
    drops[index] = drop;
    const round = stirOneDropViaShadow(drop, BigInt(index), bowls, stones[index - 1]);
    bowls = round.bowls.slice();
    // Li memorie legacy continua esser superscrit e resta un scar separat del latch semantic.
    legacyOrderMemory = round.order.slice();
    orderWriteCount += 1;
    lastSource = { kind: 'drop', ordinal: index };
    if (index === 46) {
      writeOrderAt46LatchOnce(latchState, round.order);
    }
  }

  const bowlsAfterDrops = bowls.slice();
  const orderAt46BeforePostStirs = readOrderAt46Latch(latchState);
  let lastPostStirOrder = null;
  let lastPostStirSavedSum = null;
  for (let stir = 1; stir <= 12; stir += 1) {
    const round = postStirOneForOrderMemoryDiscovery(stir, bowls);
    bowls = round.bowls.slice();
    // Post-stirs continua mutar solmen li memorie legacy; li latch single-write ne es tocat plu.
    legacyOrderMemory = round.order.slice();
    orderWriteCount += 1;
    lastSource = { kind: 'post-stir', ordinal: stir };
    lastPostStirOrder = round.order.slice();
    lastPostStirSavedSum = round.savedStirSum;
  }

  return {
    legacyGarbage: {
      bowls: legacyGarbage.bowls.slice(),
      drop46OrderDiagnostic: legacyGarbage.drop46OrderDiagnostic.slice(),
      lastPostStirOrder: legacyGarbage.lastPostStirOrder.slice(),
      legacyOrderMemory: legacyGarbage.legacyOrderMemory.slice(),
      orderWriteCount: legacyGarbage.orderWriteCount,
      lastSource: { ...legacyGarbage.lastSource },
      queryOrder: legacyGarbage.queryOrder.slice()
    },
    hiddenBackward: legacyHidden.slice(),
    drops: drops.slice(),
    bowlsAfterDrops,
    bowls: bowls.slice(),
    orderAt46Latch: readOrderAt46Latch(latchState),
    orderAt46BeforePostStirs,
    orderAt46LatchWriteCount: latchState.writeCount,
    orderAt46LatchSource: { ...latchState.source },
    lastPostStirOrder: lastPostStirOrder.slice(),
    lastPostStirSavedSum,
    legacyOrderMemory: legacyOrderMemory.slice(),
    orderWriteCount,
    lastSource: { ...lastSource },
    queryOrder: readOrderAt46Latch(latchState)
  };
}

function oldNextBowlFixedName(id) {
  if (!Number.isInteger(id) || id < 1 || id > 6) {
    throw new RangeError('Li ID legacy de bowl deve esser un integer inter 1 e 6.');
  }
  // Li scar historic ignora li position latchet e avansa solmen sur li ring numeric fix de IDs.
  return id === 6 ? 1 : id + 1;
}

function sauceWithStage56RawBowlSumDetour(counts, stones) {
  if (!counts || typeof counts !== 'object' || !Array.isArray(stones) || stones.length < 46) {
    throw new TypeError('Li sauce corrective Stage 56 exige comptes e 46 rows de stones.');
  }
  // Li sauce historic complet resta real e deven un ghost. Su post-stirs ne es mutat in loco.
  const historical = sauceWithOrderAt46Latch(counts, stones);
  let bowls = historical.bowlsAfterDrops.slice();
  const stage56Context = createStage56PostStirContext();
  let lastOrder = null;
  let lastSavedOrderNumber = null;
  for (let stir = 1; stir <= 12; stir += 1) {
    const sourceSnapshot = bowls.slice();
    // Li scar legacy es vocat realmen ante chascun detour e su resultate resta quam witness.
    const legacyRound = postStirOneForOrderMemoryDiscovery(stir, sourceSnapshot);
    stage56Context.legacyScarCallCount += 1;
    const correctedRound = stage56RawBowlSumPostStirDetour(stir, sourceSnapshot, legacyRound, stage56Context);
    bowls = correctedRound.bowls.slice();
    lastOrder = correctedRound.order.slice();
    lastSavedOrderNumber = correctedRound.savedOrderNumber;
  }
  if (stage56Context.appliedCount !== 12 || stage56Context.legacyScarCallCount !== 12 ||
      stage56Context.stirIndex !== 12 || stage56Context.history.length !== 12) {
    throw new BootstrapStageError('Stage 56 deve aplicar exactmen 12 detours pos 12 calls legacy.');
  }
  return {
    ...historical,
    bowls: bowls.slice(),
    lastPostStirOrder: lastOrder.slice(),
    lastPostStirSavedSum: lastSavedOrderNumber,
    stage56HistoricalBowls: historical.bowls.slice(),
    stage56HistoricalLastPostStirOrder: historical.lastPostStirOrder.slice(),
    stage56PostStirContext: snapshotStage56PostStirContext(stage56Context),
    stage56RawBowlSumApplied: true
  };
}

function nextBowlFromOrderAt46Latch(orderAt46Latch, queriedBowlId) {
  if (!Array.isArray(orderAt46Latch) || orderAt46Latch.length !== 6) {
    throw new TypeError('Li orderAt46Latch por next-bowl deve contener exactmen six bowl IDs.');
  }
  if (!Number.isInteger(queriedBowlId) || queriedBowlId < 1 || queriedBowlId > 6) {
    throw new RangeError('Li ID questionat por next-bowl deve esser un integer inter 1 e 6.');
  }
  const seen = new Set();
  for (const id of orderAt46Latch) {
    if (!Number.isInteger(id) || id < 1 || id > 6 || seen.has(id)) {
      throw new RangeError('Li orderAt46Latch deve esser un permutation valid de bowl IDs 1..6.');
    }
    seen.add(id);
  }
  const position = orderAt46Latch.indexOf(queriedBowlId);
  if (position < 0) {
    throw new BootstrapStageError('Li bowl questionat manca ex orderAt46Latch.');
  }
  // Li successor semantic es positional e circular; li wrap del ultim position retorna al prim.
  return orderAt46Latch[(position + 1) % orderAt46Latch.length];
}

function answerRingFromCurrentState(bowls, queriedBowlId, nextBowlId, seal) {
  if (!Array.isArray(bowls) || bowls.length < 7) {
    throw new TypeError('Li statu de bowls por answer ring deve conservar indices 1..6.');
  }
  for (let id = 1; id <= 6; id += 1) {
    if (typeof bowls[id] !== 'bigint') {
      throw new TypeError('Chascun bowl por answer ring deve esser un BigInt exact.');
    }
  }
  if (!Number.isInteger(queriedBowlId) || queriedBowlId < 1 || queriedBowlId > 6 ||
      !Number.isInteger(nextBowlId) || nextBowlId < 1 || nextBowlId > 6) {
    throw new RangeError('Li bowl questionat e su successor deve esser IDs inter 1 e 6.');
  }
  if (typeof seal !== 'bigint') {
    throw new TypeError('Li seal del answer ring deve esser un BigInt exact.');
  }
  const firstBase = bowls[queriedBowlId] + seal + 181n;
  const first = savePatch(firstBase * firstBase + 179n * bowls[nextBowlId] + seal);
  const directionBase = first + seal + 1n + 193n;
  const directionNumber = savePatch(
    directionBase * directionBase + 193n * first + 197n * bowls[6]
  );
  const directionStep = regularMod(directionNumber, 2n) === 1n ? 1n : -1n;
  return { first, directionStep };
}

function ringAnswerAt(stream, offset) {
  if (!stream || typeof stream.first !== 'bigint' || typeof stream.directionStep !== 'bigint') {
    throw new TypeError('Li answer ring legacy deve contener first e directionStep exact.');
  }
  if (stream.first < 1n || stream.first > M_OLD ||
      (stream.directionStep !== 1n && stream.directionStep !== -1n)) {
    throw new RangeError('Li answer ring legacy es extra su contract.');
  }
  if (typeof offset !== 'bigint' || offset < 0n) {
    throw new RangeError('Li offset del answer ring legacy deve esser un BigInt non-negativ.');
  }
  return 1n + regularMod(stream.first - 1n + stream.directionStep * offset, M_OLD);
}

function biasedLegacyPick(x, N) {
  if (typeof x !== 'bigint' || typeof N !== 'bigint') {
    throw new TypeError('Li selector legacy exige x e N quam BigInt exact.');
  }
  if (x < 1n || N < 1n) {
    throw new RangeError('Li selector legacy exige x e N positiv.');
  }
  // Li scar historic fa directmen modulo e ne executa null rejection ante li mapping al familie.
  return regularMod(x - 1n, N) + 1n;
}

function legacySelectionAssumingNLeM(stream, N) {
  // Li dispatcher historic manca: it presume que omni familie es curt e invia N directmen al selector reparat de Patch 13.
  return patchedSmallPick(stream, N);
}

function patchedSmallPick(stream, N) {
  if (!stream || typeof stream.first !== 'bigint' || typeof stream.directionStep !== 'bigint') {
    throw new TypeError('Li selector curt reparat exige un answer ring exact.');
  }
  if (stream.first < 1n || stream.first > M_OLD ||
      (stream.directionStep !== 1n && stream.directionStep !== -1n)) {
    throw new RangeError('Li answer ring del selector curt es extra su contract.');
  }
  if (typeof N !== 'bigint') {
    throw new TypeError('Li grandore del familie curt reparat deve esser un BigInt exact.');
  }
  if (N < 1n || N > M_OLD) {
    throw new RangeError('Li familie curt reparat deve haver un grandore inter 1 e M.');
  }
  const limit = (M_OLD / N) * N;
  let offset = 0n;
  let x = ringAnswerAt(stream, offset);
  while (x > limit) {
    offset += 1n;
    x = ringAnswerAt(stream, offset);
  }
  // Li helper legacy resta intact e es vocat solmen pos que li rejection ha removet li modulo bias.
  return biasedLegacyPick(x, N);
}

function wideDetour(stream, N) {
  if (!stream || typeof stream.first !== 'bigint' || typeof stream.directionStep !== 'bigint') {
    throw new TypeError('Li detour wide exige un answer ring exact.');
  }
  if (stream.first < 1n || stream.first > M_OLD ||
      (stream.directionStep !== 1n && stream.directionStep !== -1n)) {
    throw new RangeError('Li answer ring del detour wide es extra su contract.');
  }
  if (typeof N !== 'bigint') {
    throw new TypeError('Li grandore del familie wide deve esser un BigInt exact.');
  }
  if (N <= M_OLD) {
    throw new RangeError('Li detour wide exige un familie plu grand quam M.');
  }
  let places = 1;
  let space = M_OLD;
  while (space < N) {
    places += 1;
    space *= M_OLD;
  }
  const digits = [];
  let wide = 1n;
  let weight = 1n;
  for (let j = 0; j < places; j += 1) {
    const digit = ringAnswerAt(stream, BigInt(j)) - 1n;
    digits.push(digit);
    wide += digit * weight;
    weight *= M_OLD;
  }
  const initialWide = wide;
  const acceptanceLimit = (space / N) * N;
  let rejectionSteps = 0n;
  // Pos li construction unic del digits, rejection avansa solmen li numero wide combinat; null answer nov es demandat.
  while (wide > acceptanceLimit) {
    wide = 1n + regularMod(wide - 1n + stream.directionStep, space);
    rejectionSteps += 1n;
  }
  return {
    mode: 'wide',
    output: regularMod(wide - 1n, N) + 1n,
    places,
    space,
    digits,
    digitReadCount: places,
    initialWide,
    acceptanceLimit,
    acceptedWide: wide,
    rejectionSteps
  };
}

function selectionDispatcherWithWideDetour(stream, N) {
  if (typeof N !== 'bigint') {
    throw new TypeError('Li dispatcher de selection exige un familie quam BigInt exact.');
  }
  if (N < 1n) {
    throw new RangeError('Li dispatcher de selection exige un familie positiv.');
  }
  if (N <= M_OLD) {
    return {
      mode: 'short',
      output: patchedSmallPick(stream, N),
      places: null,
      space: null,
      digits: null,
      digitReadCount: 0,
      initialWide: null,
      acceptanceLimit: null,
      acceptedWide: null,
      rejectionSteps: 0n
    };
  }
  return wideDetour(stream, N);
}

function oldGateQuestionDay(n) {
  if (typeof n !== 'bigint') {
    throw new TypeError('Li ordinal legacy del question de gate deve esser un BigInt exact.');
  }
  if (n < 0n) {
    throw new RangeError('Li ordinal legacy del question de gate ne posse esser negativ.');
  }
  // Li scar historic conosse solmen li latere positiv e adjunte sempre li magnitude al Foundation.
  return FOUNDATION_DAY_OLD + n;
}

function gateQuestionWithSignedStep(signedStep) {
  if (typeof signedStep !== 'bigint') {
    throw new TypeError('Li passu signat reparat de gate deve esser un BigInt exact.');
  }
  const magnitude = signedStep < 0n ? -signedStep : signedStep;
  // Li helper legacy resta intact e es vocat realmen; su question positiv es li scar initial del wrapper.
  let q = oldGateQuestionDay(magnitude);
  // Patch 15 devia exclusivmen li passus negativ al latere negativ del Foundation.
  if (signedStep < 0n) {
    q = FOUNDATION_DAY_OLD - magnitude;
  }
  return q;
}

const LEGACY_YEAR_MAX = 5781n;
const REAL_YEAR_MAX_PATCH = 5778n;

function legacyYearCandidateAllowed(gates, openIndex, closeIndex) {
  if (!gates || typeof gates !== 'object') {
    throw new TypeError('Li storage legacy de gates por year candidate deve esser un object indexabil.');
  }
  if (!Number.isInteger(openIndex) || !Number.isInteger(closeIndex) || closeIndex <= openIndex) {
    throw new RangeError('Li indices legacy del year candidate deve esser integers con closeIndex>openIndex.');
  }
  const openGate = gates[openIndex];
  const closeGate = gates[closeIndex];
  if (typeof openGate !== 'bigint' || typeof closeGate !== 'bigint') {
    throw new TypeError('Li gates terminal del year candidate legacy deve esser BigInt exact.');
  }
  const gapCount = closeIndex - openIndex;
  const candidateLength = closeGate - openGate;
  // Li scar historic conserva 5781 quam ceiling real e lassa 5779..5781 passar al familie posterior.
  return gapCount >= 6 && candidateLength >= 252n && candidateLength <= LEGACY_YEAR_MAX;
}

function yearCandidateAfterFootnotePatch(gates, openIndex, closeIndex) {
  // Li helper legacy resta intact e es li prim porta real; Patch 16 ne muta LEGACY_YEAR_MAX.
  if (!legacyYearCandidateAllowed(gates, openIndex, closeIndex)) {
    return false;
  }
  const candidateLength = gates[closeIndex] - gates[openIndex];
  // Li footnote 5778 es un filter tardiv separat, ma deve preceder omni sort e selection semantic.
  if (candidateLength > REAL_YEAR_MAX_PATCH) {
    return false;
  }
  return true;
}

function legacyYearCandidatesBeforeSort(gates, candidatePairs) {
  if (!Array.isArray(candidatePairs)) {
    throw new TypeError('Li pares legacy de year candidates deve esser un array.');
  }
  const accepted = [];
  for (let ordinal = 0; ordinal < candidatePairs.length; ordinal += 1) {
    const pair = candidatePairs[ordinal];
    if (!pair || !Number.isInteger(pair.openIndex) || !Number.isInteger(pair.closeIndex)) {
      throw new TypeError('Chascun pare legacy de year candidate deve contener indices integers.');
    }
    if (!legacyYearCandidateAllowed(gates, pair.openIndex, pair.closeIndex)) {
      continue;
    }
    const openGate = gates[pair.openIndex];
    const closeGate = gates[pair.closeIndex];
    accepted.push({
      inputOrdinal: ordinal,
      openIndex: pair.openIndex,
      closeIndex: pair.closeIndex,
      openGate,
      closeGate,
      candidateLength: closeGate - openGate
    });
  }
  return accepted;
}

function legacyStableLengthOnlyYearCandidates(gates, candidatePairs) {
  const accepted = legacyYearCandidatesBeforeSort(gates, candidatePairs).map((candidate) => ({ ...candidate }));
  // Li sort legacy es intentionalmen solmen per longore e resta stabil por ties; Patch 17 ne es ancor present.
  accepted.sort((left, right) => {
    if (left.candidateLength < right.candidateLength) return -1;
    if (left.candidateLength > right.candidateLength) return 1;
    return 0;
  });
  return accepted;
}

function yearCandidatesAfterFootnotePatchBeforeSort(gates, candidatePairs) {
  if (!Array.isArray(candidatePairs)) {
    throw new TypeError('Li pares reparat de year candidates deve esser un array.');
  }
  const accepted = [];
  for (let ordinal = 0; ordinal < candidatePairs.length; ordinal += 1) {
    const pair = candidatePairs[ordinal];
    if (!pair || !Number.isInteger(pair.openIndex) || !Number.isInteger(pair.closeIndex)) {
      throw new TypeError('Chascun pare reparat de year candidate deve contener indices integers.');
    }
    if (!yearCandidateAfterFootnotePatch(gates, pair.openIndex, pair.closeIndex)) {
      continue;
    }
    const openGate = gates[pair.openIndex];
    const closeGate = gates[pair.closeIndex];
    accepted.push({
      inputOrdinal: ordinal,
      openIndex: pair.openIndex,
      closeIndex: pair.closeIndex,
      openGate,
      closeGate,
      candidateLength: closeGate - openGate
    });
  }
  return accepted;
}

function stableLengthOnlyPatchedYearCandidates(gates, candidatePairs) {
  // Li familie ja es filtrat per 5778 ante que ti copia entra in li sort.
  const accepted = yearCandidatesAfterFootnotePatchBeforeSort(gates, candidatePairs)
    .map((candidate) => ({ ...candidate }));
  // Patch 16 conserva intentionalmen li sort historic per longore solmen; li tie repair apartene a Patch 17.
  accepted.sort((left, right) => {
    if (left.candidateLength < right.candidateLength) return -1;
    if (left.candidateLength > right.candidateLength) return 1;
    return 0;
  });
  return accepted;
}

function floorDiv(a, b) {
  if (typeof a !== 'bigint' || typeof b !== 'bigint') {
    throw new TypeError('floorDiv exige du integers BigInt exact.');
  }
  if (b < 1n) {
    throw new RangeError('Li divisor de floorDiv deve esser positiv.');
  }
  let q = a / b;
  const r = a % b;
  if (r < 0n) q -= 1n;
  return q;
}

function oldJumpGuess(anchor, targetDay) {
  if (!anchor || typeof anchor !== 'object') {
    throw new TypeError('Li anchor legacy de year-jump deve esser un object.');
  }
  if (typeof anchor.number !== 'bigint' || typeof anchor.firstDay !== 'bigint' || typeof targetDay !== 'bigint') {
    throw new TypeError('Li jump legacy exige number, firstDay e targetDay quam BigInt exact.');
  }
  // Li scar historic usa 365 quam longore medie e salta directmen al numer de year estimat.
  return anchor.number + floorDiv(targetDay - anchor.firstDay, 365n);
}

function requireWalkYearRecord(year, label) {
  if (!year || typeof year !== 'object') {
    throw new TypeError(label + ' deve esser un object de year.');
  }
  for (const key of ['number', 'openDay', 'firstDay', 'closeDay']) {
    if (typeof year[key] !== 'bigint') {
      throw new TypeError(label + ' deve contener ' + key + ' quam BigInt exact.');
    }
  }
  if (year.firstDay !== year.openDay + 1n || year.closeDay < year.firstDay) {
    throw new RangeError(label + ' have un interval invalid.');
  }
  return { number: year.number, openDay: year.openDay, firstDay: year.firstDay, closeDay: year.closeDay };
}

function patchedNextYear(knownYear, nextYear) {
  const current = requireWalkYearRecord(knownYear, 'Li year current por nextYear');
  if (typeof nextYear !== 'function') {
    throw new TypeError('Patch 18 exige un callback nextYear por caminar un year exact.');
  }
  const candidate = requireWalkYearRecord(nextYear({ ...current }), 'Li year retornat per nextYear');
  if (candidate.number !== current.number + 1n) {
    throw new BootstrapStageError('nextYear deve avansar li numero exactmen per un.');
  }
  if (candidate.openDay !== current.closeDay) {
    throw new BootstrapStageError('nextYear deve compartir exactmen li gate de limite con li year current.');
  }
  return candidate;
}

function patchedPreviousYear(knownYear, previousYear) {
  const current = requireWalkYearRecord(knownYear, 'Li year current por previousYear');
  if (typeof previousYear !== 'function') {
    throw new TypeError('Patch 18 exige un callback previousYear por caminar un year exact.');
  }
  const candidate = requireWalkYearRecord(previousYear({ ...current }), 'Li year retornat per previousYear');
  if (candidate.number !== current.number - 1n) {
    throw new BootstrapStageError('previousYear deve recular li numero exactmen per un.');
  }
  if (candidate.closeDay !== current.openDay) {
    throw new BootstrapStageError('previousYear deve compartir exactmen li gate de limite con li year current.');
  }
  return candidate;
}

function findYearByWalkPatch(anchor, targetDay, nextYear, previousYear) {
  let current = requireWalkYearRecord(anchor, 'Li anchor por li caminada annual');
  if (typeof targetDay !== 'bigint') {
    throw new TypeError('Li target-day de Patch 18 deve esser un BigInt exact.');
  }
  const trace = [];
  while (targetDay > current.closeDay) {
    const before = current;
    current = patchedNextYear(current, nextYear);
    trace.push({
      direction: 'next',
      fromNumber: before.number,
      toNumber: current.number,
      sharedGate: before.closeDay
    });
  }
  while (targetDay <= current.openDay) {
    const before = current;
    current = patchedPreviousYear(current, previousYear);
    trace.push({
      direction: 'previous',
      fromNumber: before.number,
      toNumber: current.number,
      sharedGate: before.openDay
    });
  }
  if (!(current.openDay < targetDay && targetDay <= current.closeDay)) {
    throw new BootstrapStageError('Li caminada annual ne fini in un interval quel contene li target-day.');
  }
  const direction = trace.length === 0 ? 'anchor' : trace[0].direction;
  return { year: { ...current }, direction, stepCount: BigInt(trace.length), trace: trace.map((step) => ({ ...step })) };
}

function sortEqualLengthRunsByOpeningGate(list) {
  if (!Array.isArray(list)) {
    throw new TypeError('Li liste de year candidates por li tie patch deve esser un array ja sortat per longore.');
  }
  let start = 0;
  while (start < list.length) {
    const length = list[start].candidateLength;
    let end = start + 1;
    while (end < list.length && list[end].candidateLength === length) {
      end += 1;
    }
    if (end - start > 1) {
      // Li scar de longore ja ha fixat li position del run; Patch 17 toca solmen su interior.
      const run = list.slice(start, end);
      run.sort((left, right) => {
        if (left.openGate < right.openGate) return -1;
        if (left.openGate > right.openGate) return 1;
        return 0;
      });
      for (let offset = 0; offset < run.length; offset += 1) {
        list[start + offset] = run[offset];
      }
    }
    start = end;
  }
  return list;
}


class LegacyOverwritableOrderMemoryAdapter {
  call(counts, stones) {
    return legacySauceWithOverwritableOrderMemory(counts, stones);
  }
}

class Discovery11OverwrittenOrderHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, counts, stones) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireHiddenCounts(counts);
    this.validationManager.requireStoneTableForOrderMemory(stones);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery11OverwrittenOrderHandler';
    context.phase = 'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY';
    context.branchTrace.push('DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY');
    const result = this.legacyAdapter.call(counts, stones);
    context.legacyOrderMemory = result.legacyOrderMemory.slice();
    context.legacyOrderMemoryWriteCount = result.orderWriteCount;
    context.legacyOrderMemoryLastSource = { ...result.lastSource };
    context.legacyDrop46OrderDiagnostic = result.drop46OrderDiagnostic.slice();
    context.legacyLastPostStirOrder = result.lastPostStirOrder.slice();
    context.legacyLastPostStirSavedSum = result.lastPostStirSavedSum;
    context.legacyDiscovery11Drops = result.drops.slice();
    context.legacyDiscovery11BowlsAfterDrops = result.bowlsAfterDrops.slice();
    context.legacyDiscovery11FinalBowls = result.bowls.slice();
    context.legacyQueryOrder = result.queryOrder.slice();
    context.status = 'DISCOVERY_11_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery11.overwritableOrder.calls');
    return {
      bowls: result.bowls.slice(),
      drop46OrderDiagnostic: result.drop46OrderDiagnostic.slice(),
      lastPostStirOrder: result.lastPostStirOrder.slice(),
      lastPostStirSavedSum: result.lastPostStirSavedSum,
      legacyOrderMemory: result.legacyOrderMemory.slice(),
      orderWriteCount: result.orderWriteCount,
      lastSource: { ...result.lastSource },
      queryOrder: result.queryOrder.slice()
    };
  }
}

class Patch11OrderAt46LatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, counts, stones) {
    this.validationManager.requireDiscovery11Result(context);
    this.validationManager.requireHiddenCounts(counts);
    this.validationManager.requireStoneTableForOrderMemory(stones);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch11OrderAt46LatchWrapper';
    context.phase = 'PATCH_11_ORDER_AT_46_LATCH';
    context.branchTrace.push('PATCH_11_ORDER_AT_46_LATCH');
    const patched = sauceWithOrderAt46Latch(counts, stones);
    context.patch11LegacyCallPreserved = true;
    context.patch11LegacyGarbage = {
      bowls: patched.legacyGarbage.bowls.slice(),
      drop46OrderDiagnostic: patched.legacyGarbage.drop46OrderDiagnostic.slice(),
      lastPostStirOrder: patched.legacyGarbage.lastPostStirOrder.slice(),
      legacyOrderMemory: patched.legacyGarbage.legacyOrderMemory.slice(),
      orderWriteCount: patched.legacyGarbage.orderWriteCount,
      lastSource: { ...patched.legacyGarbage.lastSource },
      queryOrder: patched.legacyGarbage.queryOrder.slice()
    };
    context.patch11OrderAt46Latch = patched.orderAt46Latch.slice();
    context.patch11OrderAt46LatchWriteCount = patched.orderAt46LatchWriteCount;
    context.patch11OrderAt46LatchSource = { ...patched.orderAt46LatchSource };
    context.patch11LegacyOrderMemory = patched.legacyOrderMemory.slice();
    context.patch11LegacyOrderMemoryWriteCount = patched.orderWriteCount;
    context.patch11LegacyOrderMemoryLastSource = { ...patched.lastSource };
    context.patch11LastPostStirOrder = patched.lastPostStirOrder.slice();
    context.patch11FinalBowls = patched.bowls.slice();
    context.patch11QueryOrder = patched.queryOrder.slice();
    context.status = 'PATCH_11_RESULT';
    this.metricsManager.bump(context, 'patch11.orderAt46Latch.calls');
    return {
      bowls: patched.bowls.slice(),
      orderAt46Latch: patched.orderAt46Latch.slice(),
      orderAt46LatchWriteCount: patched.orderAt46LatchWriteCount,
      orderAt46LatchSource: { ...patched.orderAt46LatchSource },
      lastPostStirOrder: patched.lastPostStirOrder.slice(),
      lastPostStirSavedSum: patched.lastPostStirSavedSum,
      legacyOrderMemory: patched.legacyOrderMemory.slice(),
      orderWriteCount: patched.orderWriteCount,
      lastSource: { ...patched.lastSource },
      queryOrder: patched.queryOrder.slice()
    };
  }
}

class LegacyNextBowlAdapter {
  call(queriedBowlId) {
    return oldNextBowlFixedName(queriedBowlId);
  }
}

class Discovery12NextBowlHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, orderAt46Latch, queriedBowlId) {
    this.validationManager.requirePatch11Result(context);
    this.validationManager.requireLatchedBowlOrder(orderAt46Latch);
    this.validationManager.requireBowlId(queriedBowlId);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery12NextBowlHandler';
    context.phase = 'DISCOVERY_12_FIXED_ID_NEXT_BOWL';
    context.branchTrace.push('DISCOVERY_12_FIXED_ID_NEXT_BOWL');
    context.legacyNextBowlOrderAt46Latch = orderAt46Latch.slice();
    context.legacyNextBowlQueriedId = queriedBowlId;
    context.legacyNextBowlOutput = this.legacyAdapter.call(queriedBowlId);
    context.status = 'DISCOVERY_12_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery12.fixedIdNextBowl.calls');
    return context.legacyNextBowlOutput;
  }
}

class NextBowlPatchWrapper {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  repair(context, orderAt46Latch, queriedBowlId) {
    this.validationManager.requireDiscovery12Result(context);
    this.validationManager.requireLatchedBowlOrder(orderAt46Latch);
    this.validationManager.requireBowlId(queriedBowlId);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'NextBowlPatchWrapper';
    context.phase = 'PATCH_12_LATCH_CIRCULAR_SUCCESSOR';
    context.branchTrace.push('PATCH_12_LATCH_CIRCULAR_SUCCESSOR');
    context.patch12OrderAt46Latch = orderAt46Latch.slice();
    context.patch12QueriedId = queriedBowlId;
    context.patch12QueriedPosition = orderAt46Latch.indexOf(queriedBowlId);
    // Li helper legacy resta intact e es vocat diagnosticmen; su output ne decide li successor semantic.
    context.patch12LegacyDiagnostic = this.legacyAdapter.call(queriedBowlId);
    context.patch12LegacyDiagnosticPreserved = true;
    context.patch12Output = nextBowlFromOrderAt46Latch(orderAt46Latch, queriedBowlId);
    context.status = 'PATCH_12_RESULT';
    this.metricsManager.bump(context, 'patch12.nextBowl.calls');
    return context.patch12Output;
  }
}

class LegacyBiasedSelectionAdapter {
  call(stream, N) {
    const x = ringAnswerAt(stream, 0n);
    return { x, output: biasedLegacyPick(x, N) };
  }
}

class Discovery13BiasedSelectionHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, stream, seal, N) {
    this.validationManager.requirePatch12Result(context);
    this.validationManager.requireAnswerRing(stream);
    this.validationManager.requireExactInteger(seal);
    this.validationManager.requireShortFamilySize(N);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery13BiasedSelectionHandler';
    context.phase = 'DISCOVERY_13_BIASED_MODULO_SELECTION';
    context.branchTrace.push('DISCOVERY_13_BIASED_MODULO_SELECTION');
    context.legacySelectionSeal = seal;
    context.legacySelectionStreamFirst = stream.first;
    context.legacySelectionDirectionStep = stream.directionStep;
    context.legacySelectionN = N;
    const legacy = this.legacyAdapter.call(stream, N);
    context.legacySelectionInitialAnswer = legacy.x;
    context.legacySelectionOutput = legacy.output;
    context.status = 'DISCOVERY_13_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery13.biasedModulo.calls');
    return context.legacySelectionOutput;
  }
}

class SelectionRejectionPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, stream, seal, N) {
    // Ti route ne voca Discovery13BiasedSelectionHandler: li helper legacy ne deve esser vocat ante rejection.
    this.validationManager.requirePatch12Result(context);
    this.validationManager.requireAnswerRing(stream);
    this.validationManager.requireExactInteger(seal);
    this.validationManager.requireShortFamilySize(N);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'SelectionRejectionPatchWrapper';
    context.phase = 'PATCH_13_REJECTION_BEFORE_LEGACY_PICK';
    context.branchTrace.push('PATCH_13_REJECTION_BEFORE_LEGACY_PICK');
    const limit = (M_OLD / N) * N;
    let offset = 0n;
    let x = ringAnswerAt(stream, offset);
    while (x > limit) {
      offset += 1n;
      x = ringAnswerAt(stream, offset);
    }
    context.patch13AcceptanceLimit = limit;
    context.patch13AcceptedOffset = offset;
    context.patch13AcceptedAnswer = x;
    // patchedSmallPick repete li traversal intentionalmen quam layer compatibil e voca li old helper solmen pos rejection.
    context.patch13Output = patchedSmallPick(stream, N);
    context.patch13LegacyCallPreserved = true;
    context.status = 'PATCH_13_RESULT';
    this.metricsManager.bump(context, 'patch13.selectionRejection.calls');
    return context.patch13Output;
  }
}

class LegacyShortFamilyAssumptionAdapter {
  call(stream, N) {
    return legacySelectionAssumingNLeM(stream, N);
  }
}

class Discovery14WideSelectionHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, stream, seal, N) {
    this.validationManager.requirePatch12Result(context);
    this.validationManager.requireAnswerRing(stream);
    this.validationManager.requireExactInteger(seal);
    this.validationManager.requirePositiveFamilySize(N);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery14WideSelectionHandler';
    context.phase = 'DISCOVERY_14_LEGACY_ASSUMES_N_LE_M';
    context.branchTrace.push('DISCOVERY_14_LEGACY_ASSUMES_N_LE_M');
    context.legacyWideSelectionSeal = seal;
    context.legacyWideSelectionStreamFirst = stream.first;
    context.legacyWideSelectionDirectionStep = stream.directionStep;
    context.legacyWideSelectionN = N;
    context.legacyWideSelectionAssumedShort = true;
    try {
      context.legacyWideSelectionOutput = this.legacyAdapter.call(stream, N);
      context.legacyWideSelectionFailed = false;
    } catch (error) {
      context.legacyWideSelectionFailed = true;
      context.legacyWideSelectionErrorName = error && error.name ? error.name : 'Error';
      context.legacyWideSelectionErrorMessage = error && error.message ? error.message : String(error);
      context.legacyWideSelectionOutput = null;
    }
    context.status = 'DISCOVERY_14_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery14.shortOnlyAssumption.calls');
    return {
      failed: context.legacyWideSelectionFailed,
      output: context.legacyWideSelectionOutput,
      errorName: context.legacyWideSelectionErrorName,
      errorMessage: context.legacyWideSelectionErrorMessage
    };
  }
}

class WideSelectionPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, stream, seal, N) {
    this.validationManager.requireDiscovery14Result(context);
    this.validationManager.requireAnswerRing(stream);
    this.validationManager.requireExactInteger(seal);
    this.validationManager.requirePositiveFamilySize(N);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'WideSelectionPatchWrapper';
    context.phase = 'PATCH_14_SHORT_WIDE_DISPATCH';
    context.branchTrace.push('PATCH_14_SHORT_WIDE_DISPATCH');
    context.patch14LegacyDiagnosticPreserved = true;
    context.patch14LegacyDiagnosticFailed = context.legacyWideSelectionFailed;
    context.patch14LegacyDiagnosticErrorName = context.legacyWideSelectionErrorName;
    context.patch14LegacyDiagnosticOutput = context.legacyWideSelectionOutput;
    // Li assumption historic resta in su adapter; solmen ti wrapper decide si li familie usa li path curt o li detour wide.
    const dispatched = selectionDispatcherWithWideDetour(stream, N);
    context.patch14Mode = dispatched.mode;
    context.patch14Places = dispatched.places;
    context.patch14Space = dispatched.space;
    context.patch14Digits = dispatched.digits === null ? null : dispatched.digits.slice();
    context.patch14DigitReadCount = dispatched.digitReadCount;
    context.patch14InitialWide = dispatched.initialWide;
    context.patch14AcceptanceLimit = dispatched.acceptanceLimit;
    context.patch14AcceptedWide = dispatched.acceptedWide;
    context.patch14RejectionSteps = dispatched.rejectionSteps;
    context.patch14Output = dispatched.output;
    context.status = 'PATCH_14_RESULT';
    this.metricsManager.bump(context, 'patch14.wideDispatcher.calls');
    if (dispatched.mode === 'wide') {
      this.metricsManager.bump(context, 'patch14.wideDetour.calls');
    } else {
      this.metricsManager.bump(context, 'patch14.shortCompatibility.calls');
    }
    return context.patch14Output;
  }
}

class LegacyGateQuestionAdapter {
  call(signedStep) {
    if (typeof signedStep !== 'bigint') {
      throw new TypeError('Li passu signat legacy de gate deve esser un BigInt exact.');
    }
    const magnitude = signedStep < 0n ? -signedStep : signedStep;
    return {
      magnitude,
      questionDay: oldGateQuestionDay(magnitude)
    };
  }
}

class Discovery15NegativeGateQuestionHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, signedStep) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireSignedGateStep(signedStep);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery15NegativeGateQuestionHandler';
    context.phase = 'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE';
    context.branchTrace.push('DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE');
    context.legacyGateSignedStep = signedStep;
    const legacy = this.legacyAdapter.call(signedStep);
    this.validationManager.requireGateMagnitude(legacy.magnitude);
    context.legacyGateMagnitude = legacy.magnitude;
    context.legacyGateQuestionDay = legacy.questionDay;
    context.legacyGateQuestionAskedPositiveSide = signedStep < 0n && legacy.questionDay > FOUNDATION_DAY_OLD;
    context.status = 'DISCOVERY_15_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery15.negativeGatePositiveSide.calls');
    return context.legacyGateQuestionDay;
  }
}

class NegativeGateQuestionPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, signedStep) {
    this.validationManager.requireDiscovery15Result(context);
    this.validationManager.requireSignedGateStep(signedStep);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'NegativeGateQuestionPatchWrapper';
    context.phase = 'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR';
    context.branchTrace.push('PATCH_15_NEGATIVE_GATE_SIGN_DETOUR');
    context.patch15SignedStep = signedStep;
    context.patch15Magnitude = signedStep < 0n ? -signedStep : signedStep;
    // Li output legacy ja calculat resta visibil quam diagnostic e ne es removet ni mutat.
    context.patch15LegacyDiagnostic = context.legacyGateQuestionDay;
    context.patch15LegacyDiagnosticPreserved = true;
    context.patch15NegativeDetourUsed = signedStep < 0n;
    context.patch15Output = gateQuestionWithSignedStep(signedStep);
    if (signedStep >= 0n && context.patch15Output !== context.patch15LegacyDiagnostic) {
      throw new BootstrapStageError('Patch 15 ne posse mutar li path legacy por zero o passus positiv.');
    }
    context.status = 'PATCH_15_RESULT';
    this.metricsManager.bump(context, 'patch15.negativeGateDetour.calls');
    if (context.patch15NegativeDetourUsed) {
      this.metricsManager.bump(context, 'patch15.negativeGateDetour.used');
    } else {
      this.metricsManager.bump(context, 'patch15.legacySidePreserved.calls');
    }
    return context.patch15Output;
  }
}

class LegacyYearCandidateAdapter {
  prepareForSelection(gates, candidatePairs) {
    return {
      acceptedBeforeSort: legacyYearCandidatesBeforeSort(gates, candidatePairs),
      sorted: legacyStableLengthOnlyYearCandidates(gates, candidatePairs)
    };
  }

  select(preparedCandidates, stream) {
    if (!Array.isArray(preparedCandidates) || preparedCandidates.length < 1) {
      throw new RangeError('Li familie legacy preparat por selection ne posse esser vacui.');
    }
    const picked = selectionDispatcherWithWideDetour(stream, BigInt(preparedCandidates.length));
    return {
      pickedOrdinal: picked.output,
      candidate: preparedCandidates[Number(picked.output - 1n)]
    };
  }
}

class Discovery16LegacyYearCandidateHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, gates, candidatePairs, selectionStream) {
    this.validationManager.requirePatch15Result(context);
    this.validationManager.requireYearGateStore(gates);
    this.validationManager.requireYearCandidatePairs(candidatePairs);
    this.validationManager.requireAnswerRing(selectionStream);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery16LegacyYearCandidateHandler';
    context.phase = 'DISCOVERY_16_LEGACY_YEAR_MAX_5781';
    context.branchTrace.push('DISCOVERY_16_LEGACY_YEAR_MAX_5781');
    context.legacyYearCandidateInput = candidatePairs.map((pair) => ({
      openIndex: pair.openIndex, closeIndex: pair.closeIndex
    }));
    const prepared = this.legacyAdapter.prepareForSelection(gates, candidatePairs);
    context.legacyYearCandidatePreSortFamily = prepared.acceptedBeforeSort.map((candidate) => ({ ...candidate }));
    context.legacyYearCandidateSortedFamily = prepared.sorted.map((candidate) => ({ ...candidate }));
    context.legacyYearCandidateSelectionFamilySize = prepared.sorted.length;
    context.legacyYearCandidateSelectionStream = {
      first: selectionStream.first, directionStep: selectionStream.directionStep
    };
    context.legacyYearCandidateOverlongLengths = prepared.sorted
      .map((candidate) => candidate.candidateLength)
      .filter((candidateLength) => candidateLength > 5778n);
    const selected = this.legacyAdapter.select(prepared.sorted, selectionStream);
    context.legacyYearCandidateSelectedOrdinal = selected.pickedOrdinal;
    context.legacyYearCandidateSelected = { ...selected.candidate };
    context.status = 'DISCOVERY_16_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery16.legacy5781Candidate.calls');
    this.metricsManager.bump(context, 'discovery16.selectionReached.calls');
    return {
      acceptedBeforeSort: prepared.acceptedBeforeSort.map((candidate) => ({ ...candidate })),
      preparedForSelection: prepared.sorted.map((candidate) => ({ ...candidate })),
      selectedOrdinal: selected.pickedOrdinal,
      selected: { ...selected.candidate }
    };
  }
}

class YearCandidateCeilingPatchWrapper {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  repair(context, gates, candidatePairs, selectionStream) {
    this.validationManager.requirePatch15Result(context);
    this.validationManager.requireYearGateStore(gates);
    this.validationManager.requireYearCandidatePairs(candidatePairs);
    this.validationManager.requireAnswerRing(selectionStream);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'YearCandidateCeilingPatchWrapper';
    context.phase = 'PATCH_16_REAL_YEAR_MAX_5778_BEFORE_SORT';
    context.branchTrace.push('PATCH_16_REAL_YEAR_MAX_5778_BEFORE_SORT');

    // Li raw family legacy resta observabil, ma ti diagnostic ne es sortat ni selectet in li path semantic reparat.
    const legacyRaw = legacyYearCandidatesBeforeSort(gates, candidatePairs);
    context.patch16LegacyPreSortFamily = legacyRaw.map((candidate) => ({ ...candidate }));
    context.patch16LegacyCallsPreserved = true;
    context.patch16RejectedOverlongLengths = legacyRaw
      .filter((candidate) => candidate.candidateLength > REAL_YEAR_MAX_PATCH)
      .map((candidate) => candidate.candidateLength);

    // Omni reject per 5778 fini ante que stableLengthOnlyPatchedYearCandidates executa su sort.
    const filteredBeforeSort = yearCandidatesAfterFootnotePatchBeforeSort(gates, candidatePairs);
    context.patch16FilteredPreSortFamily = filteredBeforeSort.map((candidate) => ({ ...candidate }));
    const sorted = stableLengthOnlyPatchedYearCandidates(gates, candidatePairs);
    context.patch16SortedFamily = sorted.map((candidate) => ({ ...candidate }));
    context.patch16SelectionFamilySize = sorted.length;
    context.patch16SelectionStream = {
      first: selectionStream.first, directionStep: selectionStream.directionStep
    };
    const selected = this.legacyAdapter.select(sorted, selectionStream);
    context.patch16SelectedOrdinal = selected.pickedOrdinal;
    context.patch16Selected = { ...selected.candidate };
    context.status = 'PATCH_16_RESULT';
    this.metricsManager.bump(context, 'patch16.realYearCeiling.calls');
    for (let index = 0; index < context.patch16RejectedOverlongLengths.length; index += 1) {
      this.metricsManager.bump(context, 'patch16.overlongRejected.beforeSort');
    }
    return {
      legacyAcceptedBeforeSort: legacyRaw.map((candidate) => ({ ...candidate })),
      filteredBeforeSort: filteredBeforeSort.map((candidate) => ({ ...candidate })),
      preparedForSelection: sorted.map((candidate) => ({ ...candidate })),
      selectedOrdinal: selected.pickedOrdinal,
      selected: { ...selected.candidate }
    };
  }
}

class Discovery17Year5000TieHandler {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  handle(context, calculationDay) {
    this.validationManager.requirePatch16Result(context);
    this.validationManager.requireDiscreteDay(calculationDay);
    const prepared = context.patch16SortedFamily.map((candidate) => ({ ...candidate }));
    if (prepared.length < 2) {
      throw new RangeError('Discovery 17 exige adminim du year candidates filtrat por observar un tie.');
    }
    for (const candidate of prepared) {
      if (!(candidate.openGate < calculationDay && calculationDay <= candidate.closeGate)) {
        throw new BootstrapStageError('Li familie de Discovery 17 deve contener li calculation-day in chascun candidate de Year 5000.');
      }
    }

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery17Year5000TieHandler';
    context.phase = 'DISCOVERY_17_YEAR_5000_EQUAL_LENGTH_TIE';
    context.branchTrace.push('DISCOVERY_17_YEAR_5000_EQUAL_LENGTH_TIE');
    context.discovery17Year5000CalculationDay = calculationDay;
    context.discovery17PreparedForSelection = prepared.map((candidate) => ({ ...candidate }));
    context.discovery17OpeningOrder = prepared.map((candidate) => candidate.openGate);
    const witnessLength = prepared[0].candidateLength;
    for (const candidate of prepared) {
      if (candidate.candidateLength !== witnessLength) {
        throw new BootstrapStageError('Li witness de Discovery 17 deve usar candidates con longore egal.');
      }
    }
    context.discovery17WitnessCandidateLength = witnessLength;
    context.discovery17WitnessFamilySize = prepared.length;
    context.discovery17SelectedOrdinal = context.patch16SelectedOrdinal;
    context.discovery17Selected = { ...context.patch16Selected };
    // Discovery 17 observa solmen li ordre stabil heredat; null reorder per opening gate es executet ci.
    context.discovery17StableLengthOnlyScarPreserved = true;
    context.status = 'DISCOVERY_17_LEGACY_TIE_RESULT';
    this.metricsManager.bump(context, 'discovery17.year5000Tie.calls');
    return {
      preparedForSelection: prepared.map((candidate) => ({ ...candidate })),
      selectedOrdinal: context.discovery17SelectedOrdinal,
      selected: { ...context.discovery17Selected }
    };
  }
}

class Year5000TiePatchWrapper {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  repair(context, selectionStream) {
    this.validationManager.requireDiscovery17Result(context);
    this.validationManager.requireAnswerRing(selectionStream);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Year5000TiePatchWrapper';
    context.phase = 'PATCH_17_EQUAL_LENGTH_RUN_OPENING_GATE';
    context.branchTrace.push('PATCH_17_EQUAL_LENGTH_RUN_OPENING_GATE');

    // Li stable sort historic de Patch 16 resta li prim passu real e es conservat quam diagnostic.
    const legacySorted = context.discovery17PreparedForSelection.map((candidate) => ({ ...candidate }));
    context.patch17LegacyLengthSortedFamily = legacySorted.map((candidate) => ({ ...candidate }));
    context.patch17LegacySelectedDiagnostic = { ...context.discovery17Selected };
    context.patch17LegacyDiagnosticPreserved = true;

    let equalRunCount = 0;
    for (let start = 0; start < legacySorted.length;) {
      let end = start + 1;
      while (end < legacySorted.length && legacySorted[end].candidateLength === legacySorted[start].candidateLength) {
        end += 1;
      }
      if (end - start > 1) equalRunCount += 1;
      start = end;
    }

    // Patch 17 ne usa null comparator global du-clave: solmen li runs contigui egal es reordinat.
    const repaired = sortEqualLengthRunsByOpeningGate(legacySorted.map((candidate) => ({ ...candidate })));
    context.patch17EqualLengthRunCount = equalRunCount;
    context.patch17RepairedFamily = repaired.map((candidate) => ({ ...candidate }));
    context.patch17SelectionFamilySize = repaired.length;
    context.patch17SelectionStream = {
      first: selectionStream.first, directionStep: selectionStream.directionStep
    };
    const selected = this.legacyAdapter.select(repaired, selectionStream);
    context.patch17SelectedOrdinal = selected.pickedOrdinal;
    context.patch17Selected = { ...selected.candidate };
    context.status = 'PATCH_17_RESULT';
    this.metricsManager.bump(context, 'patch17.equalLengthRunRepair.calls');
    for (let index = 0; index < equalRunCount; index += 1) {
      this.metricsManager.bump(context, 'patch17.equalLengthRuns.reordered');
    }
    return {
      legacyPreparedForSelection: context.patch17LegacyLengthSortedFamily.map((candidate) => ({ ...candidate })),
      preparedForSelection: repaired.map((candidate) => ({ ...candidate })),
      selectedOrdinal: selected.pickedOrdinal,
      selected: { ...selected.candidate }
    };
  }
}

class LegacyYearJumpAdapter {
  call(anchor, targetDay) {
    return oldJumpGuess(anchor, targetDay);
  }
}

class Discovery18YearJumpHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, targetDay) {
    this.validationManager.requirePatch17Result(context);
    this.validationManager.requireDiscreteDay(targetDay);
    const selected = context.patch17Selected;
    if (!selected || typeof selected !== 'object') {
      throw new BootstrapStageError('Discovery 18 ne trova li candidate selectet de Year 5000 ex Patch 17.');
    }
    const anchor = {
      number: 5000n,
      openDay: selected.openGate,
      firstDay: selected.openGate + 1n,
      closeDay: selected.closeGate
    };
    this.validationManager.requireYearJumpAnchor(anchor);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery18YearJumpHandler';
    context.phase = 'DISCOVERY_18_OLD_JUMP_GUESS_365';
    context.branchTrace.push('DISCOVERY_18_OLD_JUMP_GUESS_365');
    context.legacyJumpAnchorNumber = anchor.number;
    context.legacyJumpAnchorOpenDay = anchor.openDay;
    context.legacyJumpAnchorFirstDay = anchor.firstDay;
    context.legacyJumpAnchorCloseDay = anchor.closeDay;
    context.legacyJumpTargetDay = targetDay;
    context.legacyJumpDeltaFromFirstDay = targetDay - anchor.firstDay;
    const guess = this.legacyAdapter.call(anchor, targetDay);
    context.legacyJumpGuess = guess;
    // Discovery 18 conserva li defect: li estimation /365 es usat directmen quam resultate semantic.
    context.legacyJumpSemanticYearNumber = guess;
    context.legacyJumpGuessUsedAsSemantic = true;
    context.status = 'DISCOVERY_18_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery18.oldJumpGuess.calls');
    this.metricsManager.bump(context, 'discovery18.guessUsedAsSemantic.calls');
    return { anchor: { ...anchor }, guessedYearNumber: guess, semanticYearNumber: guess };
  }
}

class SequentialYearWalkPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, targetDay, yearWalkSource) {
    this.validationManager.requireDiscovery18Result(context);
    this.validationManager.requireDiscreteDay(targetDay);
    this.validationManager.requireYearWalkSource(yearWalkSource);
    const anchor = {
      number: context.legacyJumpAnchorNumber,
      openDay: context.legacyJumpAnchorOpenDay,
      firstDay: context.legacyJumpAnchorFirstDay,
      closeDay: context.legacyJumpAnchorCloseDay
    };
    this.validationManager.requireYearJumpAnchor(anchor);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'SequentialYearWalkPatchWrapper';
    context.phase = 'PATCH_18_SEQUENTIAL_YEAR_WALK';
    context.branchTrace.push('PATCH_18_SEQUENTIAL_YEAR_WALK');

    // Li scar /365 ja esset vocat realmen in Discovery 18; Patch 18 conserva it exclusivmen quam telemetry.
    context.patch18LegacyGuessDiagnostic = context.legacyJumpGuess;
    context.patch18LegacyDiagnosticPreserved = true;
    context.patch18GuessIgnoredForSemantics = true;
    const walked = findYearByWalkPatch(
      anchor,
      targetDay,
      (year) => yearWalkSource.nextYear({ ...year }),
      (year) => yearWalkSource.previousYear({ ...year })
    );
    context.patch18WalkDirection = walked.direction;
    context.patch18WalkStepCount = walked.stepCount;
    context.patch18WalkTrace = walked.trace.map((step) => ({ ...step }));
    context.patch18ResolvedYear = { ...walked.year };
    context.patch18SemanticYearNumber = walked.year.number;
    context.status = 'PATCH_18_RESULT';
    this.metricsManager.bump(context, 'patch18.sequentialYearWalk.calls');
    for (let index = 0n; index < walked.stepCount; index += 1n) {
      this.metricsManager.bump(context, 'patch18.singleYearTransitions.calls');
    }
    if (walked.direction === 'next') this.metricsManager.bump(context, 'patch18.nextYearWalk.calls');
    if (walked.direction === 'previous') this.metricsManager.bump(context, 'patch18.previousYearWalk.calls');
    if (walked.direction === 'anchor') this.metricsManager.bump(context, 'patch18.anchorAlreadyContainsTarget.calls');
    return {
      anchor: { ...anchor },
      telemetryGuess: context.patch18LegacyGuessDiagnostic,
      semanticYearNumber: context.patch18SemanticYearNumber,
      resolvedYear: { ...context.patch18ResolvedYear },
      direction: context.patch18WalkDirection,
      stepCount: context.patch18WalkStepCount,
      trace: context.patch18WalkTrace.map((step) => ({ ...step }))
    };
  }
}

function buildLegacyYearStructureValue(year, calculationDay) {
  if (!year || typeof year !== 'object' || typeof year.number !== 'bigint' ||
      typeof year.openDay !== 'bigint' || typeof year.closeDay !== 'bigint' ||
      typeof calculationDay !== 'bigint') {
    throw new TypeError('Li value current del cache legacy exige year e calculation-day exact.');
  }
  // Ti value representa li structura current quel li cache vell guardar; li hit legacy ne inspecte su causas.
  return Object.freeze({
    yearNumber: year.number,
    actionDay: calculationDay,
    openingDay: year.openDay,
    closingDay: year.closeDay
  });
}

function legacyYearNumberOnlyLookup(cacheMap, yearNumber) {
  if (!(cacheMap instanceof Map)) {
    throw new TypeError('Li cache legacy per year number deve esser un Map.');
  }
  if (typeof yearNumber !== 'bigint') {
    throw new TypeError('Li clave legacy del cache deve esser un year number BigInt exact.');
  }
  // Li scar historic consulta solmen year.number; null altri parte del request participa in li decision HIT.
  if (!cacheMap.has(yearNumber)) return { hit: false, value: null };
  return { hit: true, value: cacheMap.get(yearNumber) };
}

function legacyYearNumberOnlyPut(cacheMap, yearNumber, value) {
  if (!(cacheMap instanceof Map)) {
    throw new TypeError('Li cache legacy per year number deve esser un Map.');
  }
  if (typeof yearNumber !== 'bigint') {
    throw new TypeError('Li clave legacy del cache deve esser un year number BigInt exact.');
  }
  cacheMap.set(yearNumber, value);
  return value;
}

class LegacyYearNumberCacheAdapter {
  constructor(cacheMap) {
    if (!(cacheMap instanceof Map)) {
      throw new TypeError('LegacyYearNumberCacheAdapter exige un Map persistet per su manager.');
    }
    this.cacheMap = cacheMap;
  }

  lookup(year) {
    return legacyYearNumberOnlyLookup(this.cacheMap, year.number);
  }

  put(year, value) {
    return legacyYearNumberOnlyPut(this.cacheMap, year.number, value);
  }
}

class Discovery19YearNumberCacheHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, year, calculationDay) {
    this.validationManager.requirePatch18Result(context);
    this.validationManager.requireYearCacheRecord(year);
    this.validationManager.requireDiscreteDay(calculationDay);
    if (context.patch18SemanticYearNumber !== year.number) {
      throw new BootstrapStageError('Discovery 19 deve usar li year resoluet semanticmen per Patch 18.');
    }
    const freshValue = buildLegacyYearStructureValue(year, calculationDay);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery19YearNumberCacheHandler';
    context.phase = 'DISCOVERY_19_YEAR_NUMBER_ONLY_CACHE';
    context.branchTrace.push('DISCOVERY_19_YEAR_NUMBER_ONLY_CACHE');
    context.legacyYearCacheKey = year.number;
    context.legacyYearCacheRequestActionDay = calculationDay;
    context.legacyYearCacheRequestOpeningDay = year.openDay;
    context.legacyYearCacheRequestClosingDay = year.closeDay;
    context.legacyYearCacheFreshValue = { ...freshValue };
    context.legacyYearCacheOnlyNumberKeyPreserved = true;

    const cached = this.legacyAdapter.lookup(year);
    context.legacyYearCacheHit = cached.hit;
    context.legacyYearCacheStoredBefore = cached.hit ? { ...cached.value } : null;
    if (!cached.hit) {
      this.legacyAdapter.put(year, freshValue);
      context.legacyYearCacheOutput = { ...freshValue };
      this.metricsManager.bump(context, 'discovery19.yearNumberOnlyCache.misses');
    } else {
      // Discovery 19 conserva li defect: un HIT per li sam year.number es acceptat sin gardes del request current.
      context.legacyYearCacheOutput = { ...cached.value };
      this.metricsManager.bump(context, 'discovery19.yearNumberOnlyCache.hits');
    }
    context.status = 'DISCOVERY_19_LEGACY_CACHE_RESULT';
    this.metricsManager.bump(context, 'discovery19.yearNumberOnlyCache.calls');
    return {
      hit: context.legacyYearCacheHit,
      key: context.legacyYearCacheKey,
      freshValue: { ...context.legacyYearCacheFreshValue },
      value: { ...context.legacyYearCacheOutput }
    };
  }
}


function calculationDayFingerprint(calculationDay) {
  if (typeof calculationDay !== 'bigint') {
    throw new TypeError('Li fingerprint del calculation-day deve esser li die BigInt exact self.');
  }
  // Li guard volutmen ne inventa null hash: su fingerprint es directmen li calculation-day current.
  return calculationDay;
}

function cloneGuardedYearCacheEntry(entry) {
  if (!entry || typeof entry !== 'object') return null;
  return {
    calculationDayFingerprint: entry.calculationDayFingerprint,
    openGate: entry.openGate,
    closeGate: entry.closeGate,
    value: entry.value && typeof entry.value === 'object' ? { ...entry.value } : entry.value
  };
}

function cacheGetWithActionGuard(cacheMap, year, calculationDay) {
  if (!(cacheMap instanceof Map)) {
    throw new TypeError('Li cache guardat per year number deve esser un Map.');
  }
  if (!year || typeof year !== 'object' || typeof year.number !== 'bigint' ||
      typeof year.openDay !== 'bigint' || typeof year.closeDay !== 'bigint') {
    throw new TypeError('Li cache guardat exige un year record exact.');
  }
  const fingerprint = calculationDayFingerprint(calculationDay);
  // Li scar historic resta un call real e veni ante omni guard: li bad key year.number ne es reparat.
  const legacyLookup = legacyYearNumberOnlyLookup(cacheMap, year.number);
  if (!legacyLookup.hit) {
    return { hit: false, reason: 'empty', value: null, entry: null, legacyLookup };
  }
  const entry = legacyLookup.value;
  if (!entry || typeof entry !== 'object' || !Object.prototype.hasOwnProperty.call(entry, 'calculationDayFingerprint') ||
      !Object.prototype.hasOwnProperty.call(entry, 'openGate') ||
      !Object.prototype.hasOwnProperty.call(entry, 'closeGate') ||
      !Object.prototype.hasOwnProperty.call(entry, 'value')) {
    return { hit: false, reason: 'legacy-value-shape', value: null, entry, legacyLookup };
  }
  if (entry.calculationDayFingerprint !== fingerprint) {
    return { hit: false, reason: 'calculation-day', value: null, entry, legacyLookup };
  }
  if (entry.openGate !== year.openDay) {
    return { hit: false, reason: 'open-gate', value: null, entry, legacyLookup };
  }
  if (entry.closeGate !== year.closeDay) {
    return { hit: false, reason: 'close-gate', value: null, entry, legacyLookup };
  }
  return { hit: true, reason: null, value: entry.value, entry, legacyLookup };
}

function cachePutWithGuard(cacheMap, year, calculationDay, value) {
  if (!(cacheMap instanceof Map)) {
    throw new TypeError('Li cache guardat per year number deve esser un Map.');
  }
  if (!year || typeof year !== 'object' || typeof year.number !== 'bigint' ||
      typeof year.openDay !== 'bigint' || typeof year.closeDay !== 'bigint') {
    throw new TypeError('Li cache guardat exige un year record exact.');
  }
  const entry = Object.freeze({
    calculationDayFingerprint: calculationDayFingerprint(calculationDay),
    openGate: year.openDay,
    closeGate: year.closeDay,
    value
  });
  // Li put legacy resta activ: li map usa ancor exclusivmen year.number quam su clave historic.
  legacyYearNumberOnlyPut(cacheMap, year.number, entry);
  return entry;
}

class YearCacheActionGuardPatchWrapper {
  constructor(validationManager, metricsManager, cacheMap) {
    if (!(cacheMap instanceof Map)) {
      throw new TypeError('YearCacheActionGuardPatchWrapper exige li sam Map legacy manager-owned.');
    }
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.cacheMap = cacheMap;
  }

  repair(context, year, calculationDay) {
    this.validationManager.requirePatch18Result(context);
    this.validationManager.requireYearCacheRecord(year);
    this.validationManager.requireDiscreteDay(calculationDay);
    if (context.patch18SemanticYearNumber !== year.number) {
      throw new BootstrapStageError('Patch 19 deve guardar li year semantic resoluet per Patch 18.');
    }
    const freshValue = buildLegacyYearStructureValue(year, calculationDay);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'YearCacheActionGuardPatchWrapper';
    context.phase = 'PATCH_19_ACTION_AND_GATE_GUARDS';
    context.branchTrace.push('PATCH_19_ACTION_AND_GATE_GUARDS');
    context.patch19CacheKey = year.number;
    context.patch19CalculationDayFingerprint = calculationDayFingerprint(calculationDay);
    context.patch19OpenGate = year.openDay;
    context.patch19CloseGate = year.closeDay;
    context.patch19OnlyNumberKeyPreserved = true;

    const guarded = cacheGetWithActionGuard(this.cacheMap, year, calculationDay);
    context.patch19LegacyLookupDiagnostic = {
      hit: guarded.legacyLookup.hit,
      value: guarded.legacyLookup.hit && guarded.legacyLookup.value && typeof guarded.legacyLookup.value === 'object'
        ? { ...guarded.legacyLookup.value }
        : guarded.legacyLookup.value
    };
    context.patch19LegacyDiagnosticPreserved = true;
    context.patch19GuardedEntryBefore = cloneGuardedYearCacheEntry(guarded.entry);
    context.patch19GuardMismatchReason = guarded.reason;
    context.patch19CacheHit = guarded.hit;
    if (guarded.hit) {
      context.patch19Recomputed = false;
      context.patch19Output = guarded.value && typeof guarded.value === 'object' ? { ...guarded.value } : guarded.value;
      context.patch19EntryAfter = cloneGuardedYearCacheEntry(guarded.entry);
      this.metricsManager.bump(context, 'patch19.actionGuard.hits');
    } else {
      // Un mismatch deven semanticmen un MISS; li current value reemplazza li entry sub li sam bad key.
      const entry = cachePutWithGuard(this.cacheMap, year, calculationDay, freshValue);
      context.patch19Recomputed = true;
      context.patch19Output = { ...freshValue };
      context.patch19EntryAfter = cloneGuardedYearCacheEntry(entry);
      this.metricsManager.bump(context, 'patch19.actionGuard.misses');
      if (guarded.reason !== 'empty') this.metricsManager.bump(context, 'patch19.actionGuard.replacements');
    }
    context.status = 'PATCH_19_RESULT';
    this.metricsManager.bump(context, 'patch19.actionGuard.calls');
    return {
      hit: context.patch19CacheHit,
      key: context.patch19CacheKey,
      reason: context.patch19GuardMismatchReason,
      recomputed: context.patch19Recomputed,
      value: context.patch19Output && typeof context.patch19Output === 'object' ? { ...context.patch19Output } : context.patch19Output,
      entry: cloneGuardedYearCacheEntry(context.patch19EntryAfter)
    };
  }
}


function structureSauceCountsFromDays(calculationDay, targetDay) {
  if (typeof calculationDay !== 'bigint' || typeof targetDay !== 'bigint') {
    throw new TypeError('Li dies por structure sauce deve esser BigInt exact.');
  }
  const action = dayTagWithFoundationScar(calculationDay);
  const target = dayTagWithFoundationScar(targetDay);
  return Object.freeze({
    action,
    target,
    distance: distanceWithChronologyDetour(calculationDay, targetDay),
    connection: action + target,
    direction: targetDay < calculationDay ? 1n : targetDay === calculationDay ? 2n : 3n
  });
}

function sauceWithCurrentScars(calculationDay, targetDay) {
  const counts = structureSauceCountsFromDays(calculationDay, targetDay);
  const stones = getStoneTableThroughLegacyBuilder();
  const result = sauceWithOrderAt46Latch(counts, stones);
  return Object.freeze({
    bowls: Object.freeze(result.bowls.slice()),
    orderAt46Latch: Object.freeze(result.orderAt46Latch.slice())
  });
}

function oldStructureSauce(cDay, originalTargetDay) {
  // Discovery 20 conserva li assumption historic: li sauce structural es calculat con li target original del request.
  return sauceWithCurrentScars(cDay, originalTargetDay);
}

function legacyStructureSelectorToken(sauceResult) {
  if (!sauceResult || typeof sauceResult !== 'object' || !Array.isArray(sauceResult.bowls) ||
      sauceResult.bowls.length < 7 || !Array.isArray(sauceResult.orderAt46Latch) ||
      sauceResult.orderAt46Latch.length !== 6) {
    throw new TypeError('Li selector structural legacy exige un sauce complet con bowls e latch.');
  }
  return Object.freeze({
    bowl2: sauceResult.bowls[2],
    orderAt46Latch: Object.freeze(sauceResult.orderAt46Latch.slice())
  });
}

class LegacyStructureSauceAdapter {
  call(cDay, originalTargetDay) {
    return oldStructureSauce(cDay, originalTargetDay);
  }
}

class LegacyStructureSelectorAdapter {
  select(sauceResult) {
    return legacyStructureSelectorToken(sauceResult);
  }
}

class Discovery20StructureSauceHandler {
  constructor(validationManager, metricsManager, sauceAdapter, selectorAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.sauceAdapter = sauceAdapter;
    this.selectorAdapter = selectorAdapter;
  }

  handle(context, calculationDay, originalTargetDay, yearFirstDay) {
    this.validationManager.requirePatch19Result(context);
    this.validationManager.requireDiscreteDay(calculationDay);
    this.validationManager.requireDiscreteDay(originalTargetDay);
    this.validationManager.requireDiscreteDay(yearFirstDay);
    if (!context.patch18ResolvedYear || yearFirstDay !== context.patch18ResolvedYear.openDay + 1n) {
      throw new BootstrapStageError('Discovery 20 deve derivar year.firstDay ex li year resoluet per Patch 18.');
    }
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery20StructureSauceHandler';
    context.phase = 'DISCOVERY_20_STRUCTURE_SAUCE_ORIGINAL_TARGET';
    context.branchTrace.push('DISCOVERY_20_STRUCTURE_SAUCE_ORIGINAL_TARGET');
    context.legacyStructureSauceCalculationDay = calculationDay;
    context.legacyStructureSauceOriginalTargetDay = originalTargetDay;
    context.legacyStructureSauceYearFirstDay = yearFirstDay;
    context.legacyStructureSauceTargetsDiffer = originalTargetDay !== yearFirstDay;

    const legacySauce = this.sauceAdapter.call(calculationDay, originalTargetDay);
    this.validationManager.requireStructureSauceResult(legacySauce);
    context.legacyStructureSauceBowls = legacySauce.bowls.slice();
    context.legacyStructureSauceOrderAt46Latch = legacySauce.orderAt46Latch.slice();
    const token = this.selectorAdapter.select(legacySauce);
    context.legacyStructureSelectorToken = {
      bowl2: token.bowl2,
      orderAt46Latch: token.orderAt46Latch.slice()
    };
    context.legacyStructureSelectorUsedOriginalTargetSauce = true;
    context.status = 'DISCOVERY_20_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery20.oldStructureSauce.calls');
    this.metricsManager.bump(context, 'discovery20.legacySelector.calls');
    return {
      sauceTargetDay: originalTargetDay,
      yearFirstDay,
      targetsDiffer: context.legacyStructureSauceTargetsDiffer,
      selectorToken: {
        bowl2: token.bowl2,
        orderAt46Latch: token.orderAt46Latch.slice()
      }
    };
  }
}

function structureSaucePatch(cDay, originalTargetDay, yearFirstDay) {
  if (typeof cDay !== 'bigint' || typeof originalTargetDay !== 'bigint' || typeof yearFirstDay !== 'bigint') {
    throw new TypeError('Patch 20 exige cDay, target original e year.firstDay quam BigInt exact.');
  }
  // Li helper historic resta intact e es executet realmen quam ghost; su bug vive in li duesim argument, ne in su formulas.
  const ghost = oldStructureSauce(cDay, originalTargetDay);
  // Ne reparar oldStructureSauce: li sauce semantic es materialisat separatim ex year.firstDay, talmen li ghost ne posse atinger li selector.
  const semanticSauce = sauceWithCurrentScars(cDay, yearFirstDay);
  return Object.freeze({
    targetsDiffer: originalTargetDay !== yearFirstDay,
    ghost: Object.freeze({
      bowls: Object.freeze(ghost.bowls.slice()),
      orderAt46Latch: Object.freeze(ghost.orderAt46Latch.slice())
    }),
    semanticSauce: Object.freeze({
      bowls: Object.freeze(semanticSauce.bowls.slice()),
      orderAt46Latch: Object.freeze(semanticSauce.orderAt46Latch.slice())
    })
  });
}

class StructureSaucePatchWrapper {
  constructor(validationManager, metricsManager, selectorAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.selectorAdapter = selectorAdapter;
  }

  repair(context, calculationDay, originalTargetDay, yearFirstDay) {
    this.validationManager.requirePatch19Result(context);
    this.validationManager.requireDiscreteDay(calculationDay);
    this.validationManager.requireDiscreteDay(originalTargetDay);
    this.validationManager.requireDiscreteDay(yearFirstDay);
    if (!context.patch18ResolvedYear || yearFirstDay !== context.patch18ResolvedYear.openDay + 1n) {
      throw new BootstrapStageError('Patch 20 deve usar exactmen year.firstDay ex li year resoluet per Patch 18.');
    }
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'StructureSaucePatchWrapper';
    context.phase = 'PATCH_20_STRUCTURE_SAUCE_YEAR_FIRST_DAY_GHOST';
    context.branchTrace.push('PATCH_20_STRUCTURE_SAUCE_YEAR_FIRST_DAY_GHOST');
    context.patch20GhostCalculationDay = calculationDay;
    context.patch20GhostOriginalTargetDay = originalTargetDay;
    context.patch20YearFirstDay = yearFirstDay;

    const patched = structureSaucePatch(calculationDay, originalTargetDay, yearFirstDay);
    context.patch20TargetsDiffer = patched.targetsDiffer;
    context.patch20GhostSauceBowls = patched.ghost.bowls.slice();
    context.patch20GhostOrderAt46Latch = patched.ghost.orderAt46Latch.slice();
    context.patch20GhostExecuted = true;
    context.patch20GhostIgnoredForSelector = true;
    context.patch20SemanticSauceBowls = patched.semanticSauce.bowls.slice();
    context.patch20SemanticOrderAt46Latch = patched.semanticSauce.orderAt46Latch.slice();

    // Solmen li sauce recalculat con year.firstDay entra li selector; null data del ghost es usat quam input.
    const token = this.selectorAdapter.select(patched.semanticSauce);
    context.patch20SemanticSelectorToken = {
      bowl2: token.bowl2,
      orderAt46Latch: token.orderAt46Latch.slice()
    };
    context.patch20SelectorUsedYearFirstDaySauce = true;
    context.status = 'PATCH_20_RESULT';
    this.metricsManager.bump(context, 'patch20.oldStructureSauce.ghost.calls');
    this.metricsManager.bump(context, 'patch20.yearFirstDaySauce.calls');
    this.metricsManager.bump(context, 'patch20.semanticSelector.calls');
    if (patched.targetsDiffer) this.metricsManager.bump(context, 'patch20.targetDetour.calls');
    return {
      ghostTargetDay: originalTargetDay,
      semanticTargetDay: yearFirstDay,
      targetsDiffer: patched.targetsDiffer,
      ghostSauce: {
        bowls: patched.ghost.bowls.slice(),
        orderAt46Latch: patched.ghost.orderAt46Latch.slice()
      },
      selectorToken: {
        bowl2: token.bowl2,
        orderAt46Latch: token.orderAt46Latch.slice()
      }
    };
  }
}


function positiveCompositionCountExact(gapCount, cutletCount) {
  if (!Number.isInteger(gapCount) || !Number.isInteger(cutletCount) || gapCount < 1 || cutletCount < 1) {
    throw new RangeError('Li gap count e cutlet count deve esser integers positiv.');
  }
  if (cutletCount > gapCount) return 0n;
  let n = BigInt(gapCount - 1);
  let k = BigInt(cutletCount - 1);
  if (k > n - k) k = n - k;
  let result = 1n;
  for (let i = 1n; i <= k; i += 1n) {
    result = (result * (n - k + i)) / i;
  }
  return result;
}

function legacyPositiveCompositions(gapCount, cutletCount) {
  if (!Number.isInteger(gapCount) || !Number.isInteger(cutletCount) || gapCount < 1 || cutletCount < 1) {
    throw new RangeError('Li familie legacy de partitions exige gapCount e cutletCount integers positiv.');
  }
  if (cutletCount > gapCount) {
    throw new RangeError('Li familie legacy ne posse haver plu cutlets quam gate gaps.');
  }
  const totalCount = positiveCompositionCountExact(gapCount, cutletCount);
  return Object.freeze({
    count() {
      return totalCount;
    },
    unrank1(rank1) {
      if (typeof rank1 !== 'bigint' || rank1 < 1n || rank1 > totalCount) {
        throw new RangeError('Li rank legacy de cutlet partition es extra li familie.');
      }
      let rank = rank1;
      let remaining = gapCount;
      let slots = cutletCount;
      const out = [];
      while (slots > 0) {
        if (slots === 1) {
          out.push(remaining);
          break;
        }
        const maxPart = remaining - (slots - 1);
        for (let part = 1; part <= maxPart; part += 1) {
          const block = positiveCompositionCountExact(remaining - part, slots - 1);
          if (rank > block) {
            rank -= block;
            continue;
          }
          out.push(part);
          remaining -= part;
          slots -= 1;
          break;
        }
      }
      return out;
    }
  });
}

function filteredCutletCompositions(gapCount, cutletCount, internalGateOffset) {
  if (!Number.isInteger(gapCount) || !Number.isInteger(cutletCount) || gapCount < 1 || cutletCount < 1) {
    throw new RangeError('Li familie filtrat de Patch 21 exige gapCount e cutletCount integers positiv.');
  }
  if (cutletCount > gapCount) {
    throw new RangeError('Li familie filtrat ne posse haver plu cutlets quam gate gaps.');
  }
  if (!Number.isInteger(internalGateOffset) || internalGateOffset <= 0 || internalGateOffset >= gapCount) {
    throw new RangeError('Li offset de gate por Patch 21 deve esser strictmen intern al year.');
  }

  // Ti DP conta solmen branches quel atinge exactmen li boundary; li ordre de parts resta li ordre lexicografic del familie legacy.
  const memo = new Map();
  function countAccepted(remaining, slots, cumulative, boundaryHit) {
    if (slots === 0) {
      return remaining === 0 && boundaryHit ? 1n : 0n;
    }
    if (remaining < slots) return 0n;
    if (!boundaryHit && cumulative >= internalGateOffset) return 0n;
    const key = remaining + ':' + slots + ':' + cumulative + ':' + (boundaryHit ? 1 : 0);
    if (memo.has(key)) return memo.get(key);
    let total = 0n;
    const maxPart = remaining - (slots - 1);
    for (let part = 1; part <= maxPart; part += 1) {
      const nextCumulative = cumulative + part;
      if (!boundaryHit && nextCumulative > internalGateOffset) break;
      const nextBoundaryHit = boundaryHit || nextCumulative === internalGateOffset;
      total += countAccepted(remaining - part, slots - 1, nextCumulative, nextBoundaryHit);
    }
    memo.set(key, total);
    return total;
  }

  const totalCount = countAccepted(gapCount, cutletCount, 0, false);
  return Object.freeze({
    count() {
      return totalCount;
    },
    unrank1(rank1) {
      if (typeof rank1 !== 'bigint' || rank1 < 1n || rank1 > totalCount) {
        throw new RangeError('Li rank filtrat de cutlet partition es extra li familie legal.');
      }
      let rank = rank1;
      let remaining = gapCount;
      let slots = cutletCount;
      let cumulative = 0;
      let boundaryHit = false;
      const out = [];
      while (slots > 0) {
        const maxPart = remaining - (slots - 1);
        let chosen = false;
        for (let part = 1; part <= maxPart; part += 1) {
          const nextCumulative = cumulative + part;
          if (!boundaryHit && nextCumulative > internalGateOffset) break;
          const nextBoundaryHit = boundaryHit || nextCumulative === internalGateOffset;
          const block = countAccepted(remaining - part, slots - 1, nextCumulative, nextBoundaryHit);
          if (rank > block) {
            rank -= block;
            continue;
          }
          out.push(part);
          remaining -= part;
          slots -= 1;
          cumulative = nextCumulative;
          boundaryHit = nextBoundaryHit;
          chosen = true;
          break;
        }
        if (!chosen) {
          throw new BootstrapStageError('Li DP de Patch 21 ne posset resolver un rank ja validat.');
        }
      }
      return out;
    }
  });
}

function cutletAnswerRingFromSauce(sauceResult, seal) {
  if (!sauceResult || !Array.isArray(sauceResult.bowls) || !Array.isArray(sauceResult.orderAt46Latch)) {
    throw new TypeError('Li cutlet selection exige un structure sauce complet.');
  }
  if (typeof seal !== 'bigint') {
    throw new TypeError('Li seal de cutlet selection deve esser un BigInt exact.');
  }
  const nextBowl = nextBowlFromOrderAt46Latch(sauceResult.orderAt46Latch, 2);
  return answerRingFromCurrentState(sauceResult.bowls, 2, nextBowl, seal);
}

class LegacyCutletPartitionAdapter {
  selectAllPositive(sauceResult, gapCount) {
    if (!Number.isInteger(gapCount) || gapCount < 6) {
      throw new RangeError('Li year legacy deve contener adminim six gate gaps por cutlets.');
    }
    const cutletCountCandidates = [];
    for (let cutletCount = 6; cutletCount <= 17 && cutletCount <= gapCount; cutletCount += 1) {
      cutletCountCandidates.push(cutletCount);
    }
    const countStream = cutletAnswerRingFromSauce(sauceResult, 20n);
    const countPick = selectionDispatcherWithWideDetour(countStream, BigInt(cutletCountCandidates.length));
    const cutletCount = cutletCountCandidates[Number(countPick.output - 1n)];

    // Li scar historic materialisa li familie de omni positive compositions; null gate intern es consultat ci.
    const family = legacyPositiveCompositions(gapCount, cutletCount);
    const partitionStream = cutletAnswerRingFromSauce(sauceResult, 21n);
    const partitionPick = selectionDispatcherWithWideDetour(partitionStream, family.count());
    const partition = family.unrank1(partitionPick.output);
    return {
      cutletCountCandidates,
      countStream,
      cutletCountSelectedOrdinal: countPick.output,
      cutletCount,
      familyCount: family.count(),
      partitionStream,
      selectedRank: partitionPick.output,
      partition
    };
  }
}

class Discovery21CutletPartitionHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, calculationDay, gates) {
    this.validationManager.requirePatch20Result(context);
    this.validationManager.requireDiscreteDay(calculationDay);
    this.validationManager.requireYearGateStore(gates);
    if (!context.patch17Selected || !Number.isInteger(context.patch17Selected.openIndex) ||
        !Number.isInteger(context.patch17Selected.closeIndex)) {
      throw new BootstrapStageError('Discovery 21 exige li indices del year selectet per Patch 17.');
    }
    const openIndex = context.patch17Selected.openIndex;
    const closeIndex = context.patch17Selected.closeIndex;
    const gapCount = closeIndex - openIndex;
    let internalGateIndex = null;
    for (let gateIndex = openIndex + 1; gateIndex < closeIndex; gateIndex += 1) {
      if (gates[gateIndex] === calculationDay) {
        if (internalGateIndex !== null) {
          throw new BootstrapStageError('Li calculation-day ne posse corresponder a plu quam un gate intern in Discovery 21.');
        }
        internalGateIndex = gateIndex;
      }
    }
    const internalGateOffset = internalGateIndex === null ? null : internalGateIndex - openIndex;
    const semanticSauce = {
      bowls: context.patch20SemanticSauceBowls.slice(),
      orderAt46Latch: context.patch20SemanticOrderAt46Latch.slice()
    };

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery21CutletPartitionHandler';
    context.phase = 'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION';
    context.branchTrace.push('DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION');
    context.legacyCutletGapCount = gapCount;
    context.legacyCutletInternalGateIndex = internalGateIndex;
    context.legacyCutletInternalGateOffset = internalGateOffset;

    const selected = this.legacyAdapter.selectAllPositive(semanticSauce, gapCount);
    context.legacyCutletCountCandidates = selected.cutletCountCandidates.slice();
    context.legacyCutletCountStream = { ...selected.countStream };
    context.legacyCutletCountSelectedOrdinal = selected.cutletCountSelectedOrdinal;
    context.legacyCutletCount = selected.cutletCount;
    context.legacyCutletFamilyCount = selected.familyCount;
    context.legacyCutletPartitionStream = { ...selected.partitionStream };
    context.legacyCutletSelectedRank = selected.selectedRank;
    context.legacyCutletSelectedPartition = selected.partition.slice();
    let cumulative = 0;
    context.legacyCutletPrefixSums = selected.partition.map((part) => {
      cumulative += part;
      return cumulative;
    });
    context.legacyCutletInternalBoundaryHit = internalGateOffset === null ? null :
      context.legacyCutletPrefixSums.includes(internalGateOffset);
    context.legacyCutletIgnoredInternalGate = internalGateOffset !== null;
    context.status = 'DISCOVERY_21_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery21.allPositiveFamily.calls');
    this.metricsManager.bump(context, 'discovery21.cutletCountSelection.calls');
    this.metricsManager.bump(context, 'discovery21.partitionSelection.calls');
    if (internalGateOffset !== null) this.metricsManager.bump(context, 'discovery21.internalGateIgnored.calls');
    return {
      gapCount,
      cutletCount: selected.cutletCount,
      familyCount: selected.familyCount,
      selectedRank: selected.selectedRank,
      partition: selected.partition.slice(),
      internalGateIndex,
      internalGateOffset,
      prefixSums: context.legacyCutletPrefixSums.slice(),
      internalBoundaryHit: context.legacyCutletInternalBoundaryHit
    };
  }
}

class CutletPartitionPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context) {
    this.validationManager.requireDiscovery21Result(context);
    const gapCount = context.legacyCutletGapCount;
    const cutletCount = context.legacyCutletCount;
    const internalGateIndex = context.legacyCutletInternalGateIndex;
    const internalGateOffset = context.legacyCutletInternalGateOffset;
    if (!Number.isInteger(gapCount) || !Number.isInteger(cutletCount) || cutletCount < 1 || cutletCount > gapCount) {
      throw new BootstrapStageError('Patch 21 exige li gap count e cutlet count ja selectet per Discovery 21.');
    }
    if (internalGateOffset !== null &&
        (!Number.isInteger(internalGateOffset) || internalGateOffset <= 0 || internalGateOffset >= gapCount)) {
      throw new BootstrapStageError('Patch 21 recivet un offset de gate quel ne es strictmen intern.');
    }

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'CutletPartitionPatchWrapper';
    context.phase = 'PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION';
    context.branchTrace.push('PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION');

    // Li selection raw de Discovery 21 resta un diagnostic real e complet; ne reparar ni re-unrankar li familie legacy.
    context.patch21LegacyDiagnosticPreserved = true;
    context.patch21LegacyFamilyCountDiagnostic = context.legacyCutletFamilyCount;
    context.patch21LegacySelectedRankDiagnostic = context.legacyCutletSelectedRank;
    context.patch21LegacyPartitionDiagnostic = context.legacyCutletSelectedPartition.slice();
    context.patch21LegacyPrefixSumsDiagnostic = context.legacyCutletPrefixSums.slice();
    context.patch21LegacyBoundaryHitDiagnostic = context.legacyCutletInternalBoundaryHit;

    let semanticFamilyCount;
    let semanticSelectedRank;
    let semanticPartition;
    let semanticPartitionStream;
    if (internalGateOffset === null) {
      // Sin gate intern li contract mandat un pass-through exact del partition raw, sin familie reparativ artificial.
      context.patch21FilteredFamilyUsed = false;
      context.patch21RawLegacyPassedThrough = true;
      semanticFamilyCount = context.legacyCutletFamilyCount;
      semanticSelectedRank = context.legacyCutletSelectedRank;
      semanticPartition = context.legacyCutletSelectedPartition.slice();
      semanticPartitionStream = { ...context.legacyCutletPartitionStream };
      this.metricsManager.bump(context, 'patch21.rawLegacyPassThrough.calls');
    } else {
      context.patch21FilteredFamilyUsed = true;
      context.patch21RawLegacyPassedThrough = false;
      const family = filteredCutletCompositions(gapCount, cutletCount, internalGateOffset);
      semanticFamilyCount = family.count();
      if (semanticFamilyCount < 1n) {
        throw new BootstrapStageError('Li familie legal de Patch 21 ne posse esser vacui por un gate intern valid.');
      }
      const semanticSauce = {
        bowls: context.patch20SemanticSauceBowls.slice(),
        orderAt46Latch: context.patch20SemanticOrderAt46Latch.slice()
      };
      semanticPartitionStream = cutletAnswerRingFromSauce(semanticSauce, 21n);
      const semanticPick = selectionDispatcherWithWideDetour(semanticPartitionStream, semanticFamilyCount);
      semanticSelectedRank = semanticPick.output;
      semanticPartition = family.unrank1(semanticSelectedRank);
      this.metricsManager.bump(context, 'patch21.filteredFamily.calls');
    }

    let cumulative = 0;
    const semanticPrefixSums = semanticPartition.map((part) => {
      cumulative += part;
      return cumulative;
    });
    const semanticBoundaryHit = internalGateOffset === null ? null : semanticPrefixSums.includes(internalGateOffset);
    if (internalGateOffset !== null && !semanticBoundaryHit) {
      throw new BootstrapStageError('Li partition semantic de Patch 21 manca li boundary intern obligatori.');
    }

    context.patch21SemanticPartitionStream = { ...semanticPartitionStream };
    context.patch21SemanticFamilyCount = semanticFamilyCount;
    context.patch21SemanticSelectedRank = semanticSelectedRank;
    context.patch21SemanticPartition = semanticPartition.slice();
    context.patch21SemanticPrefixSums = semanticPrefixSums.slice();
    context.patch21SemanticBoundaryHit = semanticBoundaryHit;
    context.patch21SelectionChangedFromLegacy = semanticPartition.length !== context.legacyCutletSelectedPartition.length ||
      semanticPartition.some((part, index) => part !== context.legacyCutletSelectedPartition[index]);
    context.status = 'PATCH_21_RESULT';
    this.metricsManager.bump(context, 'patch21.legacyDiagnosticPreserved.calls');
    this.metricsManager.bump(context, 'patch21.semanticPartitionSelection.calls');

    return {
      gapCount,
      cutletCount,
      internalGateIndex,
      internalGateOffset,
      familyCount: semanticFamilyCount,
      selectedRank: semanticSelectedRank,
      partition: semanticPartition.slice(),
      prefixSums: semanticPrefixSums.slice(),
      internalBoundaryHit: semanticBoundaryHit,
      filteredFamilyUsed: context.patch21FilteredFamilyUsed,
      rawLegacyPassedThrough: context.patch21RawLegacyPassedThrough,
      legacyDiagnostic: {
        familyCount: context.patch21LegacyFamilyCountDiagnostic,
        selectedRank: context.patch21LegacySelectedRankDiagnostic,
        partition: context.patch21LegacyPartitionDiagnostic.slice(),
        prefixSums: context.patch21LegacyPrefixSumsDiagnostic.slice(),
        internalBoundaryHit: context.patch21LegacyBoundaryHitDiagnostic
      }
    };
  }
}

function legacyNameRowWithRepeats(masterCount, itemCount) {
  if (!Number.isInteger(masterCount) || masterCount < 1) {
    throw new RangeError('Li generator legacy de nomes exige un master count positiv.');
  }
  if (!Number.isInteger(itemCount) || itemCount < 1) {
    throw new RangeError('Li generator legacy de nomes exige un item count positiv.');
  }
  const base = BigInt(masterCount);
  let totalCount = 1n;
  for (let position = 0; position < itemCount; position += 1) totalCount *= base;
  return Object.freeze({
    count() {
      return totalCount;
    },
    unrank1(rank1) {
      if (typeof rank1 !== 'bigint' || rank1 < 1n || rank1 > totalCount) {
        throw new RangeError('Li rank legacy de nomes es extra li familie con repetition.');
      }
      let rank0 = rank1 - 1n;
      const out = new Array(itemCount);
      for (let position = itemCount - 1; position >= 0; position -= 1) {
        out[position] = Number(rank0 % base) + 1;
        rank0 /= base;
      }
      return out;
    }
  });
}

function cutletNameAnswerRingFromSauce(sauceResult) {
  if (!sauceResult || !Array.isArray(sauceResult.bowls) || !Array.isArray(sauceResult.orderAt46Latch)) {
    throw new TypeError('Li selection de nomes de cutlet exige un structure sauce complet.');
  }
  const nextBowl = nextBowlFromOrderAt46Latch(sauceResult.orderAt46Latch, 5);
  return answerRingFromCurrentState(sauceResult.bowls, 5, nextBowl, 22n);
}

class LegacyRepeatedNameGenerator {
  select(sauceResult, masterIndices, itemCount) {
    if (!Array.isArray(masterIndices) || masterIndices.length < 1) {
      throw new TypeError('Li generator legacy de nomes exige un liste master de indices canonic.');
    }
    const seen = new Set();
    for (const index of masterIndices) {
      if (!Number.isInteger(index) || index < 1 || seen.has(index)) {
        throw new RangeError('Li liste master de nomes deve contener indices canonic distinct e positiv.');
      }
      seen.add(index);
    }
    if (!Number.isInteger(itemCount) || itemCount < 1 || itemCount > masterIndices.length) {
      throw new RangeError('Li quantitá de nomes legacy deve esser positiv e ne plu grand quam li catalog master.');
    }
    // Li errore historic tracta chascun position independentmen e talmen permisse que li sam indice canonic reapari.
    const family = legacyNameRowWithRepeats(masterIndices.length, itemCount);
    const stream = cutletNameAnswerRingFromSauce(sauceResult);
    const picked = selectionDispatcherWithWideDetour(stream, family.count());
    const ordinalRow = family.unrank1(picked.output);
    const nameIndices = ordinalRow.map((ordinal) => masterIndices[ordinal - 1]);
    return {
      familyCount: family.count(),
      stream,
      selectedRank: picked.output,
      ordinalRow,
      nameIndices
    };
  }
}

class Discovery22RepeatedNameHandler {
  constructor(validationManager, metricsManager, legacyGenerator) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyGenerator = legacyGenerator;
  }

  handle(context) {
    this.validationManager.requirePatch21Result(context);
    const masterIndices = SourceLanguageCatalog.cutlets.map((row) => row.canonicalIndex);
    const itemCount = context.patch21SemanticPartition.length;
    if (itemCount !== context.legacyCutletCount) {
      throw new BootstrapStageError('Discovery 22 exige que li quantitá de nomes corresponde exactmen al cutlet count semantic.');
    }
    const semanticSauce = {
      bowls: context.patch20SemanticSauceBowls.slice(),
      orderAt46Latch: context.patch20SemanticOrderAt46Latch.slice()
    };

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery22RepeatedNameHandler';
    context.phase = 'DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES';
    context.branchTrace.push('DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES');
    const selected = this.legacyGenerator.select(semanticSauce, masterIndices, itemCount);
    const hasRepeatedCanonicalIndex = new Set(selected.nameIndices).size !== selected.nameIndices.length;

    context.legacyCutletNameMasterIndices = masterIndices.slice();
    context.legacyCutletNameCount = itemCount;
    context.legacyCutletNameFamilyCount = selected.familyCount;
    context.legacyCutletNameStream = { ...selected.stream };
    context.legacyCutletNameSelectedRank = selected.selectedRank;
    context.legacyCutletNameIndices = selected.nameIndices.slice();
    context.legacyCutletNameHasRepeatedCanonicalIndex = hasRepeatedCanonicalIndex;
    context.legacyCutletNameUsedSemanticStructureSauce = true;
    context.legacyRepeatedNameGeneratorExecuted = true;
    context.status = 'DISCOVERY_22_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery22.repeatedNameGenerator.calls');
    this.metricsManager.bump(context, 'discovery22.nameSelection.calls');
    if (hasRepeatedCanonicalIndex) this.metricsManager.bump(context, 'discovery22.repeatedCanonicalIndex.calls');
    return {
      masterIndices: masterIndices.slice(),
      cutletCount: itemCount,
      familyCount: selected.familyCount,
      selectedRank: selected.selectedRank,
      nameIndices: selected.nameIndices.slice(),
      hasRepeatedCanonicalIndex,
      stream: { ...selected.stream }
    };
  }
}

function fallingFactorialDistinct(masterCount, itemCount) {
  if (!Number.isInteger(masterCount) || masterCount < 0) {
    throw new RangeError('Li master count por nomes distinct deve esser un integer non-negativ.');
  }
  if (!Number.isInteger(itemCount) || itemCount < 0 || itemCount > masterCount) {
    throw new RangeError('Li item count por nomes distinct deve esser inter zero e li master count.');
  }
  let total = 1n;
  for (let position = 0; position < itemCount; position += 1) {
    total *= BigInt(masterCount - position);
  }
  return total;
}

function partialPermutationUnrank(masterCount, itemCount, rank1) {
  const total = fallingFactorialDistinct(masterCount, itemCount);
  if (typeof rank1 !== 'bigint' || rank1 < 1n || rank1 > total) {
    throw new RangeError('Li rank de partial permutation es extra li familie distinct.');
  }
  const remaining = Array.from({ length: masterCount }, (_, index) => index + 1);
  const out = [];
  let rank = rank1;
  for (let position = 0; position < itemCount; position += 1) {
    const suffixLength = itemCount - position - 1;
    const block = fallingFactorialDistinct(remaining.length - 1, suffixLength);
    let selected = false;
    for (let candidate = 0; candidate < remaining.length; candidate += 1) {
      if (rank > block) {
        rank -= block;
      } else {
        out.push(remaining.splice(candidate, 1)[0]);
        selected = true;
        break;
      }
    }
    if (!selected) {
      throw new BootstrapStageError('Li unrank distinct ne posset selecter un bloc lexicografic valid.');
    }
  }
  return out;
}

class RepeatedNamePatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context) {
    this.validationManager.requireDiscovery22Result(context);
    const bad = context.legacyCutletNameIndices;
    const masterIndices = context.legacyCutletNameMasterIndices;
    const itemCount = context.legacyCutletNameCount;
    if (!Array.isArray(bad) || bad.length !== itemCount || !Array.isArray(masterIndices) || masterIndices.length < itemCount) {
      throw new BootstrapStageError('Patch 22 exige li candidate legacy e li master list complet de Discovery 22.');
    }
    const semanticSauce = {
      bowls: context.patch20SemanticSauceBowls.slice(),
      orderAt46Latch: context.patch20SemanticOrderAt46Latch.slice()
    };
    const stream = cutletNameAnswerRingFromSauce(semanticSauce);
    const distinctFamilyCount = fallingFactorialDistinct(masterIndices.length, itemCount);
    const picked = selectionDispatcherWithWideDetour(stream, distinctFamilyCount);
    const ordinalRow = partialPermutationUnrank(masterIndices.length, itemCount, picked.output);
    const correct = ordinalRow.map((ordinal) => masterIndices[ordinal - 1]);
    const identical = bad.length === correct.length && bad.every((value, index) => value === correct[index]);
    const semanticNameIndices = identical ? bad : correct;

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'RepeatedNamePatchWrapper';
    context.phase = 'PATCH_22_DISTINCT_PARTIAL_PERMUTATION_NAMES';
    context.branchTrace.push('PATCH_22_DISTINCT_PARTIAL_PERMUTATION_NAMES');
    context.patch22BadNameIndices = bad.slice();
    context.patch22CorrectNameIndices = correct.slice();
    context.patch22DistinctFamilyCount = distinctFamilyCount;
    context.patch22DistinctSelectedRank = picked.output;
    context.patch22DistinctOrdinalRow = ordinalRow.slice();
    context.patch22NameStream = { ...stream };
    context.patch22BadEqualsCorrect = identical;
    context.patch22ReturnedLegacyObject = identical;
    context.patch22SemanticNameIndices = semanticNameIndices;
    context.status = 'PATCH_22_RESULT';
    this.metricsManager.bump(context, 'patch22.legacyDiagnosticPreserved.calls');
    this.metricsManager.bump(context, 'patch22.distinctPartialPermutation.calls');
    if (identical) this.metricsManager.bump(context, 'patch22.legacyIdentityReturn.calls');
    else this.metricsManager.bump(context, 'patch22.correctedNameSelection.calls');

    return {
      masterIndices: masterIndices.slice(),
      cutletCount: itemCount,
      familyCount: distinctFamilyCount,
      selectedRank: picked.output,
      nameIndices: semanticNameIndices,
      badEqualsCorrect: identical,
      returnedLegacyObject: identical,
      legacyDiagnostic: {
        familyCount: context.legacyCutletNameFamilyCount,
        selectedRank: context.legacyCutletNameSelectedRank,
        nameIndices: bad.slice(),
        hasRepeatedCanonicalIndex: context.legacyCutletNameHasRepeatedCanonicalIndex
      },
      stream: { ...stream }
    };
  }
}


function legacyEnumerateConcreteMonthLengthWays(totalDays, monthCount, stopAfter) {
  if (!Number.isInteger(totalDays) || totalDays < 1) {
    throw new RangeError('Li API legacy de longores de mensus exige un total de dies positiv.');
  }
  if (!Number.isInteger(monthCount) || monthCount < 1) {
    throw new RangeError('Li API legacy de longores de mensus exige un quantitá de mensus positiv.');
  }
  if (stopAfter !== null && (!Number.isInteger(stopAfter) || stopAfter < 1)) {
    throw new RangeError('Li limite diagnostic del materialisation legacy deve esser un integer positiv o null.');
  }
  const minTotal = monthCount * 4;
  const maxTotal = monthCount * 123;
  if (totalDays < minTotal || totalDays > maxTotal) return { ways: [], exceededLimit: false };

  const ways = [];
  const prefix = new Array(monthCount);
  let exceededLimit = false;
  function visit(position, remaining) {
    if (exceededLimit) return;
    if (position === monthCount) {
      if (remaining === 0) {
        if (stopAfter !== null && ways.length >= stopAfter) {
          exceededLimit = true;
          return;
        }
        ways.push(prefix.slice());
      }
      return;
    }
    const slotsAfter = monthCount - position - 1;
    const minimumAfter = slotsAfter * 4;
    const maximumAfter = slotsAfter * 123;
    for (let length = 4; length <= 123; length += 1) {
      const nextRemaining = remaining - length;
      if (nextRemaining < minimumAfter) break;
      if (nextRemaining > maximumAfter) continue;
      prefix[position] = length;
      visit(position + 1, nextRemaining);
      if (exceededLimit) return;
    }
  }
  visit(0, totalDays);
  return { ways, exceededLimit };
}

function legacyMaterializeMonthLengthWays(totalDays, monthCount) {
  // Li scar historic retorna un Array concret con omni vias; it ne have null backend virtual.
  return legacyEnumerateConcreteMonthLengthWays(totalDays, monthCount, null).ways;
}

function monthCountAnswerRingFromSauce(sauceResult) {
  if (!sauceResult || !Array.isArray(sauceResult.bowls) || !Array.isArray(sauceResult.orderAt46Latch)) {
    throw new TypeError('Li selection del quantitá de mensus exige un structure sauce complet.');
  }
  const nextBowl = nextBowlFromOrderAt46Latch(sauceResult.orderAt46Latch, 3);
  return answerRingFromCurrentState(sauceResult.bowls, 3, nextBowl, 30n);
}

function monthLengthAnswerRingFromSauce(sauceResult) {
  if (!sauceResult || !Array.isArray(sauceResult.bowls) || !Array.isArray(sauceResult.orderAt46Latch)) {
    throw new TypeError('Li selection de longores de mensus exige un structure sauce complet.');
  }
  const nextBowl = nextBowlFromOrderAt46Latch(sauceResult.orderAt46Latch, 3);
  return answerRingFromCurrentState(sauceResult.bowls, 3, nextBowl, 31n);
}

function monthWeavingAnswerRingFromSauce(sauceResult) {
  if (!sauceResult || !Array.isArray(sauceResult.bowls) || !Array.isArray(sauceResult.orderAt46Latch)) {
    throw new TypeError('Li intertexe legacy de mensus exige un structure sauce complet.');
  }
  const nextBowl = nextBowlFromOrderAt46Latch(sauceResult.orderAt46Latch, 4);
  return answerRingFromCurrentState(sauceResult.bowls, 4, nextBowl, 32n);
}

function wrapMonth(j, monthCount) {
  if (!Number.isInteger(j) || !Number.isInteger(monthCount) || monthCount < 1) {
    throw new RangeError('wrapMonth exige indices integer e un quantitá positiv de mensus.');
  }
  return 1 + Number(regularMod(BigInt(j - 1), BigInt(monthCount)));
}

function legacyChooseEachDaySeparately(lengths, answerStream) {
  // Li scar historic fa un election local por chascun die e ne selecte un intertexe complet.
  if (!Array.isArray(lengths) || lengths.length < 1 ||
      lengths.some((length) => !Number.isInteger(length) || length < 1)) {
    throw new RangeError('Li chooser legacy exige longores positiv de mensus.');
  }
  const monthCount = lengths.length;
  const remaining = lengths.slice();
  const totalDays = lengths.reduce((sum, length) => sum + length, 0);
  const ghost = [];
  for (let dayPosition = 0; dayPosition < totalDays; dayPosition += 1) {
    const answer = ringAnswerAt(answerStream, BigInt(dayPosition));
    let monthId = 1 + Number(regularMod(answer - 1n, BigInt(monthCount)));
    while (remaining[monthId - 1] === 0) {
      monthId = wrapMonth(monthId + 1, monthCount);
    }
    ghost.push(monthId);
    remaining[monthId - 1] -= 1;
  }
  return ghost;
}

class LegacyMonthLengthAllWaysAPI {
  allWays(totalDays, monthCount) {
    return legacyMaterializeMonthLengthWays(totalDays, monthCount);
  }

  probeAllWays(totalDays, monthCount, probeLimit) {
    // Discovery 23 usa li sam enumeration concret ma arresta un probe diagnostic ante allocation gigant; ti cap ne es semantic.
    const probed = legacyEnumerateConcreteMonthLengthWays(totalDays, monthCount, probeLimit);
    return {
      ways: probed.ways,
      exceededLimit: probed.exceededLimit,
      concreteArrayContract: true
    };
  }
}

class Discovery23MonthLengthMaterializationHandler {
  constructor(validationManager, metricsManager, legacyApi) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyApi = legacyApi;
  }

  handle(context) {
    this.validationManager.requirePatch22Result(context);
    const year = context.patch18ResolvedYear;
    if (!year || typeof year !== 'object' || typeof year.openDay !== 'bigint' || typeof year.closeDay !== 'bigint') {
      throw new BootstrapStageError('Discovery 23 exige li year semantic resoluet del chain precedent.');
    }
    const yearLengthBig = year.closeDay - year.openDay;
    if (yearLengthBig < 1n || yearLengthBig > 5778n) {
      throw new BootstrapStageError('Discovery 23 exige un longore de year intra li limite semantic 5778.');
    }
    const yearLength = Number(yearLengthBig);
    let minMonths = Number((yearLengthBig + 122n) / 123n);
    if (minMonths < 3) minMonths = 3;
    let maxMonths = Number(yearLengthBig / 4n);
    if (maxMonths > 47) maxMonths = 47;
    if (minMonths > maxMonths) {
      throw new BootstrapStageError('Li limites legacy del quantitá de mensus es inconsistent por Discovery 23.');
    }
    const semanticSauce = {
      bowls: context.patch20SemanticSauceBowls.slice(),
      orderAt46Latch: context.patch20SemanticOrderAt46Latch.slice()
    };
    const countStream = monthCountAnswerRingFromSauce(semanticSauce);
    const countPick = selectionDispatcherWithWideDetour(countStream, BigInt(maxMonths - minMonths + 1));
    const monthCount = minMonths + Number(countPick.output - 1n);
    const lengthStream = monthLengthAnswerRingFromSauce(semanticSauce);
    const probeLimit = 2048;

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery23MonthLengthMaterializationHandler';
    context.phase = 'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS';
    context.branchTrace.push('DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS');

    // Li old API es executet realmen sur li request semantic, ma solmen quam probe capat por demonstrar li materialisation sin provocar OOM.
    const probe = this.legacyApi.probeAllWays(yearLength, monthCount, probeLimit);
    context.legacyMonthLengthYearLength = yearLengthBig;
    context.legacyMonthLengthMinMonths = minMonths;
    context.legacyMonthLengthMaxMonths = maxMonths;
    context.legacyMonthLengthCountStream = { ...countStream };
    context.legacyMonthLengthCountSelectedRank = countPick.output;
    context.legacyMonthLengthMonthCount = monthCount;
    context.legacyMonthLengthSelectionStream = { ...lengthStream };
    context.legacyMonthLengthApiContract = 'ALL_WAYS_CONCRETE_ARRAY';
    context.legacyMonthLengthProbeLimit = probeLimit;
    context.legacyMonthLengthProbeSample = probe.ways.map((row) => row.slice());
    context.legacyMonthLengthProbeExceededLimit = probe.exceededLimit;
    context.legacyMonthLengthConcreteArrayContract = probe.concreteArrayContract;
    context.legacyMonthLengthMaterializerExecuted = true;
    context.status = 'DISCOVERY_23_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery23.monthLengthConcreteApi.calls');
    this.metricsManager.bump(context, 'discovery23.monthLengthProbe.calls');
    if (probe.exceededLimit) this.metricsManager.bump(context, 'discovery23.monthLengthProbe.exceeded.calls');

    return {
      yearLength: yearLengthBig,
      minMonths,
      maxMonths,
      monthCount,
      countSelectedRank: countPick.output,
      countStream: { ...countStream },
      monthLengthStream: { ...lengthStream },
      apiContract: context.legacyMonthLengthApiContract,
      probeLimit,
      probeSampleCount: probe.ways.length,
      probeExceededLimit: probe.exceededLimit,
      concreteArrayContract: probe.concreteArrayContract,
      probeFirstWay: probe.ways.length > 0 ? probe.ways[0].slice() : null,
      probeLastStoredWay: probe.ways.length > 0 ? probe.ways[probe.ways.length - 1].slice() : null
    };
  }
}



class VirtualLegacyList {
  constructor(totalDays, monthCount) {
    if (!Number.isInteger(totalDays) || totalDays < 1) {
      throw new RangeError('VirtualLegacyList exige un total de dies positiv.');
    }
    if (!Number.isInteger(monthCount) || monthCount < 1) {
      throw new RangeError('VirtualLegacyList exige un quantitá de mensus positiv.');
    }
    this.totalDays = totalDays;
    this.monthCount = monthCount;
    this.minimumLength = 4;
    this.maximumLength = 123;
    this._countsBySlots = this._buildExactCountTable();
    this._exactCount = this._countsBySlots[monthCount][totalDays];
  }

  _buildExactCountTable() {
    // Li table usa un fenestre glissant exact: null floating-point e null materialisation del familie.
    const table = Array.from({ length: this.monthCount + 1 }, () => new Array(this.totalDays + 1).fill(0n));
    table[0][0] = 1n;
    for (let slots = 1; slots <= this.monthCount; slots += 1) {
      const previous = table[slots - 1];
      const current = table[slots];
      let window = 0n;
      for (let subtotal = 0; subtotal <= this.totalDays; subtotal += 1) {
        const entering = subtotal - this.minimumLength;
        if (entering >= 0) window += previous[entering];
        const leaving = subtotal - this.maximumLength - 1;
        if (leaving >= 0) window -= previous[leaving];
        current[subtotal] = window;
      }
    }
    return table;
  }

  count() {
    return this._exactCount;
  }

  itemAt1(rank1) {
    const familyCount = this.count();
    if (typeof rank1 !== 'bigint' || rank1 < 1n || rank1 > familyCount) {
      throw new RangeError('Li rank virtual de longores de mensus es extra li familie.');
    }
    let rank = rank1;
    let remaining = this.totalDays;
    const out = [];
    for (let position = 0; position < this.monthCount; position += 1) {
      const slotsAfter = this.monthCount - position - 1;
      let selected = false;
      for (let length = this.minimumLength; length <= this.maximumLength; length += 1) {
        const suffixTotal = remaining - length;
        let block = 0n;
        if (suffixTotal >= 0 && suffixTotal <= this.totalDays) {
          block = this._countsBySlots[slotsAfter][suffixTotal];
        }
        if (rank > block) {
          rank -= block;
        } else {
          out.push(length);
          remaining = suffixTotal;
          selected = true;
          break;
        }
      }
      if (!selected) {
        throw new BootstrapStageError('VirtualLegacyList ne posset selecter un bloc lexicografic valid.');
      }
    }
    if (remaining !== 0) {
      throw new BootstrapStageError('VirtualLegacyList finit con un subtotal non-zero.');
    }
    return out;
  }
}

class MonthLengthVirtualPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context) {
    this.validationManager.requireDiscovery23Result(context);
    const yearLengthBig = context.legacyMonthLengthYearLength;
    const monthCount = context.legacyMonthLengthMonthCount;
    if (typeof yearLengthBig !== 'bigint' || yearLengthBig < 1n || yearLengthBig > 5778n ||
        !Number.isInteger(monthCount) || monthCount < 1) {
      throw new BootstrapStageError('Patch 23 exige li request exact de longores preservat per Discovery 23.');
    }
    const virtualList = new VirtualLegacyList(Number(yearLengthBig), monthCount);
    const familyCount = virtualList.count();
    if (familyCount < 1n) {
      throw new BootstrapStageError('Patch 23 trova un familie virtual vacui por un month-count ja selectet.');
    }
    const stream = { ...context.legacyMonthLengthSelectionStream };
    const picked = selectionDispatcherWithWideDetour(stream, familyCount);
    const monthLengths = virtualList.itemAt1(picked.output);

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'MonthLengthVirtualPatchWrapper';
    context.phase = 'PATCH_23_VIRTUAL_MONTH_LENGTH_ALL_WAYS';
    context.branchTrace.push('PATCH_23_VIRTUAL_MONTH_LENGTH_ALL_WAYS');
    context.patch23LegacyApiContractDiagnostic = context.legacyMonthLengthApiContract;
    context.patch23LegacyMaterializerExecuted = context.legacyMonthLengthMaterializerExecuted === true;
    context.patch23LegacyProbeLimitDiagnostic = context.legacyMonthLengthProbeLimit;
    context.patch23LegacyProbeSampleCountDiagnostic = context.legacyMonthLengthProbeSample.length;
    context.patch23LegacyProbeExceededDiagnostic = context.legacyMonthLengthProbeExceededLimit;
    context.patch23VirtualList = virtualList;
    context.patch23VirtualFamilyCount = familyCount;
    context.patch23VirtualSelectedRank = picked.output;
    context.patch23SemanticMonthLengths = monthLengths.slice();
    context.patch23MonthLengthSelectionStream = { ...stream };
    context.patch23ApiContract = 'VIRTUAL_EXACT_COUNT_LEXICOGRAPHIC_UNRANK';
    context.status = 'PATCH_23_RESULT';
    this.metricsManager.bump(context, 'patch23.legacyConcreteDiagnosticPreserved.calls');
    this.metricsManager.bump(context, 'patch23.virtualExactCount.calls');
    this.metricsManager.bump(context, 'patch23.virtualLexicographicItemAt1.calls');

    return {
      yearLength: yearLengthBig,
      monthCount,
      apiContract: context.patch23ApiContract,
      allWays: virtualList,
      familyCount,
      selectedRank: picked.output,
      monthLengths: monthLengths.slice(),
      monthLengthStream: { ...stream },
      legacyDiagnostic: {
        apiContract: context.legacyMonthLengthApiContract,
        materializerExecuted: context.legacyMonthLengthMaterializerExecuted === true,
        probeLimit: context.legacyMonthLengthProbeLimit,
        probeSampleCount: context.legacyMonthLengthProbeSample.length,
        probeExceededLimit: context.legacyMonthLengthProbeExceededLimit,
        concreteArrayContract: context.legacyMonthLengthConcreteArrayContract
      }
    };
  }
}

class LegacyMonthWeavingAdapter {
  selectEachDay(sauceResult, monthLengths) {
    const stream = monthWeavingAnswerRingFromSauce(sauceResult);
    const ghost = legacyChooseEachDaySeparately(monthLengths, stream);
    return { stream, ghost };
  }
}

class Discovery24MonthWeavingHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context) {
    this.validationManager.requirePatch23Result(context);
    const monthLengths = context.patch23SemanticMonthLengths;
    if (!Array.isArray(monthLengths) || monthLengths.length < 1 ||
        monthLengths.some((length) => !Number.isInteger(length) || length < 1)) {
      throw new BootstrapStageError('Discovery 24 exige li longores semantic de Patch 23.');
    }
    const semanticSauce = {
      bowls: context.patch20SemanticSauceBowls.slice(),
      orderAt46Latch: context.patch20SemanticOrderAt46Latch.slice()
    };
    const selected = this.legacyAdapter.selectEachDay(semanticSauce, monthLengths);

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery24MonthWeavingHandler';
    context.phase = 'DISCOVERY_24_LEGACY_MONTH_CHOSEN_EACH_DAY';
    context.branchTrace.push('DISCOVERY_24_LEGACY_MONTH_CHOSEN_EACH_DAY');
    context.legacyMonthWeavingLengths = monthLengths.slice();
    context.legacyMonthWeavingAnswerStream = { ...selected.stream };
    context.legacyMonthWeavingGhost = selected.ghost.slice();
    context.legacyMonthWeavingSemantic = selected.ghost.slice();
    context.legacyMonthWeavingHelperExecuted = true;
    context.status = 'DISCOVERY_24_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery24.legacyChooseEachDaySeparately.calls');

    return {
      monthLengths: monthLengths.slice(),
      answerStream: { ...selected.stream },
      ghost: selected.ghost.slice(),
      monthWeaving: selected.ghost.slice(),
      helperExecuted: true
    };
  }
}

class LegalMonthWeavingDP {
  constructor(lengths) {
    if (!Array.isArray(lengths) || lengths.length < 1 ||
        lengths.some((length) => !Number.isInteger(length) || length < 1)) {
      throw new RangeError('LegalMonthWeavingDP exige longores positiv de mensus.');
    }
    this.lengths = lengths.slice();
    this.monthCount = lengths.length;
    this.totalDays = lengths.reduce((sum, length) => sum + length, 0);
    this._binomialMemo = new Map();
    this._futureWays = this._buildFutureWays();
    this._exactCount = null;
  }

  _binomial(n, k) {
    if (!Number.isInteger(n) || !Number.isInteger(k) || n < 0 || k < 0 || k > n) return 0n;
    const symmetric = k <= n - k ? k : n - k;
    const key = n + ':' + symmetric;
    if (this._binomialMemo.has(key)) return this._binomialMemo.get(key);
    let value = 1n;
    for (let i = 1; i <= symmetric; i += 1) {
      value = (value * BigInt(n - symmetric + i)) / BigInt(i);
    }
    this._binomialMemo.set(key, value);
    return value;
  }

  _buildFutureWays() {
    // Ti DP conta exactmen li insertion del mensus futur; li state x es li quantitá de simbols pos li unesim occurrence del maxim monthId ja apert.
    const table = Array.from(
      { length: this.monthCount + 1 },
      () => new Array(this.totalDays + 1).fill(0n)
    );
    for (let x = 0; x <= this.totalDays; x += 1) table[this.monthCount][x] = 1n;

    for (let openedUpTo = this.monthCount - 1; openedUpTo >= 1; openedUpTo -= 1) {
      const nextMultiplicity = this.lengths[openedUpTo];
      const current = table[openedUpTo];
      const next = table[openedUpTo + 1];
      if (nextMultiplicity === 1) {
        const constant = next[0];
        for (let x = 0; x <= this.totalDays; x += 1) current[x] = constant;
        continue;
      }

      let prefix = 0n;
      let combination = 1n;
      for (let x = 0; x <= this.totalDays; x += 1) {
        const y = x + nextMultiplicity - 1;
        if (y > this.totalDays) {
          current[x] = prefix;
          continue;
        }
        if (x > 0) {
          combination = (combination * BigInt(y - 1)) / BigInt(y - nextMultiplicity + 1);
        }
        prefix += combination * next[y];
        current[x] = prefix;
      }
    }
    return table;
  }

  _legalMove(remaining, openedUpTo, closedUpTo, monthId) {
    if (remaining[monthId - 1] === 0) return false;
    const alreadyOpened = remaining[monthId - 1] < this.lengths[monthId - 1];
    if (!alreadyOpened && monthId !== openedUpTo + 1) return false;
    const willClose = remaining[monthId - 1] === 1;
    if (willClose && monthId !== closedUpTo + 1) return false;
    return true;
  }

  _applyMove(remaining, openedUpTo, closedUpTo, monthId) {
    const next = remaining.slice();
    let nextOpened = openedUpTo;
    let nextClosed = closedUpTo;
    if (next[monthId - 1] === this.lengths[monthId - 1]) nextOpened = monthId;
    next[monthId - 1] -= 1;
    if (next[monthId - 1] === 0) nextClosed = monthId;
    return { remaining: next, openedUpTo: nextOpened, closedUpTo: nextClosed };
  }

  _activeLastOrderCount(remaining, openedUpTo, closedUpTo) {
    let firstActive = -1;
    for (let monthId = closedUpTo + 1; monthId <= openedUpTo; monthId += 1) {
      if (remaining[monthId - 1] > 0) {
        firstActive = monthId;
        break;
      }
    }
    if (firstActive < 0) return 1n;

    let prefixLength = remaining[firstActive - 1];
    let ways = 1n;
    for (let monthId = firstActive + 1; monthId <= openedUpTo; monthId += 1) {
      const multiplicity = remaining[monthId - 1];
      if (multiplicity < 1) {
        throw new BootstrapStageError('Li state activ de LegalMonthWeavingDP viola li ordre del ultim occurrences.');
      }
      ways *= this._binomial(prefixLength + multiplicity - 1, multiplicity - 1);
      prefixLength += multiplicity;
    }
    return ways;
  }

  _countCompletions(remaining, openedUpTo, closedUpTo) {
    let activeLength = 0;
    for (let monthId = closedUpTo + 1; monthId <= openedUpTo; monthId += 1) {
      activeLength += remaining[monthId - 1];
    }
    const activeWays = this._activeLastOrderCount(remaining, openedUpTo, closedUpTo);
    const futureWays = this._futureWays[openedUpTo][activeLength];
    return activeWays * futureWays;
  }

  count() {
    if (this._exactCount !== null) return this._exactCount;
    const initial = this.lengths.slice();
    const first = this._applyMove(initial, 0, 0, 1);
    this._exactCount = this._countCompletions(first.remaining, first.openedUpTo, first.closedUpTo);
    return this._exactCount;
  }

  unrank1(rank1) {
    const familyCount = this.count();
    if (typeof rank1 !== 'bigint' || rank1 < 1n || rank1 > familyCount) {
      throw new RangeError('Li rank de intertexe legal es extra li familie.');
    }
    let rank = rank1;
    let remaining = this.lengths.slice();
    let openedUpTo = 0;
    let closedUpTo = 0;
    const out = [];

    while (out.length < this.totalDays) {
      let selected = false;
      for (let monthId = 1; monthId <= this.monthCount; monthId += 1) {
        if (!this._legalMove(remaining, openedUpTo, closedUpTo, monthId)) continue;
        const next = this._applyMove(remaining, openedUpTo, closedUpTo, monthId);
        const block = this._countCompletions(next.remaining, next.openedUpTo, next.closedUpTo);
        if (rank > block) {
          rank -= block;
        } else {
          out.push(monthId);
          remaining = next.remaining;
          openedUpTo = next.openedUpTo;
          closedUpTo = next.closedUpTo;
          selected = true;
          break;
        }
      }
      if (!selected) {
        throw new BootstrapStageError('LegalMonthWeavingDP ne trova un move lexicografic legal por li rank restant.');
      }
    }
    return out;
  }
}

function compatibleMonthWeavingRank(answerStream, familyCount) {
  if (typeof familyCount !== 'bigint' || familyCount < 1n) {
    throw new RangeError('Li familie de intertexes legal deve haver un count positiv exact.');
  }
  return selectionDispatcherWithWideDetour(answerStream, familyCount).output;
}

function DPUnrankLegalWeaving(lengths, wantedRank, preparedFamily = null) {
  const family = preparedFamily === null ? new LegalMonthWeavingDP(lengths) : preparedFamily;
  if (!(family instanceof LegalMonthWeavingDP)) {
    throw new TypeError('DPUnrankLegalWeaving exige un backend LegalMonthWeavingDP valid.');
  }
  return family.unrank1(wantedRank);
}

class MonthWeavingPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context) {
    this.validationManager.requireDiscovery24Result(context);
    const monthLengths = context.legacyMonthWeavingLengths;
    const ghost = context.legacyMonthWeavingGhost;
    const answerStream = context.legacyMonthWeavingAnswerStream;
    if (!Array.isArray(monthLengths) || !Array.isArray(ghost) ||
        !answerStream || typeof answerStream.first !== 'bigint' || typeof answerStream.directionStep !== 'bigint') {
      throw new BootstrapStageError('Patch 24 exige li longores, ghost e answer ring preservat per Discovery 24.');
    }

    const family = new LegalMonthWeavingDP(monthLengths);
    const familyCount = family.count();
    const wantedRank = compatibleMonthWeavingRank(answerStream, familyCount);
    const correct = DPUnrankLegalWeaving(monthLengths, wantedRank, family);
    const ghostEqualsCorrect = ghost.length === correct.length && ghost.every((value, index) => value === correct[index]);
    const semantic = ghostEqualsCorrect ? ghost : correct;

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'MonthWeavingPatchWrapper';
    context.phase = 'PATCH_24_LEGAL_WHOLE_MONTH_WEAVING';
    context.branchTrace.push('PATCH_24_LEGAL_WHOLE_MONTH_WEAVING');
    context.patch24Ghost = ghost;
    context.patch24LegalFamily = family;
    context.patch24LegalFamilyCount = familyCount;
    context.patch24WantedRank = wantedRank;
    context.patch24CorrectMonthWeaving = correct.slice();
    context.patch24GhostEqualsCorrect = ghostEqualsCorrect;
    context.patch24ReturnedLegacyGhost = ghostEqualsCorrect;
    context.patch24SemanticMonthWeaving = semantic;
    context.legacyMonthWeavingSemantic = semantic;
    context.status = 'PATCH_24_RESULT';
    this.metricsManager.bump(context, 'patch24.legacyGhostPreserved.calls');
    this.metricsManager.bump(context, 'patch24.legalFamilyCount.calls');
    this.metricsManager.bump(context, 'patch24.wantedRank.calls');
    this.metricsManager.bump(context, 'patch24.DPUnrankLegalWeaving.calls');
    if (ghostEqualsCorrect) this.metricsManager.bump(context, 'patch24.legacyGhostIdentityReturn.calls');
    else this.metricsManager.bump(context, 'patch24.correctDetourReturn.calls');

    return {
      monthLengths: monthLengths.slice(),
      answerStream: { ...answerStream },
      ghost,
      familyCount,
      wantedRank,
      correct: correct.slice(),
      ghostEqualsCorrect,
      monthWeaving: semantic
    };
  }
}

function oldContiguousMonthDayGuess(weaving, targetPosition) {
  if (!Array.isArray(weaving) || weaving.length < 1) {
    throw new RangeError('Li intertexe legacy por day-in-month ne posse esser vacui.');
  }
  if (!Number.isInteger(targetPosition) || targetPosition < 1 || targetPosition > weaving.length) {
    throw new RangeError('Li position target legacy es extra li intertexe.');
  }
  const monthId = weaving[targetPosition - 1];
  const firstPosition = weaving.indexOf(monthId) + 1;
  return targetPosition - firstPosition + 1;
}

class LegacyContiguousMonthDayAdapter {
  guess(weaving, targetPosition) {
    return oldContiguousMonthDayGuess(weaving, targetPosition);
  }
}

class Discovery25ContiguousMonthDayHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, targetDay) {
    this.validationManager.requirePatch24Result(context);
    this.validationManager.requireExactInteger(targetDay);
    const weaving = context.patch24SemanticMonthWeaving;
    const year = context.patch18ResolvedYear;
    if (!Array.isArray(weaving) || weaving.length < 1 || !year || typeof year.openDay !== 'bigint') {
      throw new BootstrapStageError('Discovery 25 exige li intertexe semantic e li year resoluet de Patch 24.');
    }
    const targetPositionBig = targetDay - year.openDay;
    if (targetPositionBig < 1n || targetPositionBig > BigInt(weaving.length)) {
      throw new BootstrapStageError('Discovery 25 exige un target intra li positions del intertexe selectet.');
    }
    const targetPosition = Number(targetPositionBig);
    const monthId = weaving[targetPosition - 1];
    const firstPosition = weaving.indexOf(monthId) + 1;
    const guess = this.legacyAdapter.guess(weaving, targetPosition);

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery25ContiguousMonthDayHandler';
    context.phase = 'DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS';
    context.branchTrace.push('DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS');
    context.legacyMonthDayWeaving = weaving;
    context.legacyMonthDayTargetDay = targetDay;
    context.legacyMonthDayTargetPosition = targetPosition;
    context.legacyMonthDayMonthId = monthId;
    context.legacyMonthDayFirstPosition = firstPosition;
    context.legacyMonthDayGuess = guess;
    context.legacyMonthDaySemantic = guess;
    context.legacyMonthDayHelperExecuted = true;
    context.status = 'DISCOVERY_25_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery25.oldContiguousMonthDayGuess.calls');

    return {
      monthWeaving: weaving,
      targetDay,
      targetPosition,
      monthId,
      firstPosition,
      dayInMonth: guess,
      helperExecuted: true
    };
  }
}

function countMonthOccurrencesThroughTarget(weaving, targetPosition) {
  if (!Array.isArray(weaving) || weaving.length < 1) {
    throw new RangeError('Li intertexe por li occurrence count de day-in-month ne posse esser vacui.');
  }
  if (!Number.isInteger(targetPosition) || targetPosition < 1 || targetPosition > weaving.length) {
    throw new RangeError('Li position target por li occurrence count es extra li intertexe.');
  }
  const monthId = weaving[targetPosition - 1];
  let count = 0;
  for (let index = 0; index < targetPosition; index += 1) {
    if (weaving[index] === monthId) count += 1;
  }
  return count;
}

class MonthDayOccurrencePatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context) {
    this.validationManager.requireDiscovery25Result(context);
    const weaving = context.legacyMonthDayWeaving;
    const targetPosition = context.legacyMonthDayTargetPosition;
    const monthId = context.legacyMonthDayMonthId;
    const legacyGuess = context.legacyMonthDayGuess;
    if (!Array.isArray(weaving) || !Number.isInteger(targetPosition) || !Number.isInteger(monthId) ||
        !Number.isInteger(legacyGuess)) {
      throw new BootstrapStageError('Patch 25 exige li intertexe, position, monthId e guess legacy de Discovery 25.');
    }
    const correct = countMonthOccurrencesThroughTarget(weaving, targetPosition);

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'MonthDayOccurrencePatchWrapper';
    context.phase = 'PATCH_25_MONTH_DAY_OCCURRENCE_COUNT';
    context.branchTrace.push('PATCH_25_MONTH_DAY_OCCURRENCE_COUNT');
    context.patch25LegacyGuess = legacyGuess;
    context.patch25LegacyGuessPreserved = true;
    context.patch25MonthDayWeaving = weaving;
    context.patch25TargetPosition = targetPosition;
    context.patch25MonthId = monthId;
    context.patch25OccurrenceCount = correct;
    context.patch25SemanticMonthDay = correct;
    context.legacyMonthDaySemantic = correct;
    context.status = 'PATCH_25_RESULT';
    this.metricsManager.bump(context, 'patch25.legacyGuessPreserved.calls');
    this.metricsManager.bump(context, 'patch25.countMonthOccurrencesThroughTarget.calls');
    this.metricsManager.bump(context, 'patch25.semanticOverwrite.calls');

    return {
      monthWeaving: weaving,
      targetDay: context.legacyMonthDayTargetDay,
      targetPosition,
      monthId,
      legacyGuess,
      dayInMonth: correct
    };
  }
}


function legacyFindYearClosedOpeningInterval(anchor, targetDay, nextYear, previousYear) {
  let current = requireWalkYearRecord(anchor, 'Li anchor legacy por li interval annual cludet al opening gate');
  if (typeof targetDay !== 'bigint') {
    throw new TypeError('Li target-day del interval legacy deve esser un BigInt exact.');
  }
  const trace = [];
  while (targetDay > current.closeDay) {
    const before = current;
    current = patchedNextYear(current, nextYear);
    trace.push({ direction: 'next', fromNumber: before.number, toNumber: current.number, sharedGate: before.closeDay });
  }
  while (targetDay < current.openDay) {
    const before = current;
    current = patchedPreviousYear(current, previousYear);
    trace.push({ direction: 'previous', fromNumber: before.number, toNumber: current.number, sharedGate: before.openDay });
  }
  if (!(current.openDay <= targetDay && targetDay <= current.closeDay)) {
    throw new BootstrapStageError('Li interval legacy cludet al opening gate ne contene li target-day pos su caminada.');
  }
  return {
    year: { ...current },
    stepCount: BigInt(trace.length),
    trace: trace.map((step) => ({ ...step })),
    openingBoundaryAccepted: targetDay === current.openDay
  };
}

class LegacyOpeningGateIntervalAdapter {
  call(anchor, targetDay, yearWalkSource) {
    if (!yearWalkSource || typeof yearWalkSource.nextYear !== 'function' || typeof yearWalkSource.previousYear !== 'function') {
      throw new TypeError('Li adapter legacy del opening gate exige un fonte annual complet.');
    }
    return legacyFindYearClosedOpeningInterval(
      anchor,
      targetDay,
      (year) => yearWalkSource.nextYear({ ...year }),
      (year) => yearWalkSource.previousYear({ ...year })
    );
  }
}

class Discovery26OpeningGateIntervalHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, targetDay, yearWalkSource) {
    this.validationManager.requirePatch25Result(context);
    this.validationManager.requireDiscreteDay(targetDay);
    this.validationManager.requireYearWalkSource(yearWalkSource);
    const authoritativeYear = requireWalkYearRecord(context.patch18ResolvedYear, 'Li year authoritative ante Discovery 26');

    let ownershipAnchor = { ...authoritativeYear };
    let reanchoredToOpeningYear = false;
    if (targetDay === authoritativeYear.closeDay) {
      ownershipAnchor = patchedNextYear(
        authoritativeYear,
        (year) => yearWalkSource.nextYear({ ...year })
      );
      reanchoredToOpeningYear = true;
    }

    const legacy = this.legacyAdapter.call(ownershipAnchor, targetDay, yearWalkSource);

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery26OpeningGateIntervalHandler';
    context.phase = 'DISCOVERY_26_OPENING_GATE_WRONG_YEAR';
    context.branchTrace.push('DISCOVERY_26_OPENING_GATE_WRONG_YEAR');
    context.legacyOpeningGateTargetDay = targetDay;
    context.legacyOpeningGateAuthoritativeYear = { ...authoritativeYear };
    context.legacyOpeningGateOwnershipAnchor = { ...ownershipAnchor };
    context.legacyOpeningGateReanchoredToOpeningYear = reanchoredToOpeningYear;
    context.legacyOpeningGateClosedOpeningInterval = true;
    context.legacyOpeningGateBackwardUsesStrictLess = true;
    context.legacyOpeningGateWalkTrace = legacy.trace.map((step) => ({ ...step }));
    context.legacyOpeningGateWalkStepCount = legacy.stepCount;
    context.legacyOpeningGateBoundaryAccepted = legacy.openingBoundaryAccepted;
    context.legacyOpeningGateResolvedYear = { ...legacy.year };
    context.legacyOpeningGateSemanticYearNumber = legacy.year.number;
    context.status = 'DISCOVERY_26_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery26.legacyClosedOpeningInterval.calls');
    if (reanchoredToOpeningYear) this.metricsManager.bump(context, 'discovery26.openingOwnershipReanchor.calls');
    if (legacy.openingBoundaryAccepted) this.metricsManager.bump(context, 'discovery26.openingBoundaryAccepted.calls');

    return {
      targetDay,
      authoritativeYear: { ...authoritativeYear },
      ownershipAnchor: { ...ownershipAnchor },
      legacyYear: { ...legacy.year },
      semanticYearNumber: legacy.year.number,
      reanchoredToOpeningYear,
      openingBoundaryAccepted: legacy.openingBoundaryAccepted,
      stepCount: legacy.stepCount,
      trace: legacy.trace.map((step) => ({ ...step }))
    };
  }
}

function correctOpeningGateInterval(anchor, targetDay, nextYear, previousYear) {
  let current = requireWalkYearRecord(anchor, 'Li anchor reparat por li interval annual apert al opening gate');
  if (typeof targetDay !== 'bigint') {
    throw new TypeError('Li target-day del interval reparat deve esser un BigInt exact.');
  }
  const trace = [];
  while (targetDay > current.closeDay) {
    const before = current;
    current = patchedNextYear(current, nextYear);
    trace.push({ direction: 'next', fromNumber: before.number, toNumber: current.number, sharedGate: before.closeDay });
  }
  while (targetDay <= current.openDay) {
    const before = current;
    current = patchedPreviousYear(current, previousYear);
    trace.push({ direction: 'previous', fromNumber: before.number, toNumber: current.number, sharedGate: before.openDay });
  }
  if (!(current.openDay < targetDay && targetDay <= current.closeDay)) {
    throw new BootstrapStageError('Li interval reparat (open,close] ne contene li target-day pos su caminada.');
  }
  return {
    year: { ...current },
    stepCount: BigInt(trace.length),
    trace: trace.map((step) => ({ ...step })),
    openingBoundaryMovedBackward: trace.some((step) => step.direction === 'previous' && step.sharedGate === targetDay),
    authoritativeMembership: true
  };
}

class OpeningGateIntervalPatchWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, yearWalkSource) {
    this.validationManager.requireDiscovery26Result(context);
    this.validationManager.requireYearWalkSource(yearWalkSource);
    const targetDay = context.legacyOpeningGateTargetDay;
    const ownershipAnchor = context.legacyOpeningGateOwnershipAnchor;
    const legacyYear = context.legacyOpeningGateResolvedYear;
    if (typeof targetDay !== 'bigint' || !ownershipAnchor || !legacyYear) {
      throw new BootstrapStageError('Patch 26 exige target, ownership anchor e resultate legacy de Discovery 26.');
    }

    const correct = correctOpeningGateInterval(
      ownershipAnchor,
      targetDay,
      (year) => yearWalkSource.nextYear({ ...year }),
      (year) => yearWalkSource.previousYear({ ...year })
    );

    context.previousHandler = context.currentHandler;
    context.currentHandler = 'OpeningGateIntervalPatchWrapper';
    context.phase = 'PATCH_26_OPENING_GATE_PREVIOUS_YEAR';
    context.branchTrace.push('PATCH_26_OPENING_GATE_PREVIOUS_YEAR');
    context.patch26LegacyYear = { ...legacyYear };
    context.patch26LegacySemanticYearNumber = context.legacyOpeningGateSemanticYearNumber;
    context.patch26LegacyDiagnosticPreserved = true;
    context.patch26OwnershipAnchor = { ...ownershipAnchor };
    context.patch26BackwardUsesLessOrEqual = true;
    context.patch26AuthoritativeInterval = '(open,close]';
    context.patch26WalkTrace = correct.trace.map((step) => ({ ...step }));
    context.patch26WalkStepCount = correct.stepCount;
    context.patch26OpeningBoundaryMovedBackward = correct.openingBoundaryMovedBackward;
    context.patch26ResolvedYear = { ...correct.year };
    context.patch26SemanticYearNumber = correct.year.number;
    context.legacyOpeningGateSemanticYearNumber = correct.year.number;
    context.status = 'PATCH_26_RESULT';
    this.metricsManager.bump(context, 'patch26.legacyDiagnosticPreserved.calls');
    this.metricsManager.bump(context, 'patch26.correctOpeningGateInterval.calls');
    this.metricsManager.bump(context, 'patch26.semanticYearOverwrite.calls');
    if (correct.openingBoundaryMovedBackward) {
      this.metricsManager.bump(context, 'patch26.openingBoundaryMovedBackward.calls');
    }

    return {
      targetDay,
      ownershipAnchor: { ...ownershipAnchor },
      legacyYear: { ...legacyYear },
      legacySemanticYearNumber: context.patch26LegacySemanticYearNumber,
      year: { ...correct.year },
      semanticYearNumber: correct.year.number,
      stepCount: correct.stepCount,
      trace: correct.trace.map((step) => ({ ...step })),
      openingBoundaryMovedBackward: correct.openingBoundaryMovedBackward,
      authoritativeInterval: '(open,close]'
    };
  }
}

class LegacyRemainderAdapter {
  call(value) {
    return oldRemainder(value);
  }
}

class Discovery01RemainderHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, value) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireExactInteger(value);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery01RemainderHandler';
    context.phase = 'DISCOVERY_01_LEGACY_REMAINDER';
    context.branchTrace.push('DISCOVERY_01_OLD_REMAINDER');
    context.legacyRemainderInput = value;
    context.legacyRemainderOutput = this.legacyAdapter.call(value);
    context.status = 'DISCOVERY_01_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery01.legacyRemainder.calls');
    return context.legacyRemainderOutput;
  }
}

class Patch01SaveWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, value) {
    this.validationManager.requireDiscovery01Result(context);
    this.validationManager.requireExactInteger(value);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch01SaveWrapper';
    context.phase = 'PATCH_01_SAVE_ZERO_REMAP';
    context.branchTrace.push('PATCH_01_SAVE_ZERO_REMAP');
    context.patch01Input = value;
    context.patch01LegacyWasZero = context.legacyRemainderOutput === 0n;
    context.patch01Output = savePatch(value);
    context.status = 'PATCH_01_RESULT';
    this.metricsManager.bump(context, 'patch01.save.calls');
    return context.patch01Output;
  }
}

class LegacyDayTagAdapter {
  call(day) {
    return oldDayTag(day);
  }
}

class Discovery02DayTagHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, day) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireExactInteger(day);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery02DayTagHandler';
    context.phase = 'DISCOVERY_02_LEGACY_DAY_TAG';
    context.branchTrace.push('DISCOVERY_02_OLD_DAY_TAG');
    context.legacyDayTagInput = day;
    context.legacyDayTagOutput = this.legacyAdapter.call(day);
    context.status = 'DISCOVERY_02_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery02.legacyDayTag.calls');
    return context.legacyDayTagOutput;
  }
}

class Patch02DayTagWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, day) {
    this.validationManager.requireDiscovery02Result(context);
    this.validationManager.requireExactInteger(day);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch02DayTagWrapper';
    context.phase = 'PATCH_02_DAY_TAG_FOUNDATION_SCAR';
    context.branchTrace.push('PATCH_02_DAY_TAG_FOUNDATION_SCAR');
    context.patch02Input = day;
    context.patch02AddedParityUnit = day >= FOUNDATION_DAY_OLD;
    context.patch02FoundationGuardChecked = day === FOUNDATION_DAY_OLD;
    context.patch02Output = dayTagWithFoundationScar(day);
    context.status = 'PATCH_02_RESULT';
    this.metricsManager.bump(context, 'patch02.dayTag.calls');
    return context.patch02Output;
  }
}

class LegacyDistanceAdapter {
  call(calculationDay, targetDay) {
    return oldDistance(calculationDay, targetDay);
  }
}

class Discovery03DistanceHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, calculationDay, targetDay) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireExactInteger(calculationDay);
    this.validationManager.requireExactInteger(targetDay);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery03DistanceHandler';
    context.phase = 'DISCOVERY_03_LEGACY_DISTANCE';
    context.branchTrace.push('DISCOVERY_03_OLD_DISTANCE');
    context.legacyDistanceCalculationDay = calculationDay;
    context.legacyDistanceTargetDay = targetDay;
    context.legacyDistanceCalculationTag = dayTagWithFoundationScar(calculationDay);
    context.legacyDistanceTargetTag = dayTagWithFoundationScar(targetDay);
    context.legacyDistanceOutput = this.legacyAdapter.call(calculationDay, targetDay);
    context.status = 'DISCOVERY_03_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery03.legacyDistance.calls');
    return context.legacyDistanceOutput;
  }
}

class Patch03DistanceWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, calculationDay, targetDay) {
    this.validationManager.requireDiscovery03Result(context);
    this.validationManager.requireExactInteger(calculationDay);
    this.validationManager.requireExactInteger(targetDay);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch03DistanceWrapper';
    context.phase = 'PATCH_03_CHRONOLOGY_DETOUR';
    context.branchTrace.push('PATCH_03_CHRONOLOGY_DETOUR');
    context.patch03CalculationDay = calculationDay;
    context.patch03TargetDay = targetDay;
    context.patch03ChronologicalDistance = targetDay >= calculationDay
      ? targetDay - calculationDay
      : calculationDay - targetDay;
    context.patch03LegacyReplaced = context.legacyDistanceOutput !== context.patch03ChronologicalDistance;
    context.patch03DistanceBeforeInclusive = context.patch03LegacyReplaced
      ? context.patch03ChronologicalDistance
      : context.legacyDistanceOutput;
    context.patch03Output = distanceWithChronologyDetour(calculationDay, targetDay);
    if (context.patch03Output !== context.patch03DistanceBeforeInclusive + 1n) {
      throw new BootstrapStageError('Li detour de Patch 03 ne conserva li regul inclusiv local.');
    }
    context.status = 'PATCH_03_RESULT';
    this.metricsManager.bump(context, 'patch03.distance.calls');
    return context.patch03Output;
  }
}

class LegacyStoneMutationAdapter {
  call(index, state) {
    return mutateStonesWrong(index, state);
  }
}

class Discovery04StoneMutationHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, index, sourceState) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireExactInteger(index);
    this.validationManager.requireStoneState(sourceState);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery04StoneMutationHandler';
    context.phase = 'DISCOVERY_04_SEQUENTIAL_STONE_MUTATION';
    context.branchTrace.push('DISCOVERY_04_MUTATE_STONES_WRONG');
    context.legacyStoneIndex = index;
    context.legacyStoneInputBefore = {
      w: sourceState.w, b: sourceState.b, s: sourceState.s, m: sourceState.m, r: sourceState.r
    };
    const working = {
      w: sourceState.w, b: sourceState.b, s: sourceState.s, m: sourceState.m, r: sourceState.r
    };
    context.legacyStoneWorkingState = working;
    const result = this.legacyAdapter.call(index, working);
    context.legacyStoneReturnedSameObject = result === working;
    context.legacyStoneOutput = result;
    context.status = 'DISCOVERY_04_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery04.legacyStoneMutation.calls');
    return result;
  }
}

class Patch04StoneWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, index, sourceState) {
    this.validationManager.requireDiscovery04Result(context);
    this.validationManager.requireExactInteger(index);
    this.validationManager.requireStoneState(sourceState);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch04StoneWrapper';
    context.phase = 'PATCH_04_SNAPSHOT_OVERWRITE';
    context.branchTrace.push('PATCH_04_STONE_SNAPSHOT_OVERWRITE');
    context.patch04Index = index;
    context.patch04OldSnapshot = cloneStoneState(sourceState);
    context.patch04LegacyGarbageBeforeOverwrite = cloneStoneState(context.legacyStoneOutput);
    context.patch04LegacyCallPreserved = true;
    context.patch04Output = stonePatch(index, sourceState);
    context.status = 'PATCH_04_RESULT';
    this.metricsManager.bump(context, 'patch04.stoneSnapshot.calls');
    return context.patch04Output;
  }
}


class LegacyHiddenStorageAdapter {
  call(counts, stones) {
    return buildHiddenWithBackwardStorage(counts, stones);
  }
}

class Discovery05HiddenStorageHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, counts, stones) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireHiddenCounts(counts);
    this.validationManager.requireStoneTableForHidden(stones);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery05HiddenStorageHandler';
    context.phase = 'DISCOVERY_05_HIDDEN_BACKWARD_STORAGE';
    context.branchTrace.push('DISCOVERY_05_HIDDEN_BACKWARD_STORAGE');
    context.legacyHiddenCounts = {
      action: counts.action,
      target: counts.target,
      distance: counts.distance,
      connection: counts.connection,
      direction: counts.direction
    };
    context.legacyHiddenStorage = this.legacyAdapter.call(counts, stones);
    context.legacyHiddenNearestReadAsSlotOne = context.legacyHiddenStorage[1];
    context.legacyHiddenFarthestReadAsSlotSeven = context.legacyHiddenStorage[7];
    context.status = 'DISCOVERY_05_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery05.hiddenBackward.calls');
    return context.legacyHiddenStorage;
  }
}

class Patch05HiddenNearnessWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, k) {
    this.validationManager.requireDiscovery05Result(context);
    requireHiddenOrdinal(k, 'Li ordinal de hidden drop');
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch05HiddenNearnessWrapper';
    context.phase = 'PATCH_05_HIDDEN_NEARNESS_TRANSLATOR';
    context.branchTrace.push('PATCH_05_HIDDEN_NEARNESS_TRANSLATOR');
    context.patch05RequestedNearness = k;
    context.patch05PhysicalSlot = 8 - k;
    context.patch05StoragePreserved = true;
    context.patch05Output = hiddenByNearness(context.legacyHiddenStorage, k);
    context.status = 'PATCH_05_RESULT';
    this.metricsManager.bump(context, 'patch05.hiddenNearness.calls');
    return context.patch05Output;
  }
}

class LegacyPriorAdapter {
  call(dropStore, i, back) {
    return legacyPrior(dropStore, i, back);
  }
}

class Discovery06PriorHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, dropStore, i, back) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireDropStore(dropStore);
    this.validationManager.requireHistoryIndex(i, 'Li index current del visible drop');
    this.validationManager.requireHistoryIndex(back, 'Li retro-distance del history');
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery06PriorHandler';
    context.phase = 'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY';
    context.branchTrace.push('DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY');
    context.legacyPriorDropStore = dropStore;
    context.legacyPriorVisibleIndex = i;
    context.legacyPriorBack = back;
    context.legacyPriorSlot = i - back;
    context.legacyPriorSlotIsVisible = context.legacyPriorSlot >= 1;
    context.legacyPriorOutput = this.legacyAdapter.call(dropStore, i, back);
    context.status = 'DISCOVERY_06_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery06.legacyPrior.calls');
    return context.legacyPriorOutput;
  }
}

class Patch06PriorWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, dropStore, legacyHidden, i, back) {
    this.validationManager.requireDiscovery06Result(context);
    this.validationManager.requireDropStore(dropStore);
    this.validationManager.requireHistoryIndex(i, 'Li index current del visible drop');
    this.validationManager.requireHistoryIndex(back, 'Li retro-distance del history');
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch06PriorWrapper';
    context.phase = 'PATCH_06_PRIOR_HIDDEN_MAPPING';
    context.branchTrace.push('PATCH_06_PRIOR_HIDDEN_MAPPING');
    context.patch06HiddenStorage = legacyHidden;
    context.patch06PriorSlot = i - back;
    context.patch06LegacyVisibleCallUsed = context.patch06PriorSlot >= 1;
    context.patch06HiddenNearness = context.patch06PriorSlot >= 1 ? null : 1 - context.patch06PriorSlot;
    context.patch06Output = priorPatch(dropStore, legacyHidden, i, back);
    context.status = 'PATCH_06_RESULT';
    this.metricsManager.bump(context, 'patch06.prior.calls');
    return context.patch06Output;
  }
}

class LegacyGrindTableAdapter {
  call(grind) {
    return legacyGrindRow(grind);
  }
}

class Discovery07GrindIndexHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, grind) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireVisibleGrindIndex(grind);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery07GrindIndexHandler';
    context.phase = 'DISCOVERY_07_LEGACY_GRIND_INDEX';
    context.branchTrace.push('DISCOVERY_07_LEGACY_GRIND_INDEX');
    context.legacyGrindRequestedIndex = grind;
    context.legacyGrindPhysicalIndex = grind;
    context.legacyGrindOutput = this.legacyAdapter.call(grind);
    context.legacyGrindMissing = context.legacyGrindOutput === undefined;
    context.status = 'DISCOVERY_07_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery07.legacyGrindIndex.calls');
    return context.legacyGrindOutput;
  }
}

class Patch07GrindSentinelWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, grind) {
    this.validationManager.requireDiscovery07Result(context);
    this.validationManager.requireVisibleGrindIndex(grind);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch07GrindSentinelWrapper';
    context.phase = 'PATCH_07_GRIND_SENTINEL';
    context.branchTrace.push('PATCH_07_GRIND_SENTINEL');
    context.patch07RequestedIndex = grind;
    context.patch07PhysicalIndex = grind;
    context.patch07SentinelPreserved = GRIND_TABLE_WITH_SENTINEL[0] === null;
    if (!context.patch07SentinelPreserved) {
      throw new BootstrapStageError('Li sentinel de Patch 07 deve restar fisicmen in index 0.');
    }
    context.patch07Output = grindRowWithSentinel(grind);
    context.status = 'PATCH_07_RESULT';
    this.metricsManager.bump(context, 'patch07.grindSentinel.calls');
    return context.patch07Output;
  }
}

class LegacyPermutationOrderAdapter {
  call(drop) {
    return legacyBowlOrderFromDrop(drop);
  }
}

class Discovery08PermutationRankHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, drop) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireExactInteger(drop);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery08PermutationRankHandler';
    context.phase = 'DISCOVERY_08_LEGACY_PERMUTATION_RANK';
    context.branchTrace.push('DISCOVERY_08_ONE_BASED_AS_RANK0');
    context.legacyPermutationDrop = drop;
    context.legacyPermutationOneBased = regularMod(drop - 1n, 720n) + 1n;
    context.legacyPermutationRankPassedToUnrank0 = context.legacyPermutationOneBased;
    context.legacyPermutationOutput = this.legacyAdapter.call(drop);
    context.status = 'DISCOVERY_08_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery08.legacyPermutationRank.calls');
    return context.legacyPermutationOutput;
  }
}

class Patch08PermutationWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, drop) {
    this.validationManager.requireDiscovery08Result(context);
    this.validationManager.requireExactInteger(drop);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch08PermutationWrapper';
    context.phase = 'PATCH_08_ZERO_BASED_RANK_BRIDGE';
    context.branchTrace.push('PATCH_08_ZERO_BASED_RANK_BRIDGE');
    context.patch08Drop = drop;
    context.patch08OneBased = regularMod(drop - 1n, 720n) + 1n;
    context.patch08LegacyRank0 = context.patch08OneBased - 1n;
    context.patch08Output = orderPatchFromValue(drop);
    context.status = 'PATCH_08_RESULT';
    this.metricsManager.bump(context, 'patch08.permutationRank.calls');
    return context.patch08Output;
  }
}

class LegacyFixedPourAdapter {
  call(drop, index, oldBowls, stoneRow) {
    return legacyPoursToFixedBowlIds(drop, index, oldBowls, stoneRow);
  }
}

class Discovery09FixedPourHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, drop, index, oldBowls, stoneRow) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireExactInteger(drop);
    this.validationManager.requireVisibleDropIndex(index);
    this.validationManager.requireBowlVector(oldBowls);
    this.validationManager.requirePourStoneRow(stoneRow);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery09FixedPourHandler';
    context.phase = 'DISCOVERY_09_FIXED_BOWL_POURS';
    context.branchTrace.push('DISCOVERY_09_POURS_TO_FIXED_BOWL_IDS');
    context.legacyPourDrop = drop;
    context.legacyPourIndex = index;
    context.legacyPourOldBowls = oldBowls.slice();
    context.legacyPourStoneRow = { w: stoneRow.w, b: stoneRow.b, s: stoneRow.s };
    context.legacyPourFixedBowlIds = [1, 2, 3];
    context.legacyPourOutput = this.legacyAdapter.call(drop, index, oldBowls, stoneRow);
    context.legacyPourOrder = context.legacyPourOutput.order.slice();
    context.status = 'DISCOVERY_09_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery09.fixedPour.calls');
    return context.legacyPourOutput;
  }
}

class Patch09BowlAliasWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, drop, index, oldBowls, stoneRow) {
    this.validationManager.requireDiscovery09Result(context);
    this.validationManager.requireExactInteger(drop);
    this.validationManager.requireVisibleDropIndex(index);
    this.validationManager.requireBowlVector(oldBowls);
    this.validationManager.requirePourStoneRow(stoneRow);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch09BowlAliasWrapper';
    context.phase = 'PATCH_09_BOWL_ALIAS';
    context.branchTrace.push('PATCH_09_BOWL_ALIAS');
    context.patch09LegacyCallPreserved = true;
    const patched = poursThroughBowlAlias(drop, index, oldBowls, stoneRow);
    context.patch09BowlAlias = patched.bowlAlias.slice();
    context.patch09AliasedBowlIds = [patched.bowlAlias[1], patched.bowlAlias[2], patched.bowlAlias[3]];
    context.patch09Output = {
      order: patched.order.slice(),
      bowlAlias: patched.bowlAlias.slice(),
      pours: patched.pours.slice()
    };
    context.status = 'PATCH_09_RESULT';
    this.metricsManager.bump(context, 'patch09.bowlAlias.calls');
    return context.patch09Output;
  }
}

class LegacyInPlaceBowlAdapter {
  call(drop, index, bowls, stoneRow) {
    return legacyStirOneDropInPlace(drop, index, bowls, stoneRow);
  }
}

class Discovery10InPlaceBowlHandler {
  constructor(validationManager, metricsManager, legacyAdapter) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
    this.legacyAdapter = legacyAdapter;
  }

  handle(context, drop, index, sourceBowls, stoneRow) {
    this.validationManager.requireHistoricReadyContext(context);
    this.validationManager.requireExactInteger(drop);
    this.validationManager.requireVisibleDropIndex(index);
    this.validationManager.requireBowlVector(sourceBowls);
    this.validationManager.requireStoneState(stoneRow);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Discovery10InPlaceBowlHandler';
    context.phase = 'DISCOVERY_10_IN_PLACE_BOWL_CONTAMINATION';
    context.branchTrace.push('DISCOVERY_10_BOWLS_IN_PLACE');
    context.legacyBowlRoundDrop = drop;
    context.legacyBowlRoundIndex = index;
    context.legacyBowlRoundInputBefore = sourceBowls.slice();
    const working = sourceBowls.slice();
    context.legacyBowlRoundWorkingState = working;
    const result = this.legacyAdapter.call(drop, index, working, stoneRow);
    context.legacyBowlRoundReturnedSameObject = result.bowls === working;
    context.legacyBowlRoundOrder = result.order.slice();
    context.legacyBowlRoundPours = result.pours.slice();
    context.legacyBowlRoundOutput = result.bowls.slice();
    context.status = 'DISCOVERY_10_LEGACY_RESULT';
    this.metricsManager.bump(context, 'discovery10.inPlaceBowl.calls');
    return { order: result.order.slice(), pours: result.pours.slice(), bowls: result.bowls.slice() };
  }
}

class Patch10ShadowBowlWrapper {
  constructor(validationManager, metricsManager) {
    this.validationManager = validationManager;
    this.metricsManager = metricsManager;
  }

  repair(context, drop, index, sourceBowls, stoneRow) {
    this.validationManager.requireDiscovery10Result(context);
    this.validationManager.requireExactInteger(drop);
    this.validationManager.requireVisibleDropIndex(index);
    this.validationManager.requireBowlVector(sourceBowls);
    this.validationManager.requireStoneState(stoneRow);
    context.previousHandler = context.currentHandler;
    context.currentHandler = 'Patch10ShadowBowlWrapper';
    context.phase = 'PATCH_10_VAULT_PENDING_COMMIT';
    context.branchTrace.push('PATCH_10_VAULT_PENDING_COMMIT');
    const patched = stirOneDropViaShadow(drop, index, sourceBowls, stoneRow);
    context.patch10LegacyCallPreserved = true;
    context.patch10LegacyGarbage = {
      order: patched.legacyGarbage.order.slice(),
      pours: patched.legacyGarbage.pours.slice(),
      bowls: patched.legacyGarbage.bowls.slice()
    };
    context.patch10VaultOld = patched.vaultOld.slice();
    context.patch10Pending = patched.pending.slice();
    context.patch10CommitAfterAllSix = true;
    context.patch10Output = {
      order: patched.order.slice(),
      pours: patched.pours.slice(),
      bowls: patched.bowls.slice()
    };
    context.status = 'PATCH_10_RESULT';
    this.metricsManager.bump(context, 'patch10.shadowBowl.calls');
    return context.patch10Output;
  }
}

class BaseMonsterManager {
  constructor() {
    this.validationManager = new BaseValidationManager();
    this.metricsManager = new BaseMetricsManager();
    this.errorWrapper = new BaseErrorWrapper();
    this.dispatcher = new BaseDispatcher(this.validationManager, this.metricsManager, this.errorWrapper);
    this.legacyRemainderAdapter = new LegacyRemainderAdapter();
    this.discovery01RemainderHandler = new Discovery01RemainderHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyRemainderAdapter
    );
    this.patch01SaveWrapper = new Patch01SaveWrapper(this.validationManager, this.metricsManager);
    this.legacyDayTagAdapter = new LegacyDayTagAdapter();
    this.discovery02DayTagHandler = new Discovery02DayTagHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyDayTagAdapter
    );
    this.patch02DayTagWrapper = new Patch02DayTagWrapper(this.validationManager, this.metricsManager);
    this.legacyDistanceAdapter = new LegacyDistanceAdapter();
    this.discovery03DistanceHandler = new Discovery03DistanceHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyDistanceAdapter
    );
    this.patch03DistanceWrapper = new Patch03DistanceWrapper(this.validationManager, this.metricsManager);
    this.legacyStoneMutationAdapter = new LegacyStoneMutationAdapter();
    this.discovery04StoneMutationHandler = new Discovery04StoneMutationHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyStoneMutationAdapter
    );
    this.patch04StoneWrapper = new Patch04StoneWrapper(this.validationManager, this.metricsManager);
    this.legacyHiddenStorageAdapter = new LegacyHiddenStorageAdapter();
    this.discovery05HiddenStorageHandler = new Discovery05HiddenStorageHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyHiddenStorageAdapter
    );
    this.patch05HiddenNearnessWrapper = new Patch05HiddenNearnessWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyPriorAdapter = new LegacyPriorAdapter();
    this.discovery06PriorHandler = new Discovery06PriorHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyPriorAdapter
    );
    this.patch06PriorWrapper = new Patch06PriorWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyGrindTableAdapter = new LegacyGrindTableAdapter();
    this.discovery07GrindIndexHandler = new Discovery07GrindIndexHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyGrindTableAdapter
    );
    this.patch07GrindSentinelWrapper = new Patch07GrindSentinelWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyPermutationOrderAdapter = new LegacyPermutationOrderAdapter();
    this.discovery08PermutationRankHandler = new Discovery08PermutationRankHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyPermutationOrderAdapter
    );
    this.patch08PermutationWrapper = new Patch08PermutationWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyFixedPourAdapter = new LegacyFixedPourAdapter();
    this.discovery09FixedPourHandler = new Discovery09FixedPourHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyFixedPourAdapter
    );
    this.patch09BowlAliasWrapper = new Patch09BowlAliasWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyInPlaceBowlAdapter = new LegacyInPlaceBowlAdapter();
    this.discovery10InPlaceBowlHandler = new Discovery10InPlaceBowlHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyInPlaceBowlAdapter
    );
    this.patch10ShadowBowlWrapper = new Patch10ShadowBowlWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyOverwritableOrderMemoryAdapter = new LegacyOverwritableOrderMemoryAdapter();
    this.discovery11OverwrittenOrderHandler = new Discovery11OverwrittenOrderHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyOverwritableOrderMemoryAdapter
    );
    this.patch11OrderAt46LatchWrapper = new Patch11OrderAt46LatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyNextBowlAdapter = new LegacyNextBowlAdapter();
    this.discovery12NextBowlHandler = new Discovery12NextBowlHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyNextBowlAdapter
    );
    this.nextBowlPatchWrapper = new NextBowlPatchWrapper(
      this.validationManager,
      this.metricsManager,
      this.legacyNextBowlAdapter
    );
    this.legacyBiasedSelectionAdapter = new LegacyBiasedSelectionAdapter();
    this.discovery13BiasedSelectionHandler = new Discovery13BiasedSelectionHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyBiasedSelectionAdapter
    );
    this.selectionRejectionPatchWrapper = new SelectionRejectionPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyShortFamilyAssumptionAdapter = new LegacyShortFamilyAssumptionAdapter();
    this.discovery14WideSelectionHandler = new Discovery14WideSelectionHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyShortFamilyAssumptionAdapter
    );
    this.wideSelectionPatchWrapper = new WideSelectionPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyGateQuestionAdapter = new LegacyGateQuestionAdapter();
    this.discovery15NegativeGateQuestionHandler = new Discovery15NegativeGateQuestionHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyGateQuestionAdapter
    );
    this.negativeGateQuestionPatchWrapper = new NegativeGateQuestionPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyYearCandidateAdapter = new LegacyYearCandidateAdapter();
    this.discovery16LegacyYearCandidateHandler = new Discovery16LegacyYearCandidateHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyYearCandidateAdapter
    );
    this.yearCandidateCeilingPatchWrapper = new YearCandidateCeilingPatchWrapper(
      this.validationManager,
      this.metricsManager,
      this.legacyYearCandidateAdapter
    );
    this.discovery17Year5000TieHandler = new Discovery17Year5000TieHandler(
      this.validationManager,
      this.metricsManager
    );
    this.year5000TiePatchWrapper = new Year5000TiePatchWrapper(
      this.validationManager,
      this.metricsManager,
      this.legacyYearCandidateAdapter
    );
    this.legacyYearJumpAdapter = new LegacyYearJumpAdapter();
    this.discovery18YearJumpHandler = new Discovery18YearJumpHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyYearJumpAdapter
    );
    this.sequentialYearWalkPatchWrapper = new SequentialYearWalkPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    // Li cache historic apartene al manager e persiste inter invocations, ma su clave es intentionalmen solmen year.number.
    this.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER = new Map();
    this.legacyYearNumberCacheAdapter = new LegacyYearNumberCacheAdapter(
      this.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER
    );
    this.discovery19YearNumberCacheHandler = new Discovery19YearNumberCacheHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyYearNumberCacheAdapter
    );
    this.yearCacheActionGuardPatchWrapper = new YearCacheActionGuardPatchWrapper(
      this.validationManager,
      this.metricsManager,
      this.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER
    );
    this.legacyStructureSauceAdapter = new LegacyStructureSauceAdapter();
    this.legacyStructureSelectorAdapter = new LegacyStructureSelectorAdapter();
    this.discovery20StructureSauceHandler = new Discovery20StructureSauceHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyStructureSauceAdapter,
      this.legacyStructureSelectorAdapter
    );
    this.structureSaucePatchWrapper = new StructureSaucePatchWrapper(
      this.validationManager,
      this.metricsManager,
      this.legacyStructureSelectorAdapter
    );
    this.legacyCutletPartitionAdapter = new LegacyCutletPartitionAdapter();
    this.discovery21CutletPartitionHandler = new Discovery21CutletPartitionHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyCutletPartitionAdapter
    );
    this.cutletPartitionPatchWrapper = new CutletPartitionPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyRepeatedNameGenerator = new LegacyRepeatedNameGenerator();
    this.discovery22RepeatedNameHandler = new Discovery22RepeatedNameHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyRepeatedNameGenerator
    );
    this.repeatedNamePatchWrapper = new RepeatedNamePatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyMonthLengthAllWaysAPI = new LegacyMonthLengthAllWaysAPI();
    this.discovery23MonthLengthMaterializationHandler = new Discovery23MonthLengthMaterializationHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyMonthLengthAllWaysAPI
    );
    this.monthLengthVirtualPatchWrapper = new MonthLengthVirtualPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyMonthWeavingAdapter = new LegacyMonthWeavingAdapter();
    this.discovery24MonthWeavingHandler = new Discovery24MonthWeavingHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyMonthWeavingAdapter
    );
    this.monthWeavingPatchWrapper = new MonthWeavingPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyContiguousMonthDayAdapter = new LegacyContiguousMonthDayAdapter();
    this.discovery25ContiguousMonthDayHandler = new Discovery25ContiguousMonthDayHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyContiguousMonthDayAdapter
    );
    this.monthDayOccurrencePatchWrapper = new MonthDayOccurrencePatchWrapper(
      this.validationManager,
      this.metricsManager
    );
    this.legacyOpeningGateIntervalAdapter = new LegacyOpeningGateIntervalAdapter();
    this.discovery26OpeningGateIntervalHandler = new Discovery26OpeningGateIntervalHandler(
      this.validationManager,
      this.metricsManager,
      this.legacyOpeningGateIntervalAdapter
    );
    this.openingGateIntervalPatchWrapper = new OpeningGateIntervalPatchWrapper(
      this.validationManager,
      this.metricsManager
    );
  }

  prepare(calculationDay, targetDay) {
    const context = new BaseMonsterContext(calculationDay, targetDay);
    try {
      return this.dispatcher.dispatch(context);
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery01Remainder(calculationDay, targetDay, value) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery01RemainderHandler.handle(context, value);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch01Save(calculationDay, targetDay, value) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery01RemainderHandler.handle(context, value);
      const result = this.patch01SaveWrapper.repair(context, value);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery02DayTag(calculationDay, targetDay, day) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery02DayTagHandler.handle(context, day);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch02DayTag(calculationDay, targetDay, day) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery02DayTagHandler.handle(context, day);
      const result = this.patch02DayTagWrapper.repair(context, day);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery03Distance(calculationDay, targetDay) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery03DistanceHandler.handle(context, calculationDay, targetDay);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch03Distance(calculationDay, targetDay) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery03DistanceHandler.handle(context, calculationDay, targetDay);
      const result = this.patch03DistanceWrapper.repair(context, calculationDay, targetDay);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery04StoneMutation(calculationDay, targetDay, index, stoneState) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery04StoneMutationHandler.handle(context, index, stoneState);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch04StoneMutation(calculationDay, targetDay, index, stoneState) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery04StoneMutationHandler.handle(context, index, stoneState);
      const result = this.patch04StoneWrapper.repair(context, index, stoneState);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery05HiddenStorage(calculationDay, targetDay, counts, stones) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery05HiddenStorageHandler.handle(context, counts, stones);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch05HiddenNearness(calculationDay, targetDay, counts, stones, k) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery05HiddenStorageHandler.handle(context, counts, stones);
      const result = this.patch05HiddenNearnessWrapper.repair(context, k);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery06Prior(calculationDay, targetDay, dropStore, i, back) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery06PriorHandler.handle(context, dropStore, i, back);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch06Prior(calculationDay, targetDay, dropStore, legacyHidden, i, back) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery06PriorHandler.handle(context, dropStore, i, back);
      const result = this.patch06PriorWrapper.repair(context, dropStore, legacyHidden, i, back);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery07GrindIndex(calculationDay, targetDay, grind) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery07GrindIndexHandler.handle(context, grind);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch07GrindIndex(calculationDay, targetDay, grind) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery07GrindIndexHandler.handle(context, grind);
      const result = this.patch07GrindSentinelWrapper.repair(context, grind);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery08PermutationRank(calculationDay, targetDay, drop) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery08PermutationRankHandler.handle(context, drop);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch08PermutationRank(calculationDay, targetDay, drop) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery08PermutationRankHandler.handle(context, drop);
      const result = this.patch08PermutationWrapper.repair(context, drop);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery09FixedPours(calculationDay, targetDay, drop, index, oldBowls, stoneRow) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery09FixedPourHandler.handle(context, drop, index, oldBowls, stoneRow);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch09FixedPours(calculationDay, targetDay, drop, index, oldBowls, stoneRow) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery09FixedPourHandler.handle(context, drop, index, oldBowls, stoneRow);
      const result = this.patch09BowlAliasWrapper.repair(context, drop, index, oldBowls, stoneRow);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery10InPlaceBowls(calculationDay, targetDay, drop, index, bowls, stoneRow) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery10InPlaceBowlHandler.handle(context, drop, index, bowls, stoneRow);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch10InPlaceBowls(calculationDay, targetDay, drop, index, bowls, stoneRow) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery10InPlaceBowlHandler.handle(context, drop, index, bowls, stoneRow);
      const result = this.patch10ShadowBowlWrapper.repair(context, drop, index, bowls, stoneRow);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery11OverwrittenOrder(calculationDay, targetDay, counts, stones) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch11OrderAt46Latch(calculationDay, targetDay, counts, stones) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      const result = this.patch11OrderAt46LatchWrapper.repair(context, counts, stones);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery12NextBowl(calculationDay, targetDay, counts, stones, queriedBowlId) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      const latched = this.patch11OrderAt46LatchWrapper.repair(context, counts, stones);
      const result = this.discovery12NextBowlHandler.handle(context, latched.orderAt46Latch, queriedBowlId);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch12NextBowl(calculationDay, targetDay, counts, stones, queriedBowlId) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      const latched = this.patch11OrderAt46LatchWrapper.repair(context, counts, stones);
      this.discovery12NextBowlHandler.handle(context, latched.orderAt46Latch, queriedBowlId);
      const result = this.nextBowlPatchWrapper.repair(context, latched.orderAt46Latch, queriedBowlId);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery13BiasedSelection(calculationDay, targetDay, counts, stones, queriedBowlId, seal, N) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      const latched = this.patch11OrderAt46LatchWrapper.repair(context, counts, stones);
      this.discovery12NextBowlHandler.handle(context, latched.orderAt46Latch, queriedBowlId);
      const nextBowlId = this.nextBowlPatchWrapper.repair(context, latched.orderAt46Latch, queriedBowlId);
      const stream = answerRingFromCurrentState(
        context.patch11FinalBowls, queriedBowlId, nextBowlId, seal
      );
      const result = this.discovery13BiasedSelectionHandler.handle(context, stream, seal, N);
      return { result, context, stream: { first: stream.first, directionStep: stream.directionStep } };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch13SmallSelection(calculationDay, targetDay, counts, stones, queriedBowlId, seal, N) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      const latched = this.patch11OrderAt46LatchWrapper.repair(context, counts, stones);
      this.discovery12NextBowlHandler.handle(context, latched.orderAt46Latch, queriedBowlId);
      const nextBowlId = this.nextBowlPatchWrapper.repair(context, latched.orderAt46Latch, queriedBowlId);
      const stream = answerRingFromCurrentState(
        context.patch11FinalBowls, queriedBowlId, nextBowlId, seal
      );
      const result = this.selectionRejectionPatchWrapper.repair(context, stream, seal, N);
      return { result, context, stream: { first: stream.first, directionStep: stream.directionStep } };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery14WideSelection(calculationDay, targetDay, counts, stones, queriedBowlId, seal, N) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      const latched = this.patch11OrderAt46LatchWrapper.repair(context, counts, stones);
      this.discovery12NextBowlHandler.handle(context, latched.orderAt46Latch, queriedBowlId);
      const nextBowlId = this.nextBowlPatchWrapper.repair(context, latched.orderAt46Latch, queriedBowlId);
      const stream = answerRingFromCurrentState(
        context.patch11FinalBowls, queriedBowlId, nextBowlId, seal
      );
      const result = this.discovery14WideSelectionHandler.handle(context, stream, seal, N);
      return { result, context, stream: { first: stream.first, directionStep: stream.directionStep } };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch14Selection(calculationDay, targetDay, counts, stones, queriedBowlId, seal, N) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery11OverwrittenOrderHandler.handle(context, counts, stones);
      const latched = this.patch11OrderAt46LatchWrapper.repair(context, counts, stones);
      this.discovery12NextBowlHandler.handle(context, latched.orderAt46Latch, queriedBowlId);
      const nextBowlId = this.nextBowlPatchWrapper.repair(context, latched.orderAt46Latch, queriedBowlId);
      const stream = answerRingFromCurrentState(
        context.patch11FinalBowls, queriedBowlId, nextBowlId, seal
      );
      this.discovery14WideSelectionHandler.handle(context, stream, seal, N);
      const result = this.wideSelectionPatchWrapper.repair(context, stream, seal, N);
      return { result, context, stream: { first: stream.first, directionStep: stream.directionStep } };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery15GateQuestion(calculationDay, targetDay, signedStep) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      const result = this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch15GateQuestion(calculationDay, targetDay, signedStep) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      const result = this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery16YearCandidates(calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      const result = this.discovery16LegacyYearCandidateHandler.handle(
        context, gates, candidatePairs, selectionStream
      );
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch16YearCandidates(calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      // Discovery 16 resta un route separat: su sort/selection overlong ne es executet ante li filter semantic de Patch 16.
      const result = this.yearCandidateCeilingPatchWrapper.repair(
        context, gates, candidatePairs, selectionStream
      );
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery17Year5000Tie(calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      const result = this.discovery17Year5000TieHandler.handle(context, calculationDay);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch17Year5000Tie(calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      const result = this.year5000TiePatchWrapper.repair(context, selectionStream);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery18YearJump(calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      const result = this.discovery18YearJumpHandler.handle(context, targetDay);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch18YearJump(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, targetDay);
      const result = this.sequentialYearWalkPatchWrapper.repair(context, targetDay, yearWalkSource);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery19YearCache(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, targetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, targetDay, yearWalkSource);
      const result = this.discovery19YearNumberCacheHandler.handle(
        context, context.patch18ResolvedYear, calculationDay
      );
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch19YearCache(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, targetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, targetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, targetDay, yearWalkSource);
      // Li handler defectiv resta un route separat; li wrapper real-voca li lookup scar sin consumir su stale value.
      const result = this.yearCacheActionGuardPatchWrapper.repair(
        context, context.patch18ResolvedYear, calculationDay
      );
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery20StructureSauce(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      const result = this.discovery20StructureSauceHandler.handle(
        context, calculationDay, originalTargetDay, yearFirstDay
      );
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch20StructureSauce(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      // Discovery 20 resta un route defectiv separat; li patch real-voca oldStructureSauce quam ghost sin passar su resultate al selector.
      const result = this.structureSaucePatchWrapper.repair(
        context, calculationDay, originalTargetDay, yearFirstDay
      );
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery21CutletPartition(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      const result = this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch21CutletPartition(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      // Li route PATCH 21 executa prim li scar Discovery 21 complet; solmen poy li wrapper cambia li selection semantic.
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      const result = this.cutletPartitionPatchWrapper.repair(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery22RepeatedCutletNames(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      const result = this.discovery22RepeatedNameHandler.handle(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch22RepeatedCutletNames(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      // Li route PATCH 22 executa prim li generator old real e conserva su candidate quam bad diagnostic.
      this.discovery22RepeatedNameHandler.handle(context);
      const result = this.repeatedNamePatchWrapper.repair(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery23MonthLengthMaterialization(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      const result = this.discovery23MonthLengthMaterializationHandler.handle(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch23MonthLengthVirtualList(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      // Patch 23 conserva li scar concret: Discovery 23 executa su enumerator-probe real ante li backend virtual.
      this.discovery23MonthLengthMaterializationHandler.handle(context);
      const result = this.monthLengthVirtualPatchWrapper.repair(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery24MonthWeaving(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      this.discovery23MonthLengthMaterializationHandler.handle(context);
      this.monthLengthVirtualPatchWrapper.repair(context);
      const result = this.discovery24MonthWeavingHandler.handle(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch24MonthWeaving(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      this.discovery23MonthLengthMaterializationHandler.handle(context);
      this.monthLengthVirtualPatchWrapper.repair(context);
      // Li chooser legacy de Discovery 24 resta un scar activ e es executet realmen ante li detour legal.
      this.discovery24MonthWeavingHandler.handle(context);
      const result = this.monthWeavingPatchWrapper.repair(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery25ContiguousMonthDay(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      this.discovery23MonthLengthMaterializationHandler.handle(context);
      this.monthLengthVirtualPatchWrapper.repair(context);
      this.discovery24MonthWeavingHandler.handle(context);
      this.monthWeavingPatchWrapper.repair(context);
      const result = this.discovery25ContiguousMonthDayHandler.handle(context, originalTargetDay);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch25MonthDayOccurrence(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      this.discovery23MonthLengthMaterializationHandler.handle(context);
      this.monthLengthVirtualPatchWrapper.repair(context);
      this.discovery24MonthWeavingHandler.handle(context);
      this.monthWeavingPatchWrapper.repair(context);
      // Li guess contigui de Discovery 25 resta un scar activ e es executet realmen ante li overwrite.
      this.discovery25ContiguousMonthDayHandler.handle(context, originalTargetDay);
      const result = this.monthDayOccurrencePatchWrapper.repair(context);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executeDiscovery26OpeningGateInterval(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      this.discovery23MonthLengthMaterializationHandler.handle(context);
      this.monthLengthVirtualPatchWrapper.repair(context);
      this.discovery24MonthWeavingHandler.handle(context);
      this.monthWeavingPatchWrapper.repair(context);
      this.discovery25ContiguousMonthDayHandler.handle(context, originalTargetDay);
      this.monthDayOccurrencePatchWrapper.repair(context);
      const result = this.discovery26OpeningGateIntervalHandler.handle(context, originalTargetDay, yearWalkSource);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }

  executePatch26OpeningGateInterval(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  ) {
    const context = this.prepare(calculationDay, originalTargetDay);
    try {
      this.discovery15NegativeGateQuestionHandler.handle(context, signedStep);
      this.negativeGateQuestionPatchWrapper.repair(context, signedStep);
      this.yearCandidateCeilingPatchWrapper.repair(context, gates, candidatePairs, selectionStream);
      this.discovery17Year5000TieHandler.handle(context, calculationDay);
      this.year5000TiePatchWrapper.repair(context, selectionStream);
      this.discovery18YearJumpHandler.handle(context, originalTargetDay);
      this.sequentialYearWalkPatchWrapper.repair(context, originalTargetDay, yearWalkSource);
      this.yearCacheActionGuardPatchWrapper.repair(context, context.patch18ResolvedYear, calculationDay);
      const yearFirstDay = context.patch18ResolvedYear.openDay + 1n;
      this.structureSaucePatchWrapper.repair(context, calculationDay, originalTargetDay, yearFirstDay);
      this.discovery21CutletPartitionHandler.handle(context, calculationDay, gates);
      this.cutletPartitionPatchWrapper.repair(context);
      this.discovery22RepeatedNameHandler.handle(context);
      this.repeatedNamePatchWrapper.repair(context);
      this.discovery23MonthLengthMaterializationHandler.handle(context);
      this.monthLengthVirtualPatchWrapper.repair(context);
      this.discovery24MonthWeavingHandler.handle(context);
      this.monthWeavingPatchWrapper.repair(context);
      this.discovery25ContiguousMonthDayHandler.handle(context, originalTargetDay);
      this.monthDayOccurrencePatchWrapper.repair(context);
      // Li finder cludet de Discovery 26 resta un scar activ e es executet realmen ante li detour final.
      this.discovery26OpeningGateIntervalHandler.handle(context, originalTargetDay, yearWalkSource);
      const result = this.openingGateIntervalPatchWrapper.repair(context, yearWalkSource);
      return { result, context };
    } catch (error) {
      context.status = 'FAILED';
      context.lastError = this.errorWrapper.wrap(error, context.phase);
      throw context.lastError;
    }
  }
}

function createBootstrapContext(calculationDay, targetDay) {
  return new BaseMonsterManager().prepare(calculationDay, targetDay);
}

function discovery01LegacyRemainderThroughMonsterPath(calculationDay, targetDay, value) {
  return new BaseMonsterManager().executeDiscovery01Remainder(calculationDay, targetDay, value);
}

function historicRemainderThroughMonsterPath(calculationDay, targetDay, value) {
  return new BaseMonsterManager().executePatch01Save(calculationDay, targetDay, value);
}

function discovery02LegacyDayTagThroughMonsterPath(calculationDay, targetDay, day) {
  return new BaseMonsterManager().executeDiscovery02DayTag(calculationDay, targetDay, day);
}

function historicDayTagThroughMonsterPath(calculationDay, targetDay, day) {
  return new BaseMonsterManager().executePatch02DayTag(calculationDay, targetDay, day);
}

function discovery03LegacyDistanceThroughMonsterPath(calculationDay, targetDay) {
  return new BaseMonsterManager().executeDiscovery03Distance(calculationDay, targetDay);
}

function historicDistanceThroughMonsterPath(calculationDay, targetDay) {
  return new BaseMonsterManager().executePatch03Distance(calculationDay, targetDay);
}

function discovery04LegacyStoneMutationThroughMonsterPath(calculationDay, targetDay, index, stoneState) {
  return new BaseMonsterManager().executeDiscovery04StoneMutation(calculationDay, targetDay, index, stoneState);
}

function historicStoneMutationThroughMonsterPath(calculationDay, targetDay, index, stoneState) {
  return new BaseMonsterManager().executePatch04StoneMutation(calculationDay, targetDay, index, stoneState);
}

function discovery05LegacyHiddenStorageThroughMonsterPath(calculationDay, targetDay, counts, stones) {
  return new BaseMonsterManager().executeDiscovery05HiddenStorage(calculationDay, targetDay, counts, stones);
}

function historicHiddenByNearnessThroughMonsterPath(calculationDay, targetDay, counts, stones, k) {
  return new BaseMonsterManager().executePatch05HiddenNearness(calculationDay, targetDay, counts, stones, k);
}

function discovery06LegacyPriorThroughMonsterPath(calculationDay, targetDay, dropStore, i, back) {
  return new BaseMonsterManager().executeDiscovery06Prior(calculationDay, targetDay, dropStore, i, back);
}

function historicPriorThroughMonsterPath(calculationDay, targetDay, dropStore, legacyHidden, i, back) {
  return new BaseMonsterManager().executePatch06Prior(calculationDay, targetDay, dropStore, legacyHidden, i, back);
}

function discovery07LegacyGrindRowThroughMonsterPath(calculationDay, targetDay, grind) {
  return new BaseMonsterManager().executeDiscovery07GrindIndex(calculationDay, targetDay, grind);
}

function historicGrindRowThroughMonsterPath(calculationDay, targetDay, grind) {
  return new BaseMonsterManager().executePatch07GrindIndex(calculationDay, targetDay, grind);
}

function discovery08LegacyBowlOrderThroughMonsterPath(calculationDay, targetDay, drop) {
  return new BaseMonsterManager().executeDiscovery08PermutationRank(calculationDay, targetDay, drop);
}

function historicBowlOrderThroughMonsterPath(calculationDay, targetDay, drop) {
  return new BaseMonsterManager().executePatch08PermutationRank(calculationDay, targetDay, drop);
}

function discovery09LegacyFixedPoursThroughMonsterPath(calculationDay, targetDay, drop, index, oldBowls, stoneRow) {
  return new BaseMonsterManager().executeDiscovery09FixedPours(
    calculationDay, targetDay, drop, index, oldBowls, stoneRow
  );
}

function historicPoursThroughMonsterPath(calculationDay, targetDay, drop, index, oldBowls, stoneRow) {
  return new BaseMonsterManager().executePatch09FixedPours(
    calculationDay, targetDay, drop, index, oldBowls, stoneRow
  );
}

function discovery10LegacyInPlaceBowlsThroughMonsterPath(calculationDay, targetDay, drop, index, bowls, stoneRow) {
  return new BaseMonsterManager().executeDiscovery10InPlaceBowls(
    calculationDay, targetDay, drop, index, bowls, stoneRow
  );
}

function historicBowlRoundThroughMonsterPath(calculationDay, targetDay, drop, index, bowls, stoneRow) {
  return new BaseMonsterManager().executePatch10InPlaceBowls(
    calculationDay, targetDay, drop, index, bowls, stoneRow
  );
}

function discovery11LegacyOverwrittenOrderThroughMonsterPath(calculationDay, targetDay, counts, stones) {
  return new BaseMonsterManager().executeDiscovery11OverwrittenOrder(calculationDay, targetDay, counts, stones);
}

function historicOrderAt46ThroughMonsterPath(calculationDay, targetDay, counts, stones) {
  return new BaseMonsterManager().executePatch11OrderAt46Latch(calculationDay, targetDay, counts, stones);
}

function discovery12LegacyNextBowlThroughMonsterPath(calculationDay, targetDay, counts, stones, queriedBowlId) {
  return new BaseMonsterManager().executeDiscovery12NextBowl(
    calculationDay, targetDay, counts, stones, queriedBowlId
  );
}

function historicNextBowlThroughMonsterPath(calculationDay, targetDay, counts, stones, queriedBowlId) {
  return new BaseMonsterManager().executePatch12NextBowl(
    calculationDay, targetDay, counts, stones, queriedBowlId
  );
}

function discovery13LegacyBiasedSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
) {
  return new BaseMonsterManager().executeDiscovery13BiasedSelection(
    calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
  );
}

function historicSmallSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
) {
  return new BaseMonsterManager().executePatch13SmallSelection(
    calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
  );
}

function discovery14LegacyWideSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
) {
  return new BaseMonsterManager().executeDiscovery14WideSelection(
    calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
  );
}

function historicSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
) {
  return new BaseMonsterManager().executePatch14Selection(
    calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
  );
}

function discovery15LegacyGateQuestionThroughMonsterPath(calculationDay, targetDay, signedStep) {
  return new BaseMonsterManager().executeDiscovery15GateQuestion(calculationDay, targetDay, signedStep);
}

function historicGateQuestionThroughMonsterPath(calculationDay, targetDay, signedStep) {
  return new BaseMonsterManager().executePatch15GateQuestion(calculationDay, targetDay, signedStep);
}

function discovery16LegacyYearCandidatesThroughMonsterPath(
  calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
) {
  return new BaseMonsterManager().executeDiscovery16YearCandidates(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
  );
}

function historicYearCandidatesThroughMonsterPath(
  calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
) {
  return new BaseMonsterManager().executePatch16YearCandidates(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
  );
}

function discovery17LegacyYear5000TieThroughMonsterPath(
  calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
) {
  return new BaseMonsterManager().executeDiscovery17Year5000Tie(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
  );
}

function historicYear5000TieThroughMonsterPath(
  calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
) {
  return new BaseMonsterManager().executePatch17Year5000Tie(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
  );
}

function discovery18LegacyYearJumpThroughMonsterPath(
  calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
) {
  return new BaseMonsterManager().executeDiscovery18YearJump(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream
  );
}

function historicYearJumpThroughMonsterPath(
  calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  return new BaseMonsterManager().executePatch18YearJump(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function discovery19LegacyYearNumberCacheThroughMonsterPath(
  manager, calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 19 exige un BaseMonsterManager persistent quam proprietor del cache legacy.');
  }
  return manager.executeDiscovery19YearCache(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicYearNumberCacheThroughMonsterPath(
  manager, calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 19 exige un BaseMonsterManager persistent quam proprietor del sam bad-key cache.');
  }
  return manager.executePatch19YearCache(
    calculationDay, targetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function discovery20LegacyStructureSauceThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 20 exige un BaseMonsterManager persistent por li cache de Patch 19.');
  }
  return manager.executeDiscovery20StructureSauce(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicStructureSauceThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 20 exige un BaseMonsterManager persistent por li cache guardat precedent.');
  }
  return manager.executePatch20StructureSauce(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function discovery21LegacyCutletPartitionThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 21 exige un BaseMonsterManager persistent por li chain de cache precedent.');
  }
  return manager.executeDiscovery21CutletPartition(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicCutletPartitionThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 21 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executePatch21CutletPartition(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function discovery22LegacyRepeatedNamesThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 22 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executeDiscovery22RepeatedCutletNames(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicRepeatedNamesThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 22 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executePatch22RepeatedCutletNames(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function discovery23LegacyMonthLengthMaterializationThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 23 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executeDiscovery23MonthLengthMaterialization(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicMonthLengthVirtualListThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 23 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executePatch23MonthLengthVirtualList(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function discovery24LegacyMonthWeavingThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 24 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executeDiscovery24MonthWeaving(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicMonthWeavingThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 24 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executePatch24MonthWeaving(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}


function discovery25LegacyContiguousMonthDayThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 25 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executeDiscovery25ContiguousMonthDay(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicMonthDayOccurrenceThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 25 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executePatch25MonthDayOccurrence(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function discovery26LegacyOpeningGateIntervalThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Discovery 26 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executeDiscovery26OpeningGateInterval(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}

function historicOpeningGateIntervalThroughMonsterPath(
  manager, calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
) {
  if (!(manager instanceof BaseMonsterManager)) {
    throw new TypeError('Patch 26 exige un BaseMonsterManager persistent por li chain historic precedent.');
  }
  return manager.executePatch26OpeningGateInterval(
    calculationDay, originalTargetDay, signedStep, gates, candidatePairs, selectionStream, yearWalkSource
  );
}


const STAGE54_YEAR_MIN_DAYS = 252n;
const STAGE54_YEAR_MAX_DAYS = 5778n;
const STAGE54_LEGACY_YEAR_MAX_DAYS = 5781n;
const STAGE54_MIN_GATE_GAPS = 6n;

function stage54RequireDay(value, label) {
  if (typeof value !== 'bigint') {
    throw new TypeError(label + ' deve esser un BigInt exact.');
  }
  return value;
}

function stage54CloneYear(year) {
  if (!year || typeof year !== 'object') throw new TypeError('Li year integrat deve esser un object.');
  const clone = {
    number: year.number,
    openDay: year.openDay,
    firstDay: year.firstDay,
    closeDay: year.closeDay
  };
  if (typeof year.openGateIndex === 'bigint') clone.openGateIndex = year.openGateIndex;
  if (typeof year.closeGateIndex === 'bigint') clone.closeGateIndex = year.closeGateIndex;
  return clone;
}

function stage54ArraysEqual(left, right) {
  return Array.isArray(left) && Array.isArray(right) && left.length === right.length &&
    left.every((value, index) => value === right[index]);
}

function sauceWithScars(calculationDay, targetDay) {
  stage54RequireDay(calculationDay, 'Li calculation-day del sauce final');
  stage54RequireDay(targetDay, 'Li target-day del sauce final');
  let programCounter = 0;
  let counts = null;
  let stones = null;
  let duplicateHidden = null;
  let result = null;
  const trace = [];
  const compatibility = Object.freeze({
    useLegacyRemainder: true,
    useLegacyDayTag: true,
    useLegacyDistance: true,
    useBackwardHiddenStorage: true,
    useAliasPours: true,
    useShadowBowls: true,
    useLatchedQueryOrder: true
  });
  while (true) {
    switch (programCounter) {
      case 0:
        trace.push('SAUCE_ENTRY');
        programCounter = 10;
        break;
      case 10:
        counts = structureSauceCountsFromDays(calculationDay, targetDay);
        trace.push('PATCHED_COUNTS');
        programCounter = 20;
        break;
      case 20:
        stones = getStoneTableThroughLegacyBuilder();
        trace.push('STONES_THROUGH_LEGACY_BUILDER');
        programCounter = 30;
        break;
      case 30:
        // Li copia duplicat es validation/diagnostic; li path authoritative infra executa denov li sam storage retrograd.
        duplicateHidden = buildHiddenWithBackwardStorage(counts, stones);
        hiddenByNearness(duplicateHidden, 1);
        hiddenByNearness(duplicateHidden, 7);
        trace.push('BACKWARD_HIDDEN_STORAGE_AND_PATCHED_PRIOR_READY');
        programCounter = 40;
        break;
      case 40:
        // Ti unic call conserva li path legacy overwritable e executa 46 drops, permutations, aliases, shadow commits e 12 post-stirs.
        result = sauceWithOrderAt46Latch(counts, stones);
        trace.push('VISIBLE_46_ALIAS_SHADOW_LATCH_POST12');
        programCounter = 50;
        break;
      case 50: {
        if (!stage54ArraysEqual(result.hiddenBackward, duplicateHidden)) {
          throw new BootstrapStageError('Li validation duplicat del hidden storage final diverge del path authoritative.');
        }
        const nextDiagnostics = [];
        for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
          const legacyNext = oldNextBowlFixedName(bowlId);
          const semanticNext = nextBowlFromOrderAt46Latch(result.orderAt46Latch, bowlId);
          nextDiagnostics.push(Object.freeze({ bowlId, legacyNext, semanticNext }));
        }
        trace.push('QUERY_THROUGH_LATCHED_ORDER');
        return Object.freeze({
          counts,
          stones: Object.freeze(stones.map((row) => Object.freeze({ ...row }))),
          hiddenBackward: Object.freeze(result.hiddenBackward.slice()),
          drops: Object.freeze(result.drops.slice()),
          bowlsAfterDrops: Object.freeze(result.bowlsAfterDrops.slice()),
          bowls: Object.freeze(result.bowls.slice()),
          orderAt46Latch: Object.freeze(result.orderAt46Latch.slice()),
          orderAt46LatchWriteCount: result.orderAt46LatchWriteCount,
          postStirOrderDiagnostic: Object.freeze(result.lastPostStirOrder.slice()),
          legacyQueryOrderDiagnostic: Object.freeze(result.legacyGarbage.queryOrder.slice()),
          queryOrder: Object.freeze(result.queryOrder.slice()),
          nextDiagnostics: Object.freeze(nextDiagnostics),
          compatibility,
          stateMachineTrace: Object.freeze(trace.slice())
        });
      }
      default:
        throw new BootstrapStageError('Li state-machine del sauce final atinge un program counter ínconosset.');
    }
  }
}

function sauceWithScarsStage56(calculationDay, targetDay) {
  stage54RequireDay(calculationDay, 'Li calculation-day del sauce Stage 56');
  stage54RequireDay(targetDay, 'Li target-day del sauce Stage 56');
  let programCounter = 0;
  let counts = null;
  let stones = null;
  let duplicateHidden = null;
  let result = null;
  const trace = [];
  const compatibility = Object.freeze({
    useLegacyRemainder: true,
    useLegacyDayTag: true,
    useLegacyDistance: true,
    useBackwardHiddenStorage: true,
    useAliasPours: true,
    useShadowBowls: true,
    useLatchedQueryOrder: true,
    useStage56RawBowlSumDetour: true
  });
  while (true) {
    switch (programCounter) {
      case 0:
        trace.push('SAUCE_STAGE56_ENTRY');
        programCounter = 10;
        break;
      case 10:
        counts = structureSauceCountsFromDays(calculationDay, targetDay);
        trace.push('PATCHED_COUNTS');
        programCounter = 20;
        break;
      case 20:
        stones = getStoneTableThroughLegacyBuilder();
        trace.push('STONES_THROUGH_LEGACY_BUILDER');
        programCounter = 30;
        break;
      case 30:
        duplicateHidden = buildHiddenWithBackwardStorage(counts, stones);
        hiddenByNearness(duplicateHidden, 1);
        hiddenByNearness(duplicateHidden, 7);
        trace.push('BACKWARD_HIDDEN_STORAGE_AND_PATCHED_PRIOR_READY');
        programCounter = 40;
        break;
      case 40:
        result = sauceWithStage56RawBowlSumDetour(counts, stones);
        trace.push('LEGACY_POST12_GHOST_THEN_STAGE56_RAW_SUM_POST12');
        programCounter = 50;
        break;
      case 50: {
        if (!stage54ArraysEqual(result.hiddenBackward, duplicateHidden)) {
          throw new BootstrapStageError('Li validation duplicat del hidden storage Stage 56 diverge del path authoritative.');
        }
        const nextDiagnostics = [];
        for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
          const legacyNext = oldNextBowlFixedName(bowlId);
          const semanticNext = nextBowlFromOrderAt46Latch(result.orderAt46Latch, bowlId);
          nextDiagnostics.push(Object.freeze({ bowlId, legacyNext, semanticNext }));
        }
        trace.push('QUERY_THROUGH_LATCHED_ORDER');
        return Object.freeze({
          counts,
          stones: Object.freeze(stones.map((row) => Object.freeze({ ...row }))),
          hiddenBackward: Object.freeze(result.hiddenBackward.slice()),
          drops: Object.freeze(result.drops.slice()),
          bowlsAfterDrops: Object.freeze(result.bowlsAfterDrops.slice()),
          bowls: Object.freeze(result.bowls.slice()),
          stage56HistoricalBowls: Object.freeze(result.stage56HistoricalBowls.slice()),
          orderAt46Latch: Object.freeze(result.orderAt46Latch.slice()),
          orderAt46LatchWriteCount: result.orderAt46LatchWriteCount,
          postStirOrderDiagnostic: Object.freeze(result.lastPostStirOrder.slice()),
          legacyQueryOrderDiagnostic: Object.freeze(result.legacyGarbage.queryOrder.slice()),
          queryOrder: Object.freeze(result.queryOrder.slice()),
          nextDiagnostics: Object.freeze(nextDiagnostics),
          stage56PostStirContext: result.stage56PostStirContext,
          stage56RawBowlSumApplied: true,
          compatibility,
          stateMachineTrace: Object.freeze(trace.slice())
        });
      }
      default:
        throw new BootstrapStageError('Li state-machine del sauce Stage 56 atinge un program counter ínconosset.');
    }
  }
}

function stage54AnswerRingWithScar(sauceResult, bowlId, seal, context, label) {
  if (!sauceResult || !Array.isArray(sauceResult.bowls) || !Array.isArray(sauceResult.orderAt46Latch)) {
    throw new TypeError('Li question final exige un sauce complet.');
  }
  const legacyNext = oldNextBowlFixedName(bowlId);
  const semanticNext = nextBowlFromOrderAt46Latch(sauceResult.orderAt46Latch, bowlId);
  const stream = answerRingFromCurrentState(sauceResult.bowls, bowlId, semanticNext, seal);
  if (context) {
    if (!context.answerStreamsBySeal) context.answerStreamsBySeal = Object.create(null);
    context.answerStreamsBySeal[String(seal)] = { ...stream };
    context.diagnostics.push(Object.freeze({ label, bowlId, seal, legacyNext, semanticNext }));
  }
  return stream;
}

class Stage54GateRegistry {
  constructor(sauceProvider = sauceWithScars) {
    if (typeof sauceProvider !== 'function') throw new TypeError('Li gate registry exige un provider de sauce.');
    this.sauceProvider = sauceProvider;
    this.gates = new Map([[0n, FOUNDATION_DAY_OLD]]);
    this.minKnownGateIndex = 0n;
    this.maxKnownGateIndex = 0n;
    this.gapCalls = 0n;
  }

  gateGap(signedIndex) {
    if (typeof signedIndex !== 'bigint' || signedIndex === 0n) {
      throw new RangeError('Li index signat del gate gap final deve esser non-zero.');
    }
    const questionDay = gateQuestionWithSignedStep(signedIndex);
    const sauceResult = this.sauceProvider(FOUNDATION_DAY_OLD, questionDay);
    const stream = stage54AnswerRingWithScar(sauceResult, 1, 1n, null, 'gate-gap');
    const selected = selectionDispatcherWithWideDetour(stream, 922n);
    this.gapCalls += 1n;
    return 41n + selected.output;
  }

  ensureIndex(index) {
    if (typeof index !== 'bigint') throw new TypeError('Li gate index final deve esser BigInt exact.');
    if (index > this.maxKnownGateIndex) {
      let n = this.maxKnownGateIndex + 1n;
      while (n <= index) {
        const next = this.gates.get(n - 1n) + this.gateGap(n);
        this.gates.set(n, next);
        this.maxKnownGateIndex = n;
        n += 1n;
      }
    }
    if (index < this.minKnownGateIndex) {
      let n = this.minKnownGateIndex - 1n;
      while (n >= index) {
        const next = this.gates.get(n + 1n) - this.gateGap(n);
        this.gates.set(n, next);
        this.minKnownGateIndex = n;
        n -= 1n;
      }
    }
    return this.gates.get(index);
  }

  ensureCover(lowDay, highDay) {
    stage54RequireDay(lowDay, 'Li limite bass del registry de gates');
    stage54RequireDay(highDay, 'Li limite alt del registry de gates');
    if (lowDay > highDay) throw new RangeError('Li interval del registry de gates es invers.');
    while (this.ensureIndex(this.minKnownGateIndex) > lowDay) this.ensureIndex(this.minKnownGateIndex - 1n);
    while (this.ensureIndex(this.maxKnownGateIndex) < highDay) this.ensureIndex(this.maxKnownGateIndex + 1n);
  }

  indexAtOrBefore(day) {
    stage54RequireDay(day, 'Li die questionat al registry de gates');
    this.ensureCover(day, day);
    let lo = this.minKnownGateIndex;
    let hi = this.maxKnownGateIndex;
    while (lo < hi) {
      const mid = lo + floorDiv(hi - lo + 1n, 2n);
      if (this.ensureIndex(mid) <= day) lo = mid;
      else hi = mid - 1n;
    }
    return lo;
  }

  indexAtOrAfter(day) {
    const before = this.indexAtOrBefore(day);
    if (this.ensureIndex(before) === day) return before;
    this.ensureIndex(before + 1n);
    return before + 1n;
  }

  exactIndex(day) {
    const index = this.indexAtOrBefore(day);
    return this.ensureIndex(index) === day ? index : null;
  }

  bounds() {
    return Object.freeze({ minKnownGateIndex: this.minKnownGateIndex, maxKnownGateIndex: this.maxKnownGateIndex });
  }
}

function stage54LocalGateView(registry, lowIndex, highIndex) {
  if (!(registry instanceof Stage54GateRegistry) || typeof lowIndex !== 'bigint' || typeof highIndex !== 'bigint' || lowIndex > highIndex) {
    throw new TypeError('Li vista local de gates final have limites invalid.');
  }
  const span = highIndex - lowIndex;
  if (span > 10000n) throw new RangeError('Li vista local de gates final es irrationalmen larg.');
  const gates = Object.create(null);
  let local = 0;
  for (let index = lowIndex; index <= highIndex; index += 1n) {
    gates[local] = registry.ensureIndex(index);
    local += 1;
  }
  return Object.freeze({
    gates,
    lowIndex,
    highIndex,
    localIndex(actualIndex) { return Number(actualIndex - lowIndex); },
    actualIndex(localIndex) { return lowIndex + BigInt(localIndex); }
  });
}

function stage54YearRecord(registry, number, openGateIndex, closeGateIndex) {
  const openDay = registry.ensureIndex(openGateIndex);
  const closeDay = registry.ensureIndex(closeGateIndex);
  if (closeDay <= openDay) throw new BootstrapStageError('Li year final have un interval non-positiv.');
  return Object.freeze({ number, openGateIndex, closeGateIndex, openDay, firstDay: openDay + 1n, closeDay });
}

function stage54EnrichYear(registry, year) {
  const base = requireWalkYearRecord(year, 'Li year a enriquir por Stage 54');
  const openGateIndex = registry.exactIndex(base.openDay);
  const closeGateIndex = registry.exactIndex(base.closeDay);
  if (openGateIndex === null || closeGateIndex === null) {
    throw new BootstrapStageError('Li year resoluet ne posse esser reancorat a su gates exact.');
  }
  return stage54YearRecord(registry, base.number, openGateIndex, closeGateIndex);
}

function stage54SelectCandidateFamily(view, candidatePairs, stream, context, label) {
  if (candidatePairs.length < 1) throw new BootstrapStageError('Null year candidate existe por ' + label + '.');
  const legacyPrepared = legacyStableLengthOnlyYearCandidates(view.gates, candidatePairs);
  if (legacyPrepared.length < 1) throw new BootstrapStageError('Li familie legacy de year candidates es vacui por ' + label + '.');
  const legacyPick = selectionDispatcherWithWideDetour(stream, BigInt(legacyPrepared.length));
  const legacySelected = legacyPrepared[Number(legacyPick.output - 1n)];
  const filteredStable = stableLengthOnlyPatchedYearCandidates(view.gates, candidatePairs);
  const semanticPrepared = sortEqualLengthRunsByOpeningGate(filteredStable);
  if (semanticPrepared.length < 1) throw new BootstrapStageError('Li familie reparat de year candidates es vacui por ' + label + '.');
  const semanticPick = selectionDispatcherWithWideDetour(stream, BigInt(semanticPrepared.length));
  const semanticSelected = semanticPrepared[Number(semanticPick.output - 1n)];
  if (context) {
    context.diagnostics.push(Object.freeze({
      label,
      legacyFamilyCount: BigInt(legacyPrepared.length),
      legacySelectedLength: legacySelected.candidateLength,
      semanticFamilyCount: BigInt(semanticPrepared.length),
      semanticSelectedLength: semanticSelected.candidateLength,
      rejectedOverlong: legacyPrepared.filter((candidate) => candidate.candidateLength > STAGE54_YEAR_MAX_DAYS).length
    }));
  }
  return { legacyPrepared, legacySelected, semanticPrepared, semanticSelected, semanticPick };
}

function stage54BuildYear5000(calculationDay, registry, context, sauceProvider = sauceWithScars) {
  registry.ensureCover(calculationDay - STAGE54_LEGACY_YEAR_MAX_DAYS, calculationDay + STAGE54_LEGACY_YEAR_MAX_DAYS);
  const lowIndex = registry.indexAtOrBefore(calculationDay - STAGE54_LEGACY_YEAR_MAX_DAYS);
  const highIndex = registry.indexAtOrAfter(calculationDay + STAGE54_LEGACY_YEAR_MAX_DAYS);
  const view = stage54LocalGateView(registry, lowIndex, highIndex);
  const candidatePairs = [];
  for (let i = 0; i < Number(highIndex - lowIndex); i += 1) {
    const openDay = view.gates[i];
    if (openDay >= calculationDay) continue;
    for (let j = i + Number(STAGE54_MIN_GATE_GAPS); j <= Number(highIndex - lowIndex); j += 1) {
      const closeDay = view.gates[j];
      const length = closeDay - openDay;
      if (length > STAGE54_LEGACY_YEAR_MAX_DAYS) break;
      if (calculationDay <= closeDay) candidatePairs.push({ openIndex: i, closeIndex: j });
    }
  }
  const sauceResult = sauceProvider(calculationDay, calculationDay);
  stage56CaptureSauceState(context, sauceResult, 'year-5000');
  const stream = stage54AnswerRingWithScar(sauceResult, 1, 10n, context, 'year-5000');
  const selected = stage54SelectCandidateFamily(view, candidatePairs, stream, context, 'YEAR_5000');
  const year = stage54YearRecord(
    registry,
    5000n,
    view.actualIndex(selected.semanticSelected.openIndex),
    view.actualIndex(selected.semanticSelected.closeIndex)
  );
  if (!(year.openDay < calculationDay && calculationDay <= year.closeDay)) {
    throw new BootstrapStageError('Year 5000 final ne contene li calculation-day secun (open,close].');
  }
  context.year5000 = stage54CloneYear(year);
  return year;
}

function stage54BuildAdjacentYear(calculationDay, knownYear, direction, registry, context, sauceProvider = sauceWithScars) {
  const known = stage54EnrichYear(registry, knownYear);
  const forward = direction === 'next';
  if (!forward && direction !== 'previous') throw new RangeError('Li direction annual final deve esser next o previous.');
  const sharedIndex = forward ? known.closeGateIndex : known.openGateIndex;
  const sharedDay = registry.ensureIndex(sharedIndex);
  if (forward) registry.ensureCover(sharedDay, sharedDay + STAGE54_LEGACY_YEAR_MAX_DAYS);
  else registry.ensureCover(sharedDay - STAGE54_LEGACY_YEAR_MAX_DAYS, sharedDay);
  const lowIndex = forward ? sharedIndex : registry.indexAtOrBefore(sharedDay - STAGE54_LEGACY_YEAR_MAX_DAYS);
  const highIndex = forward ? registry.indexAtOrAfter(sharedDay + STAGE54_LEGACY_YEAR_MAX_DAYS) : sharedIndex;
  const view = stage54LocalGateView(registry, lowIndex, highIndex);
  const sharedLocal = view.localIndex(sharedIndex);
  const candidatePairs = [];
  if (forward) {
    for (let close = sharedLocal + Number(STAGE54_MIN_GATE_GAPS); close <= Number(highIndex - lowIndex); close += 1) {
      const length = view.gates[close] - view.gates[sharedLocal];
      if (length > STAGE54_LEGACY_YEAR_MAX_DAYS) break;
      candidatePairs.push({ openIndex: sharedLocal, closeIndex: close });
    }
  } else {
    for (let open = sharedLocal - Number(STAGE54_MIN_GATE_GAPS); open >= 0; open -= 1) {
      const length = view.gates[sharedLocal] - view.gates[open];
      if (length > STAGE54_LEGACY_YEAR_MAX_DAYS) break;
      candidatePairs.push({ openIndex: open, closeIndex: sharedLocal });
    }
  }
  const sauceTarget = sharedDay;
  const sauceResult = sauceProvider(calculationDay, sauceTarget);
  stage56CaptureSauceState(context, sauceResult, forward ? 'next-year' : 'previous-year');
  const seal = forward ? 11n : 12n;
  const stream = stage54AnswerRingWithScar(sauceResult, 1, seal, context, forward ? 'next-year' : 'previous-year');
  const selected = stage54SelectCandidateFamily(view, candidatePairs, stream, context, forward ? 'NEXT_YEAR' : 'PREVIOUS_YEAR');
  return stage54YearRecord(
    registry,
    known.number + (forward ? 1n : -1n),
    view.actualIndex(selected.semanticSelected.openIndex),
    view.actualIndex(selected.semanticSelected.closeIndex)
  );
}

function stage54ResolveTargetYear(calculationDay, targetDay, registry, context, sauceProvider = sauceWithScars) {
  const year5000 = stage54BuildYear5000(calculationDay, registry, context, sauceProvider);
  context.diagnostics.push(Object.freeze({ label: 'oldJumpGuess', value: oldJumpGuess(year5000, targetDay) }));
  const source = Object.freeze({
    nextYear: (year) => stage54BuildAdjacentYear(calculationDay, year, 'next', registry, context, sauceProvider),
    previousYear: (year) => stage54BuildAdjacentYear(calculationDay, year, 'previous', registry, context, sauceProvider)
  });
  const walked = findYearByWalkPatch(
    year5000,
    targetDay,
    (year) => source.nextYear(year),
    (year) => source.previousYear(year)
  );
  const authoritativeBeforePatch26 = stage54EnrichYear(registry, walked.year);
  let ownershipAnchor = authoritativeBeforePatch26;
  if (targetDay === authoritativeBeforePatch26.closeDay) {
    ownershipAnchor = stage54BuildAdjacentYear(calculationDay, authoritativeBeforePatch26, 'next', registry, context, sauceProvider);
  }
  const legacyInterval = legacyFindYearClosedOpeningInterval(
    ownershipAnchor,
    targetDay,
    (year) => source.nextYear(year),
    (year) => source.previousYear(year)
  );
  const corrected = correctOpeningGateInterval(
    ownershipAnchor,
    targetDay,
    (year) => source.nextYear(year),
    (year) => source.previousYear(year)
  );
  const finalYear = stage54EnrichYear(registry, corrected.year);
  if (finalYear.number !== authoritativeBeforePatch26.number ||
      finalYear.openDay !== authoritativeBeforePatch26.openDay ||
      finalYear.closeDay !== authoritativeBeforePatch26.closeDay) {
    throw new BootstrapStageError('Patch 26 final diverge del year resoluet per li sequential walk.');
  }
  context.currentYear = stage54CloneYear(finalYear);
  context.patch18ResolvedYear = stage54CloneYear(authoritativeBeforePatch26);
  context.patch18SemanticYearNumber = authoritativeBeforePatch26.number;
  context.patch26LegacyYear = stage54CloneYear(legacyInterval.year);
  context.patch26ResolvedYear = stage54CloneYear(finalYear);
  context.patch26SemanticYearNumber = finalYear.number;
  context.diagnostics.push(Object.freeze({
    label: 'opening-gate-interval',
    legacyYear: legacyInterval.year.number,
    correctYear: finalYear.number,
    legacySteps: legacyInterval.stepCount,
    correctSteps: corrected.stepCount
  }));
  return { year: finalYear, source, walk: walked, legacyInterval, corrected };
}

function stage54DistinctNamesWithScar(sauceResult, masterCount, itemCount, seal, context, label, legacyOwnRank) {
  const stream = stage54AnswerRingWithScar(sauceResult, 5, seal, context, label);
  const legacyFamily = legacyNameRowWithRepeats(masterCount, itemCount);
  const distinctCount = fallingFactorialDistinct(masterCount, itemCount);
  let legacyRank;
  let correctRank;
  if (legacyOwnRank) {
    legacyRank = selectionDispatcherWithWideDetour(stream, legacyFamily.count()).output;
    correctRank = selectionDispatcherWithWideDetour(stream, distinctCount).output;
  } else {
    correctRank = selectionDispatcherWithWideDetour(stream, distinctCount).output;
    legacyRank = correctRank;
  }
  const bad = legacyFamily.unrank1(legacyRank);
  const correct = partialPermutationUnrank(masterCount, itemCount, correctRank);
  const identical = stage54ArraysEqual(bad, correct);
  const semantic = identical ? bad : correct;
  context.diagnostics.push(Object.freeze({
    label,
    legacyFamilyCount: legacyFamily.count(),
    distinctFamilyCount: distinctCount,
    legacyRank,
    correctRank,
    bad: Object.freeze(bad.slice()),
    correct: Object.freeze(correct.slice()),
    identical
  }));
  return semantic.slice();
}

function stage54MaterializeCutlets(year, partition, nameIndices, registry) {
  let cursor = year.openGateIndex;
  const cutlets = [];
  for (let index = 0; index < partition.length; index += 1) {
    const openGateIndex = cursor;
    const closeGateIndex = cursor + BigInt(partition[index]);
    cutlets.push(Object.freeze({
      nameIndex: nameIndices[index],
      openGateIndex,
      closeGateIndex,
      firstDay: registry.ensureIndex(openGateIndex) + 1n,
      lastDay: registry.ensureIndex(closeGateIndex)
    }));
    cursor = closeGateIndex;
  }
  if (cursor !== year.closeGateIndex) throw new BootstrapStageError('Li cutlet partition final ne fini al closing gate del year.');
  return Object.freeze(cutlets);
}

function stage56CaptureSauceState(context, sauceResult, label) {
  if (!context || !sauceResult || sauceResult.stage56RawBowlSumApplied !== true || !sauceResult.stage56PostStirContext) return;
  if (!Array.isArray(context.stage56SauceStates)) context.stage56SauceStates = [];
  context.stage56SauceStates.push(Object.freeze({ label, state: sauceResult.stage56PostStirContext }));
}

function stage54BuildStructure(manager, context, calculationDay, targetDay, year, registry, sauceProvider = sauceWithScars) {
  const guarded = cacheGetWithActionGuard(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER, year, calculationDay);
  context.cacheEvents.push(Object.freeze({ type: guarded.hit ? 'HIT' : 'MISS', reason: guarded.reason, year: year.number }));
  if (guarded.hit) {
    context.status = 'STAGE_54_STRUCTURE_FROM_GUARDED_BAD_KEY_CACHE';
    return guarded.value;
  }

  const yearFirstDay = year.firstDay;
  const patch20Diagnostic = structureSaucePatch(calculationDay, targetDay, yearFirstDay);
  const structureSauce = sauceProvider(calculationDay, yearFirstDay);
  stage56CaptureSauceState(context, structureSauce, 'structure-sauce');
  if (manager.stage56Corrective === true) {
    if (!stage54ArraysEqual(patch20Diagnostic.semanticSauce.orderAt46Latch, structureSauce.orderAt46Latch)) {
      throw new BootstrapStageError('Stage 56 ne posse mutar li order latchet de drop 46.');
    }
    context.stage56HistoricalStructureSauceGhost = Object.freeze(patch20Diagnostic.semanticSauce.bowls.slice());
    context.diagnostics.push(Object.freeze({
      label: 'structure-sauce-ghost', executed: true, targetDiffers: targetDay !== yearFirstDay,
      stage56Recomputed: true, historicalBowlsDiffer: !stage54ArraysEqual(patch20Diagnostic.semanticSauce.bowls, structureSauce.bowls)
    }));
  } else {
    if (!stage54ArraysEqual(patch20Diagnostic.semanticSauce.bowls, structureSauce.bowls) ||
        !stage54ArraysEqual(patch20Diagnostic.semanticSauce.orderAt46Latch, structureSauce.orderAt46Latch)) {
      throw new BootstrapStageError('Li sauceWithScars final diverge del sauce semantic de Patch 20.');
    }
    context.diagnostics.push(Object.freeze({ label: 'structure-sauce-ghost', executed: true, targetDiffers: targetDay !== yearFirstDay }));
  }

  const gapCountBig = year.closeGateIndex - year.openGateIndex;
  if (gapCountBig < 6n || gapCountBig > 10000n) throw new BootstrapStageError('Li gap count final es extra li limite operativ del year.');
  const gapCount = Number(gapCountBig);
  const cutletCountCandidates = [];
  for (let k = 6; k <= 17 && k <= gapCount; k += 1) cutletCountCandidates.push(k);
  const cutletCountStream = stage54AnswerRingWithScar(structureSauce, 2, 20n, context, 'cutlet-count');
  const cutletCountPick = selectionDispatcherWithWideDetour(cutletCountStream, BigInt(cutletCountCandidates.length));
  const cutletCount = cutletCountCandidates[Number(cutletCountPick.output - 1n)];

  const rawPartitionFamily = legacyPositiveCompositions(gapCount, cutletCount);
  const partitionStream = stage54AnswerRingWithScar(structureSauce, 2, 21n, context, 'cutlet-partition');
  const rawPartitionRank = selectionDispatcherWithWideDetour(partitionStream, rawPartitionFamily.count()).output;
  const rawPartition = rawPartitionFamily.unrank1(rawPartitionRank);
  const calculationGateIndex = registry.exactIndex(calculationDay);
  const internalOffset = calculationGateIndex !== null && year.openGateIndex < calculationGateIndex && calculationGateIndex < year.closeGateIndex
    ? Number(calculationGateIndex - year.openGateIndex)
    : null;
  let partition = rawPartition;
  let semanticPartitionRank = rawPartitionRank;
  let semanticPartitionCount = rawPartitionFamily.count();
  if (internalOffset !== null) {
    const filtered = filteredCutletCompositions(gapCount, cutletCount, internalOffset);
    semanticPartitionCount = filtered.count();
    semanticPartitionRank = selectionDispatcherWithWideDetour(partitionStream, filtered.count()).output;
    partition = filtered.unrank1(semanticPartitionRank);
    let sum = 0;
    let hit = false;
    for (const part of partition) {
      sum += part;
      if (sum === internalOffset) hit = true;
    }
    if (!hit) throw new BootstrapStageError('Li partition filtrat final manca li calculation gate intern.');
  }
  context.diagnostics.push(Object.freeze({
    label: 'cutlet-partition-scar',
    rawCount: rawPartitionFamily.count(), rawRank: rawPartitionRank, raw: Object.freeze(rawPartition.slice()),
    internalOffset, semanticCount: semanticPartitionCount, semanticRank: semanticPartitionRank, semantic: Object.freeze(partition.slice())
  }));

  const cutletNameIndices = stage54DistinctNamesWithScar(
    structureSauce, SourceLanguageCatalog.cutlets.length, cutletCount, 22n, context, 'cutlet-names', true
  );
  if (new Set(cutletNameIndices).size !== cutletNameIndices.length) {
    throw new BootstrapStageError('Li cutlet names final ne es distinct.');
  }
  const cutlets = stage54MaterializeCutlets(year, partition, cutletNameIndices, registry);

  const yearLengthBig = year.closeDay - year.openDay;
  let minMonths = Number((yearLengthBig + 122n) / 123n);
  if (minMonths < 3) minMonths = 3;
  let maxMonths = Number(yearLengthBig / 4n);
  if (maxMonths > 47) maxMonths = 47;
  if (minMonths > maxMonths) throw new BootstrapStageError('Li limites final del month count es inconsistent.');
  const monthCountStream = stage54AnswerRingWithScar(structureSauce, 3, 30n, context, 'month-count');
  const monthCountRank = selectionDispatcherWithWideDetour(monthCountStream, BigInt(maxMonths - minMonths + 1)).output;
  const monthCount = minMonths + Number(monthCountRank - 1n);

  const legacyMonthApi = new LegacyMonthLengthAllWaysAPI();
  const probe = legacyMonthApi.probeAllWays(Number(yearLengthBig), monthCount, 128);
  const virtualLengths = new VirtualLegacyList(Number(yearLengthBig), monthCount);
  const monthLengthStream = stage54AnswerRingWithScar(structureSauce, 3, 31n, context, 'month-lengths');
  const monthLengthRank = selectionDispatcherWithWideDetour(monthLengthStream, virtualLengths.count()).output;
  const monthLengths = virtualLengths.itemAt1(monthLengthRank);
  const monthLengthsAgain = virtualLengths.itemAt1(monthLengthRank);
  if (!stage54ArraysEqual(monthLengths, monthLengthsAgain)) {
    throw new BootstrapStageError('Li validation duplicat de VirtualLegacyList final diverge.');
  }
  context.diagnostics.push(Object.freeze({
    label: 'month-length-concrete-scar',
    concreteProbeCount: probe.ways.length,
    concreteProbeExceeded: probe.exceededLimit,
    virtualCount: virtualLengths.count(),
    selectedRank: monthLengthRank
  }));

  const monthWeavingStream = stage54AnswerRingWithScar(structureSauce, 4, 32n, context, 'month-weaving');
  const ghostWeaving = legacyChooseEachDaySeparately(monthLengths, monthWeavingStream);
  const weavingFamily = new LegalMonthWeavingDP(monthLengths);
  const wantedRank = selectionDispatcherWithWideDetour(monthWeavingStream, weavingFamily.count()).output;
  const correctWeaving = DPUnrankLegalWeaving(monthLengths, wantedRank);
  const weaving = stage54ArraysEqual(ghostWeaving, correctWeaving) ? ghostWeaving : correctWeaving;
  context.diagnostics.push(Object.freeze({
    label: 'month-weaving-ghost',
    familyCount: weavingFamily.count(), wantedRank,
    ghostEqualsCorrect: stage54ArraysEqual(ghostWeaving, correctWeaving)
  }));

  const monthNameIndices = stage54DistinctNamesWithScar(
    structureSauce, SourceLanguageCatalog.months.length, monthCount, 33n, context, 'month-names', false
  );
  if (new Set(monthNameIndices).size !== monthNameIndices.length) {
    throw new BootstrapStageError('Li month names final ne es distinct.');
  }

  const candidateStructure = Object.freeze({
    yearNumber: year.number,
    yearOpenDay: year.openDay,
    yearCloseDay: year.closeDay,
    cutletCount,
    cutletPartition: Object.freeze(partition.slice()),
    cutletNameIndices: Object.freeze(cutletNameIndices.slice()),
    cutlets,
    monthCount,
    monthLengths: Object.freeze(monthLengths.slice()),
    monthWeaving: Object.freeze(weaving.slice()),
    monthNameIndices: Object.freeze(monthNameIndices.slice()),
    structureSauceBowls: Object.freeze(structureSauce.bowls.slice()),
    structureSauceOrderAt46Latch: Object.freeze(structureSauce.orderAt46Latch.slice())
  });
  if (candidateStructure.monthWeaving.length !== Number(yearLengthBig)) {
    throw new BootstrapStageError('Li intertexe final ne have li longore exact del year.');
  }
  context.oldSnapshot = context.structure;
  context.pendingSnapshot = candidateStructure;
  context.commitToken = 'STAGE54_STRUCTURE_VALIDATED';
  context.structure = context.pendingSnapshot;
  context.pendingSnapshot = null;
  cachePutWithGuard(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER, year, calculationDay, context.structure);
  context.cacheEvents.push(Object.freeze({ type: 'COMMIT', year: year.number }));
  return context.structure;
}

function stage54ResolveFive(context, year, structure, targetDay) {
  let chosenCutlet = null;
  for (const cutlet of structure.cutlets) {
    if (cutlet.firstDay <= targetDay && targetDay <= cutlet.lastDay) {
      chosenCutlet = cutlet;
      break;
    }
  }
  if (chosenCutlet === null) throw new BootstrapStageError('Null cutlet final contene li target-day.');
  const dayInCutlet = targetDay - chosenCutlet.firstDay + 1n;
  const offsetBig = targetDay - year.firstDay;
  if (offsetBig < 0n || offsetBig >= BigInt(structure.monthWeaving.length)) {
    throw new BootstrapStageError('Li offset final del target-day es extra li intertexe.');
  }
  const offset = Number(offsetBig);
  const monthId = structure.monthWeaving[offset];
  const legacyMonthGuess = oldContiguousMonthDayGuess(structure.monthWeaving, offset + 1);
  const dayInMonthNumber = countMonthOccurrencesThroughTarget(structure.monthWeaving, offset + 1);
  const dayInMonth = BigInt(dayInMonthNumber);
  const monthNameIndex = structure.monthNameIndices[monthId - 1];
  context.diagnostics.push(Object.freeze({
    label: 'contiguous-month-ghost', legacyMonthGuess, occurrenceCount: dayInMonthNumber, monthId, targetPosition: offset + 1
  }));
  const resultFive = Object.freeze([
    year.number,
    textByCanonicalIndex('cutlet', chosenCutlet.nameIndex),
    dayInCutlet,
    textByCanonicalIndex('month', monthNameIndex),
    dayInMonth
  ]);
  if (resultFive.length !== 5 || dayInCutlet < 1n || dayInMonth < 1n) {
    throw new BootstrapStageError('Li final resultate deve contener exactmen quin fields valid.');
  }
  return resultFive;
}

class Stage54CompatibilityManager {
  installAuthoritativeFlags(context) {
    const flags = Object.freeze({
      useLegacyRemainder: true,
      useLegacyDayTag: true,
      useLegacyDistance: true,
      useBackwardHiddenStorage: true,
      useAliasPours: true,
      useShadowBowls: true,
      useLatchedQueryOrder: true,
      useLateYearFilter: true,
      useGuardedBadCacheKey: true,
      useGhostStructureSauce: true,
      useVirtualFamilies: true,
      useGhostWeaveCandidate: true
    });
    context.compatibilityFlags = flags;
    return flags;
  }
}

class Stage54RecoveryManager {
  snapshot(context, stage) {
    return Object.freeze({
      stage,
      status: context.status,
      currentYear: context.currentYear ? stage54CloneYear(context.currentYear) : null,
      structure: context.structure || null,
      resultFive: context.resultFive ? Object.freeze(context.resultFive.slice()) : null
    });
  }

  restore(context, snapshot) {
    if (!snapshot || typeof snapshot.stage !== 'number') throw new TypeError('Li snapshot de recovery final es invalid.');
    context.status = snapshot.status;
    context.currentYear = snapshot.currentYear ? stage54CloneYear(snapshot.currentYear) : null;
    context.structure = snapshot.structure;
    context.resultFive = snapshot.resultFive ? Object.freeze(snapshot.resultFive.slice()) : null;
    context.recoveryEvents.push(Object.freeze({ type: 'RESTORE', stage: snapshot.stage }));
  }
}

class Stage54MonsterIntegrationManager extends BaseMonsterManager {
  constructor(gateRegistry, sauceProvider = sauceWithScars, stage56Corrective = false) {
    super();
    this.gateRegistry = gateRegistry;
    this.sauceProvider = sauceProvider;
    this.stage56Corrective = stage56Corrective;
    this.compatibilityManager = new Stage54CompatibilityManager();
    this.recoveryManager = new Stage54RecoveryManager();
    this.integrationHooks = Object.freeze({
      beforeStage: null,
      afterStage: null
    });
  }

  prepareFinal(calculationDay, targetDay) {
    const context = this.prepare(calculationDay, targetDay);
    context.mode = 'AUTHORITATIVE_SPAGHETTI';
    context.subPhase = 'ENTRY';
    context.retryBudget = 3;
    context.recoveryDepth = 0;
    context.warnings = [];
    context.recoveryEvents = [];
    context.cacheEvents = [];
    context.answerStreamsBySeal = Object.create(null);
    context.gatesTouched = [];
    context.year5000 = null;
    context.currentYear = null;
    context.structure = null;
    context.resultFive = null;
    context.oldSnapshot = null;
    context.pendingSnapshot = null;
    context.rollbackSnapshot = null;
    context.commitToken = null;
    this.compatibilityManager.installAuthoritativeFlags(context);
    context.phase = 'STAGE_54_ENTRY';
    context.status = 'STAGE_54_NEW';
    context.branchTrace.push('STAGE_54_ENTRY');
    return context;
  }

  executeCalendarDate(calculationDay, targetDay) {
    stage54RequireDay(calculationDay, 'Li calculation-day final');
    stage54RequireDay(targetDay, 'Li target-day final');
    const context = this.prepareFinal(calculationDay, targetDay);
    let programCounter = 0;
    let yearResolution = null;
    let year = null;
    let structure = null;
    let committedSnapshot = this.recoveryManager.snapshot(context, programCounter);
    while (true) {
      context.phase = 'STAGE_54_MAIN_' + programCounter;
      context.branchTrace.push('STAGE_54_MAIN_' + programCounter);
      try {
        switch (programCounter) {
          case 0:
            this.validationManager.requireDiscreteDay(calculationDay);
            this.validationManager.requireDiscreteDay(targetDay);
            this.metricsManager.bump(context, 'stage54.calendar.calls');
            context.status = 'STAGE_54_VALIDATED';
            committedSnapshot = this.recoveryManager.snapshot(context, 0);
            programCounter = 10;
            break;
          case 10:
            context.subPhase = 'YEAR_RESOLUTION';
            yearResolution = stage54ResolveTargetYear(calculationDay, targetDay, this.gateRegistry, context, this.sauceProvider);
            year = yearResolution.year;
            context.gatesTouched = [year.openDay, year.closeDay];
            context.status = 'STAGE_54_YEAR_READY';
            committedSnapshot = this.recoveryManager.snapshot(context, 10);
            programCounter = 20;
            break;
          case 20: {
            context.subPhase = 'GUARDED_CACHE';
            const guarded = cacheGetWithActionGuard(this.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER, year, calculationDay);
            context.diagnostics.push(Object.freeze({ label: 'pre-structure-cache-probe', hit: guarded.hit, reason: guarded.reason }));
            programCounter = guarded.hit ? 70 : 30;
            if (guarded.hit) structure = guarded.value;
            break;
          }
          case 30:
            context.subPhase = 'STRUCTURE_BUILD';
            structure = stage54BuildStructure(this, context, calculationDay, targetDay, year, this.gateRegistry, this.sauceProvider);
            context.status = 'STAGE_54_STRUCTURE_READY';
            committedSnapshot = this.recoveryManager.snapshot(context, 30);
            programCounter = 70;
            break;
          case 70:
            if (structure === null) structure = stage54BuildStructure(this, context, calculationDay, targetDay, year, this.gateRegistry, this.sauceProvider);
            context.structure = structure;
            context.commitToken = 'STAGE54_STRUCTURE_COMMITTED';
            programCounter = 80;
            break;
          case 80:
            context.subPhase = 'FINAL_RESOLVER';
            context.resultFive = stage54ResolveFive(context, year, structure, targetDay);
            context.commitToken = 'STAGE54_RESULT_VALIDATED';
            committedSnapshot = this.recoveryManager.snapshot(context, 80);
            programCounter = 90;
            break;
          case 90:
            context.status = 'SUCCESS';
            this.metricsManager.bump(context, 'stage54.calendar.success');
            context.branchTrace.push('STAGE_54_SUCCESS');
            return { result: Object.freeze(context.resultFive.slice()), context };
          default:
            throw new BootstrapStageError('Li state-machine principal de Stage 54 have un stage ínconosset.');
        }
      } catch (error) {
        context.lastError = error;
        context.wrappedErrors = Array.isArray(context.wrappedErrors) ? context.wrappedErrors : [];
        context.wrappedErrors.push(Object.freeze({ stage: programCounter, name: error.name }));
        if (error && error.recoverableStage54 === true && context.retryBudget > 0) {
          context.retryBudget -= 1;
          context.recoveryDepth += 1;
          context.rollbackSnapshot = committedSnapshot;
          this.recoveryManager.restore(context, committedSnapshot);
          programCounter = committedSnapshot.stage;
          continue;
        }
        context.status = 'FAILED';
        throw error;
      }
    }
  }
}

const STAGE54_GLOBAL_GATE_REGISTRY = new Stage54GateRegistry();
const STAGE54_GLOBAL_MANAGER = new Stage54MonsterIntegrationManager(STAGE54_GLOBAL_GATE_REGISTRY);

function calendarDateSpaghettiStage55HistoricalWithContext(calculationDay, targetDay) {
  return STAGE54_GLOBAL_MANAGER.executeCalendarDate(calculationDay, targetDay);
}

function calendarDateSpaghettiStage55Historical(calculationDay, targetDay) {
  return calendarDateSpaghettiStage55HistoricalWithContext(calculationDay, targetDay).result;
}

class Stage56MonsterIntegrationManager extends Stage54MonsterIntegrationManager {
  constructor(gateRegistry) {
    super(gateRegistry, sauceWithScarsStage56, true);
  }

  prepareFinal(calculationDay, targetDay) {
    const context = super.prepareFinal(calculationDay, targetDay);
    context.mode = 'AUTHORITATIVE_SPAGHETTI_STAGE_56';
    context.stage56SauceStates = [];
    context.stage56HistoricalStructureSauceGhost = null;
    context.stage56CorrectiveApplied = true;
    context.compatibilityFlags = Object.freeze({ ...context.compatibilityFlags, useStage56RawBowlSumDetour: true });
    context.phase = 'STAGE_56_CORRECTIVE_ENTRY';
    context.branchTrace.push('STAGE_56_CORRECTIVE_ENTRY');
    return context;
  }
}

const STAGE56_GLOBAL_GATE_REGISTRY = new Stage54GateRegistry(sauceWithScarsStage56);
const STAGE56_GLOBAL_MANAGER = new Stage56MonsterIntegrationManager(STAGE56_GLOBAL_GATE_REGISTRY);

function calendarDateSpaghettiWithContext(calculationDay, targetDay) {
  return STAGE56_GLOBAL_MANAGER.executeCalendarDate(calculationDay, targetDay);
}

function calendarDateSpaghetti(calculationDay, targetDay) {
  return calendarDateSpaghettiWithContext(calculationDay, targetDay).result;
}

module.exports = Object.freeze({
  SourceLanguageCatalog,
  textByCanonicalIndex,
  M_OLD,
  FOUNDATION_DAY_OLD,
  BootstrapStageError,
  BaseMonsterContext,
  BaseValidationManager,
  BaseMetricsManager,
  BaseErrorWrapper,
  BaseDispatcher,
  LegacyRemainderAdapter,
  Discovery01RemainderHandler,
  Patch01SaveWrapper,
  LegacyDayTagAdapter,
  Discovery02DayTagHandler,
  Patch02DayTagWrapper,
  LegacyDistanceAdapter,
  Discovery03DistanceHandler,
  Patch03DistanceWrapper,
  LegacyStoneMutationAdapter,
  Discovery04StoneMutationHandler,
  Patch04StoneWrapper,
  LegacyHiddenStorageAdapter,
  Discovery05HiddenStorageHandler,
  Patch05HiddenNearnessWrapper,
  LegacyPriorAdapter,
  Discovery06PriorHandler,
  Patch06PriorWrapper,
  LegacyGrindTableAdapter,
  Discovery07GrindIndexHandler,
  Patch07GrindSentinelWrapper,
  LegacyPermutationOrderAdapter,
  Discovery08PermutationRankHandler,
  Patch08PermutationWrapper,
  LegacyFixedPourAdapter,
  Discovery09FixedPourHandler,
  Patch09BowlAliasWrapper,
  LegacyInPlaceBowlAdapter,
  Discovery10InPlaceBowlHandler,
  Patch10ShadowBowlWrapper,
  LegacyOverwritableOrderMemoryAdapter,
  Discovery11OverwrittenOrderHandler,
  Patch11OrderAt46LatchWrapper,
  LegacyNextBowlAdapter,
  Discovery12NextBowlHandler,
  NextBowlPatchWrapper,
  LegacyBiasedSelectionAdapter,
  Discovery13BiasedSelectionHandler,
  SelectionRejectionPatchWrapper,
  LegacyShortFamilyAssumptionAdapter,
  Discovery14WideSelectionHandler,
  WideSelectionPatchWrapper,
  LegacyGateQuestionAdapter,
  Discovery15NegativeGateQuestionHandler,
  NegativeGateQuestionPatchWrapper,
  LegacyYearCandidateAdapter,
  Discovery16LegacyYearCandidateHandler,
  YearCandidateCeilingPatchWrapper,
  Discovery17Year5000TieHandler,
  Year5000TiePatchWrapper,
  LegacyYearJumpAdapter,
  Discovery18YearJumpHandler,
  SequentialYearWalkPatchWrapper,
  LegacyYearNumberCacheAdapter,
  Discovery19YearNumberCacheHandler,
  YearCacheActionGuardPatchWrapper,
  LegacyStructureSauceAdapter,
  LegacyStructureSelectorAdapter,
  Discovery20StructureSauceHandler,
  StructureSaucePatchWrapper,
  LegacyCutletPartitionAdapter,
  Discovery21CutletPartitionHandler,
  CutletPartitionPatchWrapper,
  LegacyRepeatedNameGenerator,
  Discovery22RepeatedNameHandler,
  RepeatedNamePatchWrapper,
  LegacyMonthLengthAllWaysAPI,
  Discovery23MonthLengthMaterializationHandler,
  VirtualLegacyList,
  MonthLengthVirtualPatchWrapper,
  LegacyMonthWeavingAdapter,
  Discovery24MonthWeavingHandler,
  LegalMonthWeavingDP,
  MonthWeavingPatchWrapper,
  LegacyContiguousMonthDayAdapter,
  Discovery25ContiguousMonthDayHandler,
  MonthDayOccurrencePatchWrapper,
  LegacyOpeningGateIntervalAdapter,
  Discovery26OpeningGateIntervalHandler,
  OpeningGateIntervalPatchWrapper,
  BaseMonsterManager,
  regularMod,
  oldRemainder,
  savePatch,
  oldDayTag,
  dayTagWithFoundationScar,
  oldDistance,
  distanceWithChronologyDetour,
  mutateStonesWrong,
  cloneStoneState,
  stonePatch,
  getStoneTableThroughLegacyBuilder,
  LEGACY_HIDDEN_COEFF_REVERSED,
  coeffForHidden,
  hiddenStoneKind,
  makeHiddenPatched,
  buildHiddenWithBackwardStorage,
  hiddenByNearness,
  legacyPrior,
  priorPatch,
  LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED,
  legacyGrindRow,
  GRIND_TABLE_WITH_SENTINEL,
  grindRowWithSentinel,
  oldPermutationUnrank0,
  legacyBowlOrderFromDrop,
  orderPatchFromValue,
  legacyPoursToFixedBowlIds,
  installBowlAlias,
  bowlAtLegacyPosition,
  poursThroughBowlAlias,
  BOWL_STIR_STONE_BY_POSITION_LEGACY,
  legacyStirOneDropInPlace,
  stirOneDropViaShadow,
  DISCOVERY11_BOWL_PRIMES,
  initialBowlsForOrderMemoryDiscovery,
  visibleDropThroughCurrentLayers,
  postStirOneForOrderMemoryDiscovery,
  createStage56PostStirContext,
  stage56RawBowlSumPostStirDetour,
  legacySauceWithOverwritableOrderMemory,
  createOrderAt46LatchState,
  writeOrderAt46LatchOnce,
  readOrderAt46Latch,
  sauceWithOrderAt46Latch,
  sauceWithStage56RawBowlSumDetour,
  oldNextBowlFixedName,
  nextBowlFromOrderAt46Latch,
  answerRingFromCurrentState,
  ringAnswerAt,
  biasedLegacyPick,
  legacySelectionAssumingNLeM,
  patchedSmallPick,
  wideDetour,
  selectionDispatcherWithWideDetour,
  oldGateQuestionDay,
  gateQuestionWithSignedStep,
  LEGACY_YEAR_MAX,
  REAL_YEAR_MAX_PATCH,
  legacyYearCandidateAllowed,
  yearCandidateAfterFootnotePatch,
  legacyYearCandidatesBeforeSort,
  legacyStableLengthOnlyYearCandidates,
  yearCandidatesAfterFootnotePatchBeforeSort,
  stableLengthOnlyPatchedYearCandidates,
  sortEqualLengthRunsByOpeningGate,
  floorDiv,
  oldJumpGuess,
  patchedNextYear,
  patchedPreviousYear,
  findYearByWalkPatch,
  buildLegacyYearStructureValue,
  legacyYearNumberOnlyLookup,
  legacyYearNumberOnlyPut,
  calculationDayFingerprint,
  cacheGetWithActionGuard,
  cachePutWithGuard,
  structureSauceCountsFromDays,
  sauceWithCurrentScars,
  oldStructureSauce,
  legacyStructureSelectorToken,
  structureSaucePatch,
  legacyPositiveCompositions,
  filteredCutletCompositions,
  legacyNameRowWithRepeats,
  fallingFactorialDistinct,
  partialPermutationUnrank,
  cutletNameAnswerRingFromSauce,
  legacyMaterializeMonthLengthWays,
  monthCountAnswerRingFromSauce,
  monthLengthAnswerRingFromSauce,
  monthWeavingAnswerRingFromSauce,
  wrapMonth,
  legacyChooseEachDaySeparately,
  compatibleMonthWeavingRank,
  DPUnrankLegalWeaving,
  oldContiguousMonthDayGuess,
  countMonthOccurrencesThroughTarget,
  legacyFindYearClosedOpeningInterval,
  correctOpeningGateInterval,
  createBootstrapContext,
  discovery01LegacyRemainderThroughMonsterPath,
  historicRemainderThroughMonsterPath,
  discovery02LegacyDayTagThroughMonsterPath,
  historicDayTagThroughMonsterPath,
  discovery03LegacyDistanceThroughMonsterPath,
  historicDistanceThroughMonsterPath,
  discovery04LegacyStoneMutationThroughMonsterPath,
  historicStoneMutationThroughMonsterPath,
  discovery05LegacyHiddenStorageThroughMonsterPath,
  historicHiddenByNearnessThroughMonsterPath,
  discovery06LegacyPriorThroughMonsterPath,
  historicPriorThroughMonsterPath,
  discovery07LegacyGrindRowThroughMonsterPath,
  historicGrindRowThroughMonsterPath,
  discovery08LegacyBowlOrderThroughMonsterPath,
  historicBowlOrderThroughMonsterPath,
  discovery09LegacyFixedPoursThroughMonsterPath,
  historicPoursThroughMonsterPath,
  discovery10LegacyInPlaceBowlsThroughMonsterPath,
  historicBowlRoundThroughMonsterPath,
  discovery11LegacyOverwrittenOrderThroughMonsterPath,
  historicOrderAt46ThroughMonsterPath,
  discovery12LegacyNextBowlThroughMonsterPath,
  historicNextBowlThroughMonsterPath,
  discovery13LegacyBiasedSelectionThroughMonsterPath,
  historicSmallSelectionThroughMonsterPath,
  discovery14LegacyWideSelectionThroughMonsterPath,
  historicSelectionThroughMonsterPath,
  discovery15LegacyGateQuestionThroughMonsterPath,
  historicGateQuestionThroughMonsterPath,
  discovery16LegacyYearCandidatesThroughMonsterPath,
  historicYearCandidatesThroughMonsterPath,
  discovery17LegacyYear5000TieThroughMonsterPath,
  historicYear5000TieThroughMonsterPath,
  discovery18LegacyYearJumpThroughMonsterPath,
  historicYearJumpThroughMonsterPath,
  discovery19LegacyYearNumberCacheThroughMonsterPath,
  historicYearNumberCacheThroughMonsterPath,
  discovery20LegacyStructureSauceThroughMonsterPath,
  historicStructureSauceThroughMonsterPath,
  discovery21LegacyCutletPartitionThroughMonsterPath,
  historicCutletPartitionThroughMonsterPath,
  discovery22LegacyRepeatedNamesThroughMonsterPath,
  historicRepeatedNamesThroughMonsterPath,
  discovery23LegacyMonthLengthMaterializationThroughMonsterPath,
  historicMonthLengthVirtualListThroughMonsterPath,
  discovery24LegacyMonthWeavingThroughMonsterPath,
  historicMonthWeavingThroughMonsterPath,
  discovery25LegacyContiguousMonthDayThroughMonsterPath,
  historicMonthDayOccurrenceThroughMonsterPath,
  discovery26LegacyOpeningGateIntervalThroughMonsterPath,
  historicOpeningGateIntervalThroughMonsterPath,
  sauceWithScars,
  sauceWithScarsStage56,
  Stage54GateRegistry,
  Stage54CompatibilityManager,
  Stage54RecoveryManager,
  Stage54MonsterIntegrationManager,
  Stage56MonsterIntegrationManager,
  STAGE54_GLOBAL_GATE_REGISTRY,
  STAGE54_GLOBAL_MANAGER,
  calendarDateSpaghettiStage55HistoricalWithContext,
  calendarDateSpaghettiStage55Historical,
  calendarDateSpaghettiWithContext,
  calendarDateSpaghetti
});
