/* Vendored without semantic modification from Sargon17-Green/pastafari-calendar main.
 * Source blob: 42637e8d83b373ef128b364d1ad62de3bfc81a09
 * Phase E reverse-search contract. Do not edit here independently of the source contract.
 */
"use strict";

/**
 * Local-only diagnostics for the Pastafari calendar runtime.
 *
 * Nothing in this module performs I/O, networking, persistence, logging, or
 * analytics. Diagnostics are disabled by default. Summary mode keeps bounded
 * aggregate counters/durations. Detailed mode additionally keeps a bounded
 * ring of trace events.
 */

export const PASTAFARI_DIAGNOSTICS_SCHEMA_VERSION = 1;
export const PASTAFARI_DIAGNOSTICS_MODES = Object.freeze([
  "disabled",
  "summary",
  "detailed",
]);
export const PASTAFARI_DIAGNOSTIC_OUTCOMES = Object.freeze([
  "ok",
  "cache-hit",
  "cache-miss",
  "fallback",
  "superseded",
  "timeout",
  "cancelled",
  "error",
]);

const DEFAULT_TRACE_LIMIT = 512;
const MAX_TRACE_LIMIT = 10_000;
const MAX_DATA_DEPTH = 5;
const MAX_COLLECTION_ITEMS = 512;
const MAX_SUMMARY_METRICS = 512;
const MAX_CHILD_SNAPSHOTS = 16;
const MAX_OPERATION_RECORDS = 50;
const MAX_STRING_LENGTH = 2_048;

let mode = "disabled";
let traceLimit = DEFAULT_TRACE_LIMIT;
let nextOperation = 1;
let nextTraceSequence = 1;
let diagnosticsEpoch = 1;
let appliedTransportEpoch = null;
let lastFallbackClockMs = 0;

const counters = new Map();
const durations = new Map();
const gauges = new Map();
const childSnapshots = new Map();
const operationRecords = [];
const trace = [];
let droppedMetricKeys = 0;
let droppedChildSnapshots = 0;

function validateMode(value) {
  if (!PASTAFARI_DIAGNOSTICS_MODES.includes(value)) {
    throw new RangeError(`Unknown diagnostics mode: ${String(value)}.`);
  }
  return value;
}

function validateTraceLimit(value) {
  const normalized = Number(value);
  if (!Number.isSafeInteger(normalized) || normalized < 0 || normalized > MAX_TRACE_LIMIT) {
    throw new RangeError(`traceLimit must be a safe integer in 0..${MAX_TRACE_LIMIT}.`);
  }
  return normalized;
}

/** Monotonic milliseconds in every supported production runtime. */
export function pastafariMonotonicNow() {
  // Update 15 deliberately keeps all three clocks alive, but a diagnostics
  // clock is not allowed to become a new source of calendar failure.  Walk the
  // old clock procession one bell at a time and leave the last good reading in
  // the ash bucket if a host hook throws.
  if (typeof globalThis.performance?.now === "function") {
    try {
      const value = globalThis.performance.now();
      if (Number.isFinite(value)) return value;
    } catch {}
  }
  const hrtime = globalThis.process?.hrtime;
  if (typeof hrtime?.bigint === "function") {
    try {
      const value = Number(hrtime.bigint()) / 1_000_000;
      if (Number.isFinite(value)) return value;
    } catch {}
  }

  // Very old JS hosts may expose neither performance.now nor hrtime. Clamp the
  // wall clock so it can never move backwards.  A hostile/test clock may throw
  // too; diagnostics then retain the previous monotonic witness instead of
  // steering the semantic operation.
  try {
    const wall = Date.now();
    if (Number.isFinite(wall)) lastFallbackClockMs = Math.max(lastFallbackClockMs, wall);
  } catch {}
  return lastFallbackClockMs;
}

const UPDATE15_SEEN_ASH_BUCKET = Object.freeze({
  has() { return false; },
  add() { return this; },
});

function sanitize(value, depth = 0, seen = null) {
  // The WeakSet allocation ritual remains. If test/fault injection makes that
  // decorative allocation fail, use a depth-bounded witness sink rather than
  // allowing diagnostics to replace a calendar result/exception.
  if (seen === null) {
    try { seen = new WeakSet(); }
    catch { seen = UPDATE15_SEEN_ASH_BUCKET; }
  }
  if (value === null || value === undefined) return value ?? null;
  if (typeof value === "bigint") return value.toString();
  if (typeof value === "string") {
    return value.length <= MAX_STRING_LENGTH
      ? value
      : `${value.slice(0, MAX_STRING_LENGTH)}…`;
  }
  if (typeof value === "number" || typeof value === "boolean") return value;
  if (typeof value === "symbol" || typeof value === "function") return String(value);
  if (value instanceof Error) {
    return {
      name: value.name || "Error",
      message: sanitize(value.message || String(value), depth + 1, seen),
      code: value.code ?? null,
    };
  }
  if (depth >= MAX_DATA_DEPTH) return "[depth-limit]";
  if (typeof value !== "object") return String(value);
  if (seen.has(value)) return "[circular]";
  seen.add(value);

  if (Array.isArray(value)) {
    return value.slice(0, MAX_COLLECTION_ITEMS).map((item) => sanitize(item, depth + 1, seen));
  }

  const out = {};
  for (const [key, item] of Object.entries(value).slice(0, MAX_COLLECTION_ITEMS)) {
    out[key] = sanitize(item, depth + 1, seen);
  }
  return out;
}

function setBoundedMetric(map, name, value) {
  if (map.has(name) || map.size < MAX_SUMMARY_METRICS) {
    map.set(name, value);
    return true;
  }
  droppedMetricKeys += 1;
  return false;
}

function pushTrace(subsystem, event, data = null, operationId = null) {
  if (mode !== "detailed" || traceLimit === 0) return;
  trace.push(Object.freeze({
    sequence: nextTraceSequence++,
    monotonicMs: pastafariMonotonicNow(),
    operationId,
    subsystem,
    event,
    data: data === null ? null : sanitize(data),
  }));
  if (trace.length > traceLimit) trace.splice(0, trace.length - traceLimit);
}

export function isPastafariDiagnosticsEnabled(requiredMode = "summary") {
  if (requiredMode === "detailed") return mode === "detailed";
  return mode !== "disabled";
}

export function configurePastafariDiagnostics(options = {}) {
  if (options === null || typeof options !== "object") {
    throw new TypeError("Diagnostics options must be an object.");
  }
  if (Object.hasOwn(options, "mode")) mode = validateMode(options.mode);
  if (Object.hasOwn(options, "traceLimit")) {
    traceLimit = validateTraceLimit(options.traceLimit);
    if (trace.length > traceLimit) trace.splice(0, trace.length - traceLimit);
  }
  return getPastafariDiagnosticsConfig();
}

export function getPastafariDiagnosticsConfig() {
  return Object.freeze({
    schemaVersion: PASTAFARI_DIAGNOSTICS_SCHEMA_VERSION,
    mode,
    traceLimit,
    epoch: diagnosticsEpoch,
  });
}

export function getPastafariDiagnosticsTransportConfig() {
  return Object.freeze({ mode, traceLimit, epoch: diagnosticsEpoch });
}

function clearDiagnosticState() {
  counters.clear();
  durations.clear();
  gauges.clear();
  childSnapshots.clear();
  operationRecords.length = 0;
  trace.length = 0;
  droppedMetricKeys = 0;
  droppedChildSnapshots = 0;
  nextOperation = 1;
  nextTraceSequence = 1;
}

export function applyPastafariDiagnosticsTransportConfig(config) {
  if (!config || typeof config !== "object") return getPastafariDiagnosticsConfig();
  if (Number.isSafeInteger(config.epoch) && config.epoch !== appliedTransportEpoch) {
    clearDiagnosticState();
    appliedTransportEpoch = config.epoch;
  }
  return configurePastafariDiagnostics({
    mode: config.mode ?? mode,
    traceLimit: config.traceLimit ?? traceLimit,
  });
}

export function resetPastafariDiagnostics() {
  clearDiagnosticState();
  diagnosticsEpoch += 1;
}

export function incrementDiagnosticCounter(name, delta = 1) {
  if (mode === "disabled") return;
  let exactDelta;
  if (typeof delta === "bigint") {
    exactDelta = delta;
  } else {
    const numeric = Number(delta);
    if (!Number.isSafeInteger(numeric)) return;
    exactDelta = numeric;
  }

  const current = counters.get(name);
  if (current !== undefined) {
    if (typeof current === "bigint" || typeof exactDelta === "bigint") {
      counters.set(name, BigInt(current) + BigInt(exactDelta));
      return;
    }
    const sum = current + exactDelta;
    counters.set(name, Number.isSafeInteger(sum) ? sum : BigInt(current) + BigInt(exactDelta));
    return;
  }
  setBoundedMetric(counters, name, exactDelta);
}

export function setDiagnosticGauge(name, value) {
  if (mode === "disabled") return;
  setBoundedMetric(gauges, name, sanitize(value));
}

export function observeDiagnosticDuration(name, durationMs) {
  if (mode === "disabled") return;
  const value = Number(durationMs);
  if (!Number.isFinite(value) || value < 0) return;
  const current = durations.get(name);
  if (!current) {
    setBoundedMetric(durations, name, {
      count: 1,
      totalMs: value,
      minMs: value,
      maxMs: value,
      lastMs: value,
    });
    return;
  }
  current.count += 1;
  current.totalMs += value;
  current.minMs = Math.min(current.minMs, value);
  current.maxMs = Math.max(current.maxMs, value);
  current.lastMs = value;
}

export function diagnosticTrace(subsystem, event, data = null, operationId = null) {
  pushTrace(subsystem, event, data, operationId);
}

export function beginDiagnosticOperation(subsystem, operation, data = null) {
  if (mode === "disabled") return null;
  const token = Object.freeze({
    id: `op-${nextOperation++}`,
    subsystem,
    operation,
    startedMs: pastafariMonotonicNow(),
    data: sanitize(data ?? {}),
  });
  incrementDiagnosticCounter(`${subsystem}.operations.started`);
  pushTrace(subsystem, "operation-start", { operation, ...sanitize(data ?? {}) }, token.id);
  return token;
}

export function endDiagnosticOperation(token, outcome = "ok", data = null) {
  if (!token || mode === "disabled") return 0;
  const durationMs = Math.max(0, pastafariMonotonicNow() - token.startedMs);
  incrementDiagnosticCounter(`${token.subsystem}.operations.finished`);
  incrementDiagnosticCounter(`${token.subsystem}.outcome.${outcome}`);
  observeDiagnosticDuration(`${token.subsystem}.${token.operation}`, durationMs);
  operationRecords.push(Object.freeze({
    id: token.id,
    subsystem: token.subsystem,
    operation: token.operation,
    startedMonotonicMs: token.startedMs,
    durationMs,
    outcome,
    start: token.data,
    end: sanitize(data ?? {}),
  }));
  if (operationRecords.length > MAX_OPERATION_RECORDS) {
    operationRecords.splice(0, operationRecords.length - MAX_OPERATION_RECORDS);
  }
  pushTrace(
    token.subsystem,
    "operation-end",
    { operation: token.operation, outcome, durationMs, ...sanitize(data ?? {}) },
    token.id,
  );
  return durationMs;
}

export function recordDiagnosticError(subsystem, error, operationId = null, data = null) {
  if (mode === "disabled") return;
  incrementDiagnosticCounter(`${subsystem}.errors`);
  pushTrace(subsystem, "error", {
    error: sanitize(error),
    ...sanitize(data ?? {}),
  }, operationId);
}

export function recordDiagnosticCacheLookup(cacheName, hit) {
  if (mode === "disabled") return;
  incrementDiagnosticCounter(`${cacheName}.${hit ? "hit" : "miss"}`);
}

export function recordDiagnosticCacheEviction(cacheName) {
  if (mode === "disabled") return;
  incrementDiagnosticCounter(`${cacheName}.eviction`);
}

export function mergePastafariDiagnosticsSnapshot(source, snapshot) {
  if (mode === "disabled" || typeof source !== "string" || !source) return;
  if (!snapshot || snapshot.schemaVersion !== PASTAFARI_DIAGNOSTICS_SCHEMA_VERSION) return;

  const sourceTraceLimit = Number.isSafeInteger(snapshot.traceLimit)
    ? Math.max(0, Math.min(snapshot.traceLimit, MAX_TRACE_LIMIT))
    : DEFAULT_TRACE_LIMIT;
  const cloned = {
    schemaVersion: snapshot.schemaVersion,
    mode: snapshot.mode,
    traceLimit: sourceTraceLimit,
    epoch: snapshot.epoch ?? null,
    generatedAtMonotonicMs: Number(snapshot.generatedAtMonotonicMs) || 0,
    limits: sanitize(snapshot.limits ?? {}),
    summary: {
      counters: sanitize(snapshot.summary?.counters ?? {}),
      durations: sanitize(snapshot.summary?.durations ?? {}),
      gauges: sanitize(snapshot.summary?.gauges ?? {}),
      droppedMetricKeys: Number(snapshot.summary?.droppedMetricKeys) || 0,
      droppedChildSnapshots: Number(snapshot.summary?.droppedChildSnapshots) || 0,
    },
    operations: Array.isArray(snapshot.operations)
      ? snapshot.operations.slice(-MAX_OPERATION_RECORDS).map((item) => sanitize(item))
      : [],
    trace: Array.isArray(snapshot.trace)
      ? snapshot.trace.slice(-sourceTraceLimit).map((item) => sanitize(item))
      : [],
  };
  if (childSnapshots.has(source) || childSnapshots.size < MAX_CHILD_SNAPSHOTS) {
    childSnapshots.set(source, cloned);
  } else {
    droppedChildSnapshots += 1;
  }
}

function sortedObject(map, transform = (value) => value) {
  return Object.fromEntries(
    [...map.entries()]
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, value]) => [key, transform(value)]),
  );
}

export function getPastafariDiagnosticsSnapshot() {
  return {
    schemaVersion: PASTAFARI_DIAGNOSTICS_SCHEMA_VERSION,
    mode,
    traceLimit,
    epoch: diagnosticsEpoch,
    generatedAtMonotonicMs: pastafariMonotonicNow(),
    limits: {
      maxMetricKeysPerKind: MAX_SUMMARY_METRICS,
      maxChildSnapshots: MAX_CHILD_SNAPSHOTS,
      maxOperationRecords: MAX_OPERATION_RECORDS,
      maxTraceEvents: traceLimit,
    },
    summary: {
      counters: sortedObject(counters, (value) => (typeof value === "bigint" ? value.toString() : value)),
      durations: sortedObject(durations, (value) => ({ ...value })),
      gauges: sortedObject(gauges),
      droppedMetricKeys,
      droppedChildSnapshots,
    },
    operations: operationRecords.map((record) => ({
      ...record,
      start: sanitize(record.start),
      end: sanitize(record.end),
    })),
    children: sortedObject(childSnapshots, (value) => JSON.parse(JSON.stringify(value))),
    trace: trace.map((item) => ({ ...item, data: sanitize(item.data) })),
  };
}
