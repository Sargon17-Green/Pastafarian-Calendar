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

function calendarDateSpaghetti() {
  throw new BootstrapStageError('Li function final ne es ancor implementat in Discovery 02; li progression historic deve restar intact.');
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
  BaseMonsterManager,
  regularMod,
  oldRemainder,
  savePatch,
  oldDayTag,
  createBootstrapContext,
  discovery01LegacyRemainderThroughMonsterPath,
  historicRemainderThroughMonsterPath,
  discovery02LegacyDayTagThroughMonsterPath,
  calendarDateSpaghetti
});
