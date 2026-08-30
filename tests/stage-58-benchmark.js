'use strict';

const { performance } = require('node:perf_hooks');
const { spawnSync } = require('node:child_process');
const production = require('../src');

const C = -15048173n;

function canonical(result) {
  return result.map((value) => typeof value === 'bigint' ? value.toString() : value);
}

function metricSnapshot() {
  return production.stage58AccelerationSnapshot().metrics;
}

function metricDelta(before, after, key) {
  return Number((after[key] || 0n) - (before[key] || 0n));
}

function makeStage(stage) {
  if (stage === 54) {
    const registry = new production.Stage54GateRegistry(production.sauceWithScars);
    return { registry, manager: new production.Stage54MonsterIntegrationManager(registry, production.sauceWithScars, false) };
  }
  const registry = new production.Stage54GateRegistry(production.sauceWithScarsStage56);
  const manager = stage === 56
    ? new production.Stage56MonsterIntegrationManager(registry)
    : new production.Stage57MonsterIntegrationManager(registry);
  return { registry, manager };
}

function measured(label, holder, target) {
  const before = metricSnapshot();
  const gapBefore = holder.registry.gapCalls;
  const checkpointBefore = holder.registry.stage58GateCheckpointHits;
  const start = performance.now();
  let routed = null;
  let error = null;
  try {
    routed = holder.manager.executeCalendarDate(C, target);
  } catch (caught) {
    error = { name: caught.name, message: caught.message };
  }
  const milliseconds = performance.now() - start;
  const after = metricSnapshot();
  const events = routed ? routed.context.cacheEvents : [];
  return {
    label,
    calculationDay: C.toString(),
    targetDay: target.toString(),
    milliseconds: Number(milliseconds.toFixed(3)),
    result: routed ? canonical(routed.result) : null,
    error,
    sauceComputations: metricDelta(before, after, 'stage58.sauce54.recomputations') + metricDelta(before, after, 'stage58.sauce56.recomputations'),
    sauceCacheHits: metricDelta(before, after, 'stage58.sauce54.hits') + metricDelta(before, after, 'stage58.sauce56.hits'),
    gateGapComputations: Number(holder.registry.gapCalls - gapBefore),
    gateCheckpointHits: Number(holder.registry.stage58GateCheckpointHits - checkpointBefore),
    year5000Hits: metricDelta(before, after, 'stage58.years.year5000Hits'),
    adjacentYearBuilds: metricDelta(before, after, 'stage58.years.adjacentBuilds'),
    adjacentYearTransitionHits: metricDelta(before, after, 'stage58.years.transitionHits'),
    semanticStructureHits: metricDelta(before, after, 'stage58.structure.hits'),
    semanticStructureMisses: metricDelta(before, after, 'stage58.structure.misses'),
    virtualDpBackendHits: metricDelta(before, after, 'stage58.virtualDp.backendHits'),
    virtualDpBackendMisses: metricDelta(before, after, 'stage58.virtualDp.backendMisses'),
    weavingDpBackendHits: metricDelta(before, after, 'stage58.weavingDp.backendHits'),
    weavingDpBackendMisses: metricDelta(before, after, 'stage58.weavingDp.backendMisses'),
    rejectionIterations: metricDelta(before, after, 'stage58.selection.rejectionIterations'),
    rejectionIterationsAvoided: metricDelta(before, after, 'stage58.selection.rejectionIterationsAvoided'),
    selectionCacheHits: metricDelta(before, after, 'stage58.selection.hits'),
    selectionCacheMisses: metricDelta(before, after, 'stage58.selection.misses'),
    gatesMaterializedInRegistry: Number(holder.registry.maxKnownGateIndex - holder.registry.minKnownGateIndex + 1n),
    cacheEvents: events.map((event) => event.type)
  };
}

function print(row) {
  process.stdout.write(JSON.stringify(row) + '\n');
}

if (process.argv[2] === '--warm-child') {
  production.resetStage58AccelerationMetrics();
  const holder = makeStage(57);
  print(measured('cold-single-stage57', holder, C));
  print(measured('identical-repeat-stage57', holder, C));
  print(measured('same-year-target+1', holder, C + 1n));
  print(measured('same-year-target-1', holder, C - 1n));
  print(measured('same-calculation-day-forward-2500', holder, C + 2500n));
  print(measured('neighboring-year-backward-2500', holder, C - 2500n));
  print(measured('far-forward-12000', holder, C + 12000n));
  process.exit(0);
}

if (process.argv[2] === '--single-child') {
  const stage = Number(process.argv[3]);
  const offset = BigInt(process.argv[4]);
  production.resetStage58AccelerationMetrics();
  const holder = makeStage(stage);
  print(measured('stage-' + stage + '-offset-' + offset.toString(), holder, C + offset));
  process.exit(0);
}

function child(args) {
  const run = spawnSync(process.execPath, [__filename, ...args], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
  if (run.status !== 0) {
    process.stderr.write(run.stderr || 'Stage 58 benchmark child fallit.\n');
    process.exit(run.status === null ? 1 : run.status);
  }
  process.stdout.write(run.stdout);
}

// Li far-backward e li routes historic es process-isolat por evitar que V8 heap pressure de un witness
// modifica li wall-clock del witness sequent. Li warm cases resta intentionalmen in un sam manager.
child(['--warm-child']);
child(['--single-child', '57', '-12000']);
child(['--single-child', '54', '0']);
child(['--single-child', '56', '0']);
