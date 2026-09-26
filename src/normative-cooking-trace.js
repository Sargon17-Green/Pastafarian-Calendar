'use strict';

const core = require('./index');

const TRACE_SCHEMA_VERSION = '0.4.0';
const TRACE_SEMANTIC_PROFILE = 'PASTAFARIAN_STAGE57_CANONICAL_SAVED_SUM';
const FOUNDATION_DAY = core.FOUNDATION_DAY_OLD;

function requireDay(value, label) {
  if (typeof value !== 'bigint') throw new TypeError(label + ' deve esser un BigInt exact.');
  return value;
}

function compareBigInt(a, b) {
  return a < b ? -1 : a > b ? 1 : 0;
}

function cloneYear(year) {
  if (!year || typeof year !== 'object') return null;
  const out = {
    number: year.number,
    openDay: year.openDay,
    firstDay: year.firstDay,
    closeDay: year.closeDay,
  };
  if (typeof year.openGateIndex === 'bigint') out.openGateIndex = year.openGateIndex;
  if (typeof year.closeGateIndex === 'bigint') out.closeGateIndex = year.closeGateIndex;
  return out;
}

function sameYear(a, b) {
  return !!a && !!b
    && a.number === b.number
    && a.openDay === b.openDay
    && a.closeDay === b.closeDay;
}

function sixBowls(bowls) {
  if (!Array.isArray(bowls) || bowls.length < 7) {
    throw new TypeError('Li cooking trace expecta six bowls in indices 1..6.');
  }
  return bowls.slice(1, 7);
}

function cloneCounts(counts) {
  if (!counts || typeof counts !== 'object') {
    throw new TypeError('Li cooking trace expecta li quin comptes de Sauce.');
  }
  return {
    action: counts.action,
    target: counts.target,
    distance: counts.distance,
    connection: counts.connection,
    direction: counts.direction,
  };
}

function normalizeTraceOptions(options) {
  if (options === null || options === undefined) {
    return { onGateSauceDetail: null, gateDetailGateIndices: null, onProgress: null };
  }
  if (!options || typeof options !== 'object' || Array.isArray(options)) {
    throw new TypeError('Li options del cooking trace deve esser un plain object.');
  }
  const onGateSauceDetail = options.onGateSauceDetail === undefined
    ? null
    : options.onGateSauceDetail;
  if (onGateSauceDetail !== null && typeof onGateSauceDetail !== 'function') {
    throw new TypeError('onGateSauceDetail deve esser null o un function.');
  }
  const onProgress = options.onProgress === undefined ? null : options.onProgress;
  if (onProgress !== null && typeof onProgress !== 'function') {
    throw new TypeError('onProgress deve esser null o un function.');
  }
  let gateDetailGateIndices = null;
  if (options.gateDetailGateIndices !== undefined && options.gateDetailGateIndices !== null) {
    if (!Array.isArray(options.gateDetailGateIndices)) {
      throw new TypeError('gateDetailGateIndices deve esser null o un array de BigInt.');
    }
    gateDetailGateIndices = new Set();
    for (const index of options.gateDetailGateIndices) {
      if (typeof index !== 'bigint' || index === 0n) {
        throw new RangeError('Chascun gateDetailGateIndices deve esser un BigInt non-zero.');
      }
      gateDetailGateIndices.add(index);
    }
  }
  return { onGateSauceDetail, gateDetailGateIndices, onProgress };
}

function deepFreeze(value, seen = new Set()) {
  if (value === null || typeof value !== 'object' || seen.has(value)) return value;
  seen.add(value);
  const items = Array.isArray(value) ? value : Object.values(value);
  for (const item of items) deepFreeze(item, seen);
  return Object.freeze(value);
}

function exactJsonValue(value, seen = new Set()) {
  if (typeof value === 'bigint') return value.toString();
  if (value === null || typeof value === 'string' || typeof value === 'boolean') return value;
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new TypeError('Li trace ne serialisa un Number non-finit.');
    return value;
  }
  if (value === undefined) return null;
  if (typeof value === 'function' || typeof value === 'symbol') {
    throw new TypeError('Li trace semantic ne serialisa functiones o simbols.');
  }
  if (typeof value !== 'object') return String(value);
  if (seen.has(value)) throw new TypeError('Li trace semantic ne deve contener cycles.');
  const proto = Object.getPrototypeOf(value);
  if (!Array.isArray(value) && proto !== Object.prototype && proto !== null) {
    throw new TypeError('Li trace semantic deve contener solmen arrays e plain objects.');
  }
  seen.add(value);
  let out;
  if (Array.isArray(value)) {
    out = value.map((item) => exactJsonValue(item, seen));
  } else {
    out = {};
    for (const [key, item] of Object.entries(value)) out[key] = exactJsonValue(item, seen);
  }
  seen.delete(value);
  return out;
}

function createLiveProgressEmitter(callback) {
  const enabled = typeof callback === 'function';
  const startedAt = Date.now();
  let previousAt = startedAt;
  let sequence = 0;
  return Object.freeze({
    enabled,
    emit(kind, payload = {}) {
      if (!enabled) return;
      const now = Date.now();
      const event = deepFreeze(exactJsonValue({
        sequence: ++sequence,
        kind: String(kind),
        elapsedMs: Math.max(0, now - startedAt),
        durationMs: Math.max(0, now - previousAt),
        payload,
      }));
      previousAt = now;
      try {
        callback(event);
      } catch (_) {
        // Progress is observational UI telemetry and may never change calendar semantics.
      }
    },
  });
}

function canonicalIndexFor(group, text) {
  const rows = group === 'cutlet'
    ? core.SourceLanguageCatalog.cutlets
    : group === 'month'
      ? core.SourceLanguageCatalog.months
      : null;
  if (!rows) throw new RangeError('Grupp canonic ínconosset in li cooking trace.');
  const row = rows.find((item) => item.text === text);
  if (!row) throw new Error('Un nómine del resultate final manca ex li catalog canonic.');
  return row.canonicalIndex;
}

function findDiagnostic(context, label) {
  if (!context || !Array.isArray(context.diagnostics)) return null;
  for (let i = context.diagnostics.length - 1; i >= 0; i -= 1) {
    const row = context.diagnostics[i];
    if (row && row.label === label) return row;
  }
  return null;
}

function streamForSeal(context, seal) {
  if (!context || !context.answerStreamsBySeal) return null;
  const stream = context.answerStreamsBySeal[String(seal)];
  return stream ? { first: stream.first, directionStep: stream.directionStep } : null;
}

function yearKey(year) {
  return year.number.toString() + ':' + year.openDay.toString() + ':' + year.closeDay.toString();
}

function compactSauceSnapshot(result) {
  if (!result || !result.counts || !Array.isArray(result.bowls) || !Array.isArray(result.orderAt46Latch)) {
    throw new TypeError('Li Sauce real ne expone li checkpoints minim por li trace.');
  }
  return {
    counters: cloneCounts(result.counts),
    finalBowls: sixBowls(result.bowls),
    orderAtDrop46: result.orderAt46Latch.slice(),
    stage56SavedSumApplied: result.stage56SavedSumApplied === true,
    stage56RawBowlSumApplied: result.stage56RawBowlSumApplied === true,
  };
}


function createCookingCheckpointCollector() {
  const hidden = new Map();
  const visible = new Map();
  const initialBowls = [];
  const bowlRounds = [];
  const postStirs = [];
  let stoneSeed = null;
  const stoneTransitions = [];

  const observer = (kind, payload) => {
    if (kind === 'stone-seed') {
      stoneSeed = { ...payload, values: { ...payload.values } };
      return;
    }
    if (kind === 'stone-transition') {
      stoneTransitions.push({
        ...payload,
        before: { ...payload.before },
        rawBeforeSave: { ...payload.rawBeforeSave },
        after: { ...payload.after },
      });
      return;
    }
    if (kind === 'hidden-start') {
      hidden.set(payload.ordinal, { ...payload, grinds: [] });
      return;
    }
    if (kind === 'hidden-grind') {
      const row = hidden.get(payload.ordinal);
      if (!row) throw new Error('Hidden-grind apari ante su hidden-start.');
      row.grinds.push({ ...payload });
      return;
    }
    if (kind === 'visible-start') {
      visible.set(payload.ordinal, { ...payload, grinds: [] });
      return;
    }
    if (kind === 'visible-grind') {
      const row = visible.get(payload.ordinal);
      if (!row) throw new Error('Visible-grind apari ante su visible-start.');
      row.grinds.push({ ...payload });
      return;
    }
    if (kind === 'initial-bowl') {
      initialBowls.push({ ...payload });
      return;
    }
    if (kind === 'bowl-round') {
      bowlRounds.push({
        ...payload,
        order: payload.order.slice(),
        pours: payload.pours.slice(),
        beforeBowls: payload.beforeBowls.slice(),
        positions: payload.positions.map((row) => ({ ...row })),
        afterBowls: payload.afterBowls.slice(),
        stoneRow: { ...payload.stoneRow },
      });
      return;
    }
    if (kind === 'post-stir') {
      postStirs.push({
        ...payload,
        order: payload.order.slice(),
        positions: Array.isArray(payload.positions) ? payload.positions.map((row) => ({ ...row })) : [],
        afterBowls: payload.afterBowls.slice(),
      });
      return;
    }
    throw new Error('Ínconosset cooking checkpoint: ' + String(kind));
  };

  return {
    observer,
    snapshot() {
      return {
        hiddenDrops: Array.from(hidden.values())
          .sort((a, b) => a.ordinal - b.ordinal)
          .map((row) => ({ ...row, grinds: row.grinds.map((grind) => ({ ...grind })) })),
        visibleDrops: Array.from(visible.values())
          .sort((a, b) => a.ordinal - b.ordinal)
          .map((row) => ({ ...row, grinds: row.grinds.map((grind) => ({ ...grind })) })),
        stoneSeed: stoneSeed ? { ...stoneSeed, values: { ...stoneSeed.values } } : null,
        stoneTransitions: stoneTransitions
          .slice()
          .sort((a, b) => a.ordinal - b.ordinal)
          .map((row) => ({
            ...row,
            before: { ...row.before },
            rawBeforeSave: { ...row.rawBeforeSave },
            after: { ...row.after },
          })),
        initialBowls: initialBowls.slice().sort((a, b) => a.bowlId - b.bowlId),
        bowlRounds: bowlRounds.slice().sort((a, b) => a.ordinal - b.ordinal),
        postStirs: postStirs.slice().sort((a, b) => a.stirIndex - b.stirIndex),
      };
    },
  };
}

class NormativeExecutionRecorder {
  constructor() {
    this.nextSauceOrdinal = 1;
    this.sauceRuns = [];
    this.gates = new Map([[0n, FOUNDATION_DAY]]);
    this.gateGaps = new Map();
    this.activeGateStack = [];
    this.transitions = [];
    this.authoritativeYears = [];
    this.authoritativeYearKeys = new Set();
    this.year5000 = null;
    this.nextSelectionOrdinal = 1;
    this.selectionEvents = [];
    this.gateDetailSinkErrors = [];
  }

  recordSelection(kind, payload) {
    if (kind !== 'selection-result' || !payload || typeof payload !== 'object') {
      throw new TypeError('Li recorder expecta un selection-result checkpoint.');
    }
    const gateIndex = this.activeGateStack.length
      ? this.activeGateStack[this.activeGateStack.length - 1]
      : null;
    this.selectionEvents.push({
      id: 'selection-' + String(this.nextSelectionOrdinal++),
      gateIndex,
      ...payload,
      rejectionEncoding: payload.rejectionEncoding
        ? { ...payload.rejectionEncoding }
        : null,
      digits: Array.isArray(payload.digits) ? payload.digits.slice() : null,
    });
  }

  beginGateGap(signedIndex) {
    this.activeGateStack.push(signedIndex);
    if (!this.gateGaps.has(signedIndex)) {
      this.gateGaps.set(signedIndex, {
        signedIndex,
        gap: null,
        sauceRunId: null,
      });
    }
  }

  finishGateGap(signedIndex, gap) {
    const row = this.gateGaps.get(signedIndex);
    if (!row) throw new Error('Li recorder perdit un gate-gap activ.');
    row.gap = gap;
  }

  endGateGap(signedIndex) {
    const active = this.activeGateStack.pop();
    if (active !== signedIndex) throw new Error('Li stack de gate-gap diverge.');
  }

  recordGate(index, day) {
    const old = this.gates.get(index);
    if (old !== undefined && old !== day) {
      throw new Error('Un sam gate index apari con du dies diferent.');
    }
    this.gates.set(index, day);
  }

  recordSauce(calculationDay, targetDay, result, coreCheckpoints = null) {
    const gateIndex = this.activeGateStack.length
      ? this.activeGateStack[this.activeGateStack.length - 1]
      : null;
    const row = {
      id: 'sauce-' + String(this.nextSauceOrdinal++),
      calculationDay,
      targetDay,
      gateIndex,
      transitionId: null,
      detailStreamed: false,
      compact: compactSauceSnapshot(result),
      coreCheckpoints: coreCheckpoints || null,
      fullResult: coreCheckpoints || gateIndex === null ? result : null,
      stage56StateRef: gateIndex === null && result ? result.stage56PostStirContext || null : null,
    };
    this.sauceRuns.push(row);
    if (gateIndex !== null) {
      const gap = this.gateGaps.get(gateIndex);
      if (!gap) throw new Error('Li Sauce de gate manca su record de gate-gap.');
      gap.sauceRunId = row.id;
    }
    return result;
  }

  latestTransitionSauce(calculationDay, sharedDay) {
    for (let i = this.sauceRuns.length - 1; i >= 0; i -= 1) {
      const row = this.sauceRuns[i];
      if (row.gateIndex === null
          && row.transitionId === null
          && row.calculationDay === calculationDay
          && row.targetDay === sharedDay) return row;
    }
    return null;
  }

  recordTransition(calculationDay, knownYear, direction, resultYear) {
    const sharedDay = direction === 'next' ? knownYear.closeDay : knownYear.openDay;
    const sauce = this.latestTransitionSauce(calculationDay, sharedDay);
    const row = {
      id: 'year-transition-' + String(this.transitions.length + 1),
      calculationDay,
      direction,
      fromYear: cloneYear(knownYear),
      toYear: cloneYear(resultYear),
      sharedDay,
      sauceRunId: sauce ? sauce.id : null,
      semantic: false,
    };
    if (sauce) sauce.transitionId = row.id;
    this.transitions.push(row);
  }

  recordYear5000(year) {
    if (this.year5000 === null) this.year5000 = cloneYear(year);
    else if (!sameYear(this.year5000, year)) throw new Error('Year 5000 diverge intra un unic trace.');
  }

  recordAuthoritativeYear(year, lineage) {
    const cloned = cloneYear(year);
    const key = lineage + '|' + yearKey(cloned);
    if (this.authoritativeYearKeys.has(key)) return;
    this.authoritativeYearKeys.add(key);
    this.authoritativeYears.push({ lineage, year: cloned });
    if (lineage === 'next' || lineage === 'previous') {
      for (let i = this.transitions.length - 1; i >= 0; i -= 1) {
        const transition = this.transitions[i];
        if (!transition.semantic
            && transition.direction === lineage
            && sameYear(transition.toYear, cloned)) {
          transition.semantic = true;
          break;
        }
      }
    }
  }
}

class TracingGateRegistry extends core.Stage54GateRegistry {
  constructor(provider, recorder, selectionCheckpoint, progress) {
    super(provider);
    this.recorder = recorder;
    this.progress = progress;
    this.cookingTraceSelectionCheckpoint = selectionCheckpoint;
  }

  gateGap(signedIndex) {
    this.recorder.beginGateGap(signedIndex);
    this.progress.emit('gate-gap-start', { signedIndex });
    try {
      const gap = super.gateGap(signedIndex);
      this.recorder.finishGateGap(signedIndex, gap);
      this.progress.emit('gate-gap-finished', { signedIndex, gap });
      return gap;
    } finally {
      this.recorder.endGateGap(signedIndex);
    }
  }

  ensureIndex(index) {
    const wasKnown = this.recorder.gates.has(index);
    const day = super.ensureIndex(index);
    this.recorder.recordGate(index, day);
    if (!wasKnown) this.progress.emit('gate-ready', { index, day });
    return day;
  }
}

class TracingYearMemory extends core.Stage58RememberedYearDetourManager {
  constructor(provider, recorder, progress) {
    super(provider);
    this.recorder = recorder;
    this.progress = progress;
  }

  rememberYear5000(calculationDay, year) {
    const first = this.recorder.year5000 === null;
    this.recorder.recordYear5000(year);
    if (first) this.progress.emit('year-5000-memory', { calculationDay, year: cloneYear(year) });
    return super.rememberYear5000(calculationDay, year);
  }

  rememberTransition(calculationDay, knownYear, direction, resultYear) {
    const value = super.rememberTransition(calculationDay, knownYear, direction, resultYear);
    this.recorder.recordTransition(calculationDay, knownYear, direction, resultYear);
    this.progress.emit('year-transition', {
      calculationDay,
      direction,
      fromYear: cloneYear(knownYear),
      toYear: cloneYear(resultYear),
    });
    return value;
  }

  rememberAuthoritative(calculationDay, year, lineage = 'origin') {
    const before = this.recorder.authoritativeYears.length;
    const value = super.rememberAuthoritative(calculationDay, year, lineage);
    this.recorder.recordAuthoritativeYear(year, lineage);
    if (this.recorder.authoritativeYears.length !== before) {
      this.progress.emit('year-authoritative', { calculationDay, lineage, year: cloneYear(year) });
    }
    return value;
  }
}

class TracingStage57Manager extends core.Stage57MonsterIntegrationManager {
  constructor(registry, selectionCheckpoint, progressCheckpoint) {
    super(registry);
    this.cookingTraceSelectionCheckpoint = selectionCheckpoint;
    this.cookingTraceProgressCheckpoint = progressCheckpoint;
  }

  prepareFinal(calculationDay, targetDay) {
    const context = super.prepareFinal(calculationDay, targetDay);
    context.cookingTraceSelectionCheckpoint = this.cookingTraceSelectionCheckpoint;
    context.cookingTraceProgressCheckpoint = this.cookingTraceProgressCheckpoint;
    return context;
  }
}

function projectPostStirs(result) {
  const state = result.stage56PostStirContext;
  if (!state || !Array.isArray(state.history)) return [];
  let before = result.bowlsAfterDrops;
  return state.history.map((row) => {
    const after = row.correctedResult.bowls;
    const projected = {
      ordinal: row.stirIndex,
      beforeBowls: sixBowls(before),
      rawBowlSum: row.rawBowlSum,
      savedOrderNumber: row.savedOrderNumber,
      order: row.correctedResult.order.slice(),
      positions: Array.isArray(row.positions)
        ? row.positions.map((position) => ({ ...position }))
        : [],
      afterBowls: sixBowls(after),
    };
    before = after;
    return projected;
  });
}

function fullSauceProjection(run, role, stoneTableId) {
  const result = run.fullResult;
  const detail = run.coreCheckpoints;
  if (!result || !Array.isArray(result.stones)
      || !Array.isArray(result.hiddenBackward)
      || !Array.isArray(result.drops)
      || !Array.isArray(result.bowlsAfterDrops)) {
    throw new TypeError('Li Sauce central ne expone li checkpoints minim por un full trace.');
  }
  if (!detail
      || !Array.isArray(detail.hiddenDrops)
      || !Array.isArray(detail.visibleDrops)
      || !Array.isArray(detail.initialBowls)
      || !Array.isArray(detail.bowlRounds)) {
    throw new TypeError('Li Sauce central ne expone li checkpoints opt-in de cooking trace.');
  }

  const hiddenByOrdinal = new Map(detail.hiddenDrops.map((row) => [row.ordinal, row]));
  const visibleByOrdinal = new Map(detail.visibleDrops.map((row) => [row.ordinal, row]));
  const hiddenDrops = [];
  for (let ordinal = 1; ordinal <= 7; ordinal += 1) {
    const checkpoint = hiddenByOrdinal.get(ordinal);
    if (!checkpoint) throw new Error('Mancant hidden checkpoint ' + ordinal + '.');
    hiddenDrops.push({
      ordinal,
      value: result.hiddenBackward[8 - ordinal],
      coefficients: { ...checkpoint.coefficients },
      stoneRow: { ...checkpoint.stoneRow },
      rawBeforeSave: checkpoint.rawBeforeSave,
      initial: checkpoint.initial,
      grinds: checkpoint.grinds.map((grind) => ({ ...grind })),
    });
  }

  const visibleDrops = [];
  for (let ordinal = 1; ordinal <= 46; ordinal += 1) {
    const checkpoint = visibleByOrdinal.get(ordinal);
    if (!checkpoint) throw new Error('Mancant visible checkpoint ' + ordinal + '.');
    visibleDrops.push({
      ordinal,
      value: result.drops[ordinal],
      priors: { ...checkpoint.priors },
      stoneRow: { ...checkpoint.stoneRow },
      rawBeforeSave: checkpoint.rawBeforeSave,
      initial: checkpoint.initial,
      grinds: checkpoint.grinds.map((grind) => ({ ...grind })),
    });
  }

  return {
    id: run.id,
    role,
    inputs: {
      calculationDay: run.calculationDay,
      targetDay: run.targetDay,
    },
    counters: cloneCounts(result.counts),
    stoneTableRef: stoneTableId,
    hiddenDrops,
    visibleDrops,
    initialBowls: detail.initialBowls.map((row) => ({ ...row })),
    bowlRounds: detail.bowlRounds.map((row) => ({
      ordinal: row.ordinal,
      drop: row.drop,
      order: row.order.slice(),
      poursByPosition: row.pours.slice(1, 7),
      beforeBowls: sixBowls(row.beforeBowls),
      stoneRow: { ...row.stoneRow },
      positions: row.positions.map((position) => ({ ...position })),
      afterBowls: sixBowls(row.afterBowls),
    })),
    bowlsAfterDrops: sixBowls(result.bowlsAfterDrops),
    orderAtDrop46: result.orderAt46Latch.slice(),
    postStirs: projectPostStirs(result),
    finalBowls: sixBowls(result.bowls),
    coverage: {
      counters: 'captured',
      stoneRows: 'shared-artifact',
      hiddenDropValues: 'captured',
      hiddenGrinds: 'captured-at-execution',
      visibleDropValues: 'captured',
      visiblePriorsAndGrinds: 'captured-at-execution',
      initialBowls: 'captured-at-execution',
      bowlRounds: 'captured-at-execution',
      postStirRounds: 'captured',
      postStirPositionU: 'captured-at-execution',
      stoneTransitionOperands: 'shared-artifact-captured-at-execution',
    },
  };
}

function buildStoneTable(recorder) {
  const run = recorder.sauceRuns.find((item) =>
    item.fullResult
    && Array.isArray(item.fullResult.stones)
    && item.coreCheckpoints
    && item.coreCheckpoints.stoneSeed
    && Array.isArray(item.coreCheckpoints.stoneTransitions)
  );
  if (!run) return null;
  const transitions = new Map(
    run.coreCheckpoints.stoneTransitions.map((row) => [row.ordinal, row]),
  );
  return {
    id: 'stone-table-1',
    seed: {
      ordinal: run.coreCheckpoints.stoneSeed.ordinal,
      values: { ...run.coreCheckpoints.stoneSeed.values },
    },
    rows: run.fullResult.stones.map((row, index) => {
      const ordinal = index + 1;
      const transition = transitions.get(ordinal) || null;
      return {
        ordinal,
        values: { w: row.w, b: row.b, s: row.s, m: row.m, r: row.r },
        transition: transition ? {
          index: transition.index,
          before: { ...transition.before },
          rawBeforeSave: { ...transition.rawBeforeSave },
          after: { ...transition.after },
        } : null,
      };
    }),
  };
}

function assignSauceRoles(recorder, context, stoneTableId) {
  const labelByState = new Map();
  for (const row of context.stage56SauceStates || []) {
    if (row && row.state) labelByState.set(row.state, row.label);
  }

  const transitionBySauce = new Map();
  for (const row of recorder.transitions) {
    if (row.semantic && row.sauceRunId) transitionBySauce.set(row.sauceRunId, row);
  }

  const central = [];
  for (const run of recorder.sauceRuns) {
    if (!run.fullResult) continue;
    let role = null;
    if (transitionBySauce.has(run.id)) {
      const transition = transitionBySauce.get(run.id);
      role = {
        kind: 'year-transition',
        direction: transition.direction,
        fromYear: transition.fromYear,
        toYear: transition.toYear,
        sharedDay: transition.sharedDay,
      };
    } else {
      const label = labelByState.get(run.stage56StateRef) || null;
      if (label === 'year-5000') role = { kind: 'year-5000' };
      else if (label === 'structure-sauce') role = { kind: 'year-structure' };
    }
    if (role) central.push(fullSauceProjection(run, role, stoneTableId));
  }
  return central;
}

function projectGateNetwork(recorder) {
  const gates = Array.from(recorder.gates.entries())
    .sort((a, b) => compareBigInt(a[0], b[0]))
    .map(([index, day]) => ({ index, day }));
  const gaps = Array.from(recorder.gateGaps.values())
    .sort((a, b) => compareBigInt(a.signedIndex, b.signedIndex))
    .map((row) => {
      const sauce = recorder.sauceRuns.find((item) => item.id === row.sauceRunId);
      return {
        signedIndex: row.signedIndex,
        gap: row.gap,
        sauceRunId: row.sauceRunId,
        sauceSummary: sauce ? sauce.compact : null,
        detailCoverage: sauce && sauce.detailStreamed ? 'streamed-same-execution' : 'compact-stream-option-available',
      };
    });
  return { gates, gaps };
}

function projectSelections(recorder) {
  return recorder.selectionEvents.map((row) => ({
    id: row.id,
    gateIndex: row.gateIndex,
    sourceLabel: row.label,
    mode: row.mode,
    familySize: row.familySize,
    stream: {
      first: row.streamFirst,
      directionStep: row.directionStep,
    },
    places: row.places === undefined ? null : row.places,
    space: row.space === undefined ? null : row.space,
    digits: Array.isArray(row.digits) ? row.digits.slice() : null,
    acceptanceLimit: row.acceptanceLimit,
    firstCandidate: row.firstCandidate === undefined ? null : row.firstCandidate,
    initialWide: row.initialWide === undefined ? null : row.initialWide,
    rejectionSteps: row.rejectionSteps,
    acceptedCandidate: row.acceptedCandidate,
    output: row.output,
    rejectionEncoding: row.rejectionEncoding ? { ...row.rejectionEncoding } : null,
  }));
}

function projectFinalResult(result) {
  return {
    year: result[0],
    cutlet: {
      canonicalIndex: canonicalIndexFor('cutlet', result[1]),
      sourceName: result[1],
    },
    dayInCutlet: result[2],
    month: {
      canonicalIndex: canonicalIndexFor('month', result[3]),
      sourceName: result[3],
    },
    dayInMonth: result[4],
  };
}

function projectStructure(context, centralSauces) {
  const structure = context.structure;
  if (!structure) throw new Error('Li execution real finit sin structura de year.');

  const structureSauce = centralSauces.find((run) => run.role.kind === 'year-structure') || null;
  const partition = findDiagnostic(context, 'cutlet-partition-scar');
  const cutletNames = findDiagnostic(context, 'cutlet-names');
  const monthLengths = findDiagnostic(context, 'month-length-concrete-scar');
  const monthWeaving = findDiagnostic(context, 'month-weaving-ghost');
  const monthNames = findDiagnostic(context, 'month-names');

  return {
    sauceRunId: structureSauce ? structureSauce.id : null,
    year: {
      number: structure.yearNumber,
      openDay: structure.yearOpenDay,
      closeDay: structure.yearCloseDay,
    },
    cutlets: {
      count: structure.cutletCount,
      partition: structure.cutletPartition.slice(),
      nameCanonicalIndices: structure.cutletNameIndices.slice(),
      items: structure.cutlets.map((row) => ({
        nameCanonicalIndex: row.nameIndex,
        sourceName: core.textByCanonicalIndex('cutlet', row.nameIndex),
        openGateIndex: row.openGateIndex,
        closeGateIndex: row.closeGateIndex,
        firstDay: row.firstDay,
        lastDay: row.lastDay,
      })),
      countStream: streamForSeal(context, 20),
      partitionStream: streamForSeal(context, 21),
      partitionSelection: partition ? {
        familyCount: partition.semanticCount,
        selectedRank: partition.semanticRank,
        requiredInternalGateOffset: partition.internalOffset,
      } : null,
      nameStream: streamForSeal(context, 22),
      nameSelection: cutletNames ? {
        familyCount: cutletNames.distinctFamilyCount,
        selectedRank: cutletNames.correctRank,
      } : null,
    },
    months: {
      count: structure.monthCount,
      lengths: structure.monthLengths.slice(),
      weaving: structure.monthWeaving.slice(),
      nameCanonicalIndices: structure.monthNameIndices.slice(),
      items: structure.monthLengths.map((length, index) => ({
        slot: index + 1,
        length,
        nameCanonicalIndex: structure.monthNameIndices[index],
        sourceName: core.textByCanonicalIndex('month', structure.monthNameIndices[index]),
      })),
      countStream: streamForSeal(context, 30),
      lengthStream: streamForSeal(context, 31),
      lengthSelection: monthLengths ? {
        familyCount: monthLengths.virtualCount,
        selectedRank: monthLengths.selectedRank,
      } : null,
      weavingStream: streamForSeal(context, 32),
      weavingSelection: monthWeaving ? {
        familyCount: monthWeaving.familyCount,
        selectedRank: monthWeaving.wantedRank,
      } : null,
      nameStream: streamForSeal(context, 33),
      nameSelection: monthNames ? {
        familyCount: monthNames.distinctFamilyCount,
        selectedRank: monthNames.correctRank,
      } : null,
    },
  };
}

function projectPositioning(context, finalResult) {
  const diagnostic = findDiagnostic(context, 'contiguous-month-ghost');
  return {
    targetDay: context.targetDay,
    year: cloneYear(context.currentYear),
    targetPositionInYear: diagnostic ? diagnostic.targetPosition : null,
    monthId: diagnostic ? diagnostic.monthId : null,
    dayInCutlet: finalResult.dayInCutlet,
    dayInMonth: finalResult.dayInMonth,
    cutletCanonicalIndex: finalResult.cutlet.canonicalIndex,
    monthCanonicalIndex: finalResult.month.canonicalIndex,
  };
}

function projectArchaeology(context, recorder) {
  const rows = [{
    kind: 'stage56-raw-bowl-sum-corrective',
    semanticRule: 'post-stir-u-uses-saved-order-number',
    historicalScarExecuted: true,
    historicalValuesIncluded: false,
  }];

  if (context.stage57Patch26RoundTripGhost) {
    rows.push({
      kind: 'stage57-patch26-round-trip-ghost',
      mismatch: context.stage57Patch26RoundTripMismatch === true,
      legacyGuardExecuted: context.stage57LegacyGuardExecuted === true,
      legacyGuardPassed: context.stage57LegacyGuardPassed === true,
      semanticYear: cloneYear(context.stage57SemanticYear || context.currentYear),
      ghostYear: cloneYear(context.stage57Patch26RoundTripGhost),
    });
  }

  const nonSemanticTransitions = recorder.transitions.filter((row) => !row.semantic);
  if (nonSemanticTransitions.length) {
    rows.push({
      kind: 'non-semantic-year-transition-executions',
      count: nonSemanticTransitions.length,
      valuesIncluded: false,
    });
  }

  return rows;
}

function buildChapters(trace) {
  const structureSauce = trace.artifacts.sauceRuns.find((run) => run.role.kind === 'year-structure');
  return [
    { id: 'inputs', kind: 'inputs', refs: [] },
    { id: 'gates', kind: 'gate-network', refs: trace.artifacts.gateNetwork.gaps.map((row) => row.sauceRunId).filter(Boolean) },
    { id: 'year-5000', kind: 'year-5000', refs: trace.artifacts.sauceRuns.filter((run) => run.role.kind === 'year-5000').map((run) => run.id) },
    { id: 'year-walk', kind: 'year-walk', refs: trace.artifacts.yearWalk.transitions.map((row) => row.sauceRunId).filter(Boolean) },
    { id: 'structure-sauce', kind: 'year-structure-sauce', refs: structureSauce ? [structureSauce.id] : [] },
    { id: 'cutlets', kind: 'cutlet-construction', refs: [] },
    { id: 'months', kind: 'month-construction-and-weaving', refs: [] },
    { id: 'position', kind: 'final-positioning', refs: [] },
    { id: 'result', kind: 'five-field-result', refs: [] },
  ];
}

function calendarDateSpaghettiCookingTrace(calculationDay, targetDay, options = null) {
  requireDay(calculationDay, 'Li calculation-day del cooking trace');
  requireDay(targetDay, 'Li target-day del cooking trace');
  const traceOptions = normalizeTraceOptions(options);
  const progress = createLiveProgressEmitter(traceOptions.onProgress);
  progress.emit('run-start', { calculationDay, targetDay });

  const recorder = new NormativeExecutionRecorder();
  const selectionCheckpoint = (kind, payload) => {
    recorder.recordSelection(kind, payload);
    progress.emit(kind, payload);
  };
  const provider = (cDay, tDay) => {
    const gateIndex = recorder.activeGateStack.length
      ? recorder.activeGateStack[recorder.activeGateStack.length - 1]
      : null;
    const streamGateDetail = gateIndex !== null
      && traceOptions.onGateSauceDetail !== null
      && (traceOptions.gateDetailGateIndices === null
        || traceOptions.gateDetailGateIndices.has(gateIndex));
    const sauceId = 'sauce-' + String(recorder.nextSauceOrdinal);
    progress.emit('sauce-start', { sauceId, calculationDay: cDay, targetDay: tDay, gateIndex });
    const collector = gateIndex === null || streamGateDetail || progress.enabled
      ? createCookingCheckpointCollector()
      : null;
    const checkpoint = collector
      ? (kind, payload) => {
        collector.observer(kind, payload);
        progress.emit(kind, { sauceId, gateIndex, ...payload });
      }
      : null;
    const result = core.sauceWithScarsStage56(
      cDay,
      tDay,
      checkpoint,
    );
    recorder.recordSauce(
      cDay,
      tDay,
      result,
      collector ? collector.snapshot() : null,
    );
    const run = recorder.sauceRuns[recorder.sauceRuns.length - 1];
    progress.emit('sauce-finished', {
      sauceId: run.id,
      gateIndex,
      calculationDay: cDay,
      targetDay: tDay,
      finalBowls: run.compact.finalBowls.slice(),
      orderAtDrop46: run.compact.orderAtDrop46.slice(),
    });
    if (streamGateDetail) {
      const detail = deepFreeze(exactJsonValue(fullSauceProjection(
        run,
        { kind: 'gate-gap', signedIndex: gateIndex },
        'stone-table-1',
      )));
      try {
        traceOptions.onGateSauceDetail(detail);
        run.detailStreamed = true;
      } catch (error) {
        recorder.gateDetailSinkErrors.push(error);
      } finally {
        run.coreCheckpoints = null;
        run.fullResult = null;
      }
    }
    return result;
  };

  const registry = new TracingGateRegistry(provider, recorder, selectionCheckpoint, progress);
  const progressCheckpoint = (kind, payload) => progress.emit(kind, payload);
  const manager = new TracingStage57Manager(registry, selectionCheckpoint, progressCheckpoint);
  manager.sauceProvider = provider;
  manager.stage58YearMemoryScar = new TracingYearMemory(provider, recorder, progress);

  const routed = manager.executeCalendarDate(calculationDay, targetDay);
  progress.emit('semantic-execution-finished', { result: routed.result.slice() });
  if (recorder.gateDetailSinkErrors.length) {
    const error = new Error('Un gate-detail sink fallit pos que li execution semantic finit.');
    error.cause = recorder.gateDetailSinkErrors[0];
    throw error;
  }
  const context = routed.context;
  const stoneTable = buildStoneTable(recorder);
  const centralSauces = assignSauceRoles(recorder, context, stoneTable ? stoneTable.id : null);
  const finalResult = projectFinalResult(routed.result);

  const semanticTransitions = recorder.transitions
    .filter((row) => row.semantic)
    .map((row) => ({
      direction: row.direction,
      fromYear: row.fromYear,
      toYear: row.toYear,
      sharedDay: row.sharedDay,
      sauceRunId: row.sauceRunId,
    }));

  const trace = {
    schemaVersion: TRACE_SCHEMA_VERSION,
    semanticProfile: TRACE_SEMANTIC_PROFILE,
    inputs: { calculationDay, targetDay },
    finalResult,
    chapters: [],
    artifacts: {
      stoneTable,
      sauceRuns: centralSauces,
      gateNetwork: projectGateNetwork(recorder),
      selections: projectSelections(recorder),
      yearWalk: {
        year5000: cloneYear(recorder.year5000 || context.year5000),
        authoritativeYears: recorder.authoritativeYears.map((row) => ({
          lineage: row.lineage,
          year: row.year,
        })),
        transitions: semanticTransitions,
        finalYear: cloneYear(context.currentYear),
        interval: '(open,close]',
      },
      structure: projectStructure(context, centralSauces),
      positioning: projectPositioning(context, finalResult),
    },
    archaeology: projectArchaeology(context, recorder),
    measurement: {
      totalSauceCallsObserved: recorder.sauceRuns.length,
      gateSauceCallsObserved: recorder.sauceRuns.filter((row) => row.gateIndex !== null).length,
      nonGateSauceCallsObserved: recorder.sauceRuns.filter((row) => row.gateIndex === null).length,
      gateCountMaterialized: recorder.gates.size,
      gateGapCountMaterialized: recorder.gateGaps.size,
      semanticYearTransitionCount: semanticTransitions.length,
      selectionCallsObserved: recorder.selectionEvents.length,
      selectionRejectionStepsObserved: recorder.selectionEvents.reduce(
        (sum, row) => sum + (typeof row.rejectionSteps === 'bigint' ? row.rejectionSteps : 0n),
        0n,
      ),
      gateDetailChunksStreamed: recorder.sauceRuns.filter((row) => row.detailStreamed === true).length,
    },
    coverage: {
      sameSemanticExecutionAsFinalResult: true,
      independentExplanationEngine: false,
      languageNeutralSemanticKeys: true,
      exactIntegerTransport: 'decimal-string',
      cacheDiagnosticsExcludedFromSemantics: true,
      stoneTransitionOperands: 'captured-at-execution-shared-artifact',
      selectionCandidateRejections: 'captured-lossless-run-encoding',
      gateSauceDetail: traceOptions.onGateSauceDetail === null
        ? 'same-execution-stream-option-available'
        : traceOptions.gateDetailGateIndices === null
          ? 'streamed-from-same-execution'
          : 'selected-gates-streamed-from-same-execution',
      gateSauceDetailTransport: 'one-json-safe-chunk-per-gate-sauce',
      gateDetailRequestedIndices: traceOptions.gateDetailGateIndices === null
        ? null
        : Array.from(traceOptions.gateDetailGateIndices.values()).sort(compareBigInt),
      missingCoreCheckpoints: [],
    },
  };
  trace.chapters = buildChapters(trace);
  progress.emit('trace-ready', {
    sauceRuns: recorder.sauceRuns.length,
    gates: recorder.gates.size,
    selections: recorder.selectionEvents.length,
  });

  return deepFreeze(exactJsonValue(trace));
}

module.exports = Object.freeze({
  TRACE_SCHEMA_VERSION,
  TRACE_SEMANTIC_PROFILE,
  calendarDateSpaghettiCookingTrace,
});
