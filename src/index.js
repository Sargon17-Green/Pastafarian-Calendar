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

function calendarDateSpaghetti() {
  throw new BootstrapStageError('Li function final ne es ancor implementat in Discovery 18; li progression historic deve restar intact.');
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
  legacySauceWithOverwritableOrderMemory,
  createOrderAt46LatchState,
  writeOrderAt46LatchOnce,
  readOrderAt46Latch,
  sauceWithOrderAt46Latch,
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
  calendarDateSpaghetti
});
