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

function calendarDateSpaghetti() {
  throw new BootstrapStageError('Li function final ne es ancor implementat in Discovery 04; li progression historic deve restar intact.');
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
  BaseMonsterManager,
  regularMod,
  oldRemainder,
  savePatch,
  oldDayTag,
  dayTagWithFoundationScar,
  oldDistance,
  distanceWithChronologyDetour,
  mutateStonesWrong,
  createBootstrapContext,
  discovery01LegacyRemainderThroughMonsterPath,
  historicRemainderThroughMonsterPath,
  discovery02LegacyDayTagThroughMonsterPath,
  historicDayTagThroughMonsterPath,
  discovery03LegacyDistanceThroughMonsterPath,
  historicDistanceThroughMonsterPath,
  discovery04LegacyStoneMutationThroughMonsterPath,
  calendarDateSpaghetti
});
