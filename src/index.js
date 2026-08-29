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

function calendarDateSpaghetti() {
  throw new BootstrapStageError('Li function final ne es ancor implementat in Discovery 09; li progression historic deve restar intact.');
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
  calendarDateSpaghetti
});
