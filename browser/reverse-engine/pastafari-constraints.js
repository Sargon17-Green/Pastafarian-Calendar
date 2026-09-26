/* Vendored without semantic modification from Sargon17-Green/pastafari-calendar main.
 * Source blob: 9f4b8524c4715d0248b9731fdcfd2c27c684d9b4
 * Phase E reverse-search contract. Do not edit here independently of the source contract.
 */
"use strict";

import {
  beginDiagnosticOperation,
  diagnosticTrace,
  endDiagnosticOperation,
  incrementDiagnosticCounter,
  recordDiagnosticError,
} from "./pastafari-diagnostics.js";
import {
  GregorianDate,
  PastafariCalendar,
  SAME_AS_TARGET,
  findPastafariDate,
  gregorianToJdn,
} from "./pastafari-calendar-fast.js";

const DEFAULT_YIELD_EVERY = 128;

function fail(ErrorType, message, code, extra = {}) {
  const error = new ErrorType(message);
  error.code = code;
  Object.assign(error, extra);
  throw error;
}

function abortError() {
  incrementDiagnosticCounter("constraints.cancellations");
  const error = new Error("Pastafari constraint solving was aborted.");
  error.name = "AbortError";
  error.code = "ERR_REVERSE_ABORTED";
  return error;
}

async function breathe() {
  if (typeof setTimeout === "function") {
    await new Promise((resolve) => setTimeout(resolve, 0));
  } else {
    await Promise.resolve();
  }
}

function toBigInt(value, fieldName) {
  if (typeof value === "bigint") return value;
  if (typeof value === "number" && Number.isSafeInteger(value)) return BigInt(value);
  if (typeof value === "string" && /^[+-]?\d+$/.test(value.trim())) return BigInt(value.trim());
  fail(TypeError, `${fieldName} must be an integer JDN.`, "ERR_CONSTRAINT_JDN");
}

function absoluteToJdn(value, fieldName) {
  if (typeof value === "bigint" || typeof value === "number") return toBigInt(value, fieldName);
  if (typeof value === "string") {
    const text = value.trim();
    if (/^[+-]?\d+$/.test(text)) return BigInt(text);
    const match = /^([+-]?\d+)-(\d{2})-(\d{2})$/.exec(text);
    if (match) return gregorianToJdn(new GregorianDate(match[1], Number(match[2]), Number(match[3])));
    fail(RangeError, `${fieldName} must be an integer JDN or ISO Gregorian date.`, "ERR_CONSTRAINT_JDN");
  }
  if (value instanceof GregorianDate) return gregorianToJdn(value);
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) fail(RangeError, `${fieldName} is an invalid Date.`, "ERR_CONSTRAINT_JDN");
    return gregorianToJdn(new GregorianDate(value.getFullYear(), value.getMonth() + 1, value.getDate()));
  }
  if (value && typeof value === "object" && Object.hasOwn(value, "jdn")) {
    return toBigInt(value.jdn, `${fieldName}.jdn`);
  }
  if (value && typeof value === "object" && "year" in value && "month" in value && "day" in value) {
    return gregorianToJdn(new GregorianDate(value.year, Number(value.month), Number(value.day)));
  }
  fail(TypeError, `${fieldName} must be a JDN or Gregorian date.`, "ERR_CONSTRAINT_JDN");
}

function normalizePastafariDate(value, fieldName) {
  const source = typeof value?.toJSON === "function" ? value.toJSON() : value;
  if (!source || typeof source !== "object") {
    fail(TypeError, `${fieldName} must be a Pastafari date object.`, "ERR_CONSTRAINT_PASTAFARI_DATE");
  }
  let year;
  try {
    year = BigInt(source.year);
  } catch {
    fail(TypeError, `${fieldName}.year must be an integer.`, "ERR_CONSTRAINT_PASTAFARI_DATE");
  }
  const dayInCutlet = Number(source.dayInCutlet);
  const dayInMonth = Number(source.dayInMonth);
  if (!Number.isSafeInteger(dayInCutlet) || dayInCutlet < 1) {
    fail(RangeError, `${fieldName}.dayInCutlet must be a positive safe integer.`, "ERR_CONSTRAINT_PASTAFARI_DATE");
  }
  if (!Number.isSafeInteger(dayInMonth) || dayInMonth < 1) {
    fail(RangeError, `${fieldName}.dayInMonth must be a positive safe integer.`, "ERR_CONSTRAINT_PASTAFARI_DATE");
  }
  if (typeof source.cutletName !== "string" || typeof source.monthName !== "string") {
    fail(TypeError, `${fieldName} must contain cutletName and monthName strings.`, "ERR_CONSTRAINT_PASTAFARI_DATE");
  }
  return Object.freeze({ year, cutletName: source.cutletName, dayInCutlet, monthName: source.monthName, dayInMonth });
}

function samePastafari(actual, wanted) {
  const source = typeof actual?.toJSON === "function" ? actual.toJSON() : actual;
  return !!source
    && BigInt(source.year) === wanted.year
    && source.cutletName === wanted.cutletName
    && Number(source.dayInCutlet) === wanted.dayInCutlet
    && source.monthName === wanted.monthName
    && Number(source.dayInMonth) === wanted.dayInMonth;
}

function jdnToGregorian(jdn) {
  const floorDiv = (a, b) => {
    let q = a / b;
    const r = a % b;
    if (r !== 0n && ((r > 0n) !== (b > 0n))) q -= 1n;
    return q;
  };
  const a = jdn + 32044n;
  const b = floorDiv(4n * a + 3n, 146097n);
  const c = a - floorDiv(146097n * b, 4n);
  const d = floorDiv(4n * c + 3n, 1461n);
  const e = c - floorDiv(1461n * d, 4n);
  const m = floorDiv(5n * e + 2n, 153n);
  const day = e - floorDiv(153n * m + 2n, 5n) + 1n;
  const month = m + 3n - 12n * floorDiv(m, 10n);
  const year = 100n * b + d - 4800n + floorDiv(m, 10n);
  return new GregorianDate(year, Number(month), Number(day));
}

function normalizeRange(value, fieldName) {
  if (value === undefined || value === null) return null;
  let first;
  let last;
  if (Array.isArray(value) && value.length === 2) {
    [first, last] = value;
  } else if (typeof value === "object" && "start" in value && "end" in value) {
    first = value.start;
    last = value.end;
  } else {
    fail(TypeError, `${fieldName} must be [start,end] or {start,end}.`, "ERR_CONSTRAINT_RANGE");
  }
  const min = absoluteToJdn(first, `${fieldName}.start`);
  const max = absoluteToJdn(last, `${fieldName}.end`);
  if (max < min) fail(RangeError, `${fieldName}.end precedes start.`, "ERR_CONSTRAINT_RANGE");
  return { min, max };
}

function cloneDomain(domain) {
  return {
    min: domain.min,
    max: domain.max,
    candidates: domain.candidates === null ? null : new Set(domain.candidates),
  };
}

function domainEmpty(domain) {
  return domain.min !== null && domain.max !== null && domain.max < domain.min
    || domain.candidates !== null && domain.candidates.size === 0;
}

function finiteBounds(domain) {
  if (domain.candidates !== null) {
    if (domain.candidates.size === 0) return null;
    let min = null;
    let max = null;
    for (const value of domain.candidates) {
      if (min === null || value < min) min = value;
      if (max === null || value > max) max = value;
    }
    return { min, max };
  }
  if (domain.min === null || domain.max === null) return null;
  return { min: domain.min, max: domain.max };
}

function cardinality(domain) {
  if (domain.candidates !== null) return BigInt(domain.candidates.size);
  if (domain.min === null || domain.max === null) return null;
  return domain.max - domain.min + 1n;
}

function singleton(domain) {
  if (domain.candidates !== null) {
    if (domain.candidates.size !== 1) return null;
    return domain.candidates.values().next().value;
  }
  return domain.min !== null && domain.max !== null && domain.min === domain.max ? domain.min : null;
}

function hasValue(domain, value) {
  if (domain.min !== null && value < domain.min) return false;
  if (domain.max !== null && value > domain.max) return false;
  return domain.candidates === null || domain.candidates.has(value);
}

function intersectRange(domain, min, max) {
  let changed = false;
  if (min !== null && (domain.min === null || min > domain.min)) {
    domain.min = min;
    changed = true;
  }
  if (max !== null && (domain.max === null || max < domain.max)) {
    domain.max = max;
    changed = true;
  }
  if (domain.candidates !== null) {
    for (const value of [...domain.candidates]) {
      if ((domain.min !== null && value < domain.min) || (domain.max !== null && value > domain.max)) {
        domain.candidates.delete(value);
        changed = true;
      }
    }
  }
  return changed;
}

function intersectCandidates(domain, values) {
  const next = new Set();
  for (const value of values) if (hasValue(domain, value)) next.add(value);
  if (domain.candidates === null) {
    domain.candidates = next;
    return true;
  }
  let changed = false;
  for (const value of [...domain.candidates]) {
    if (!next.has(value)) {
      domain.candidates.delete(value);
      changed = true;
    }
  }
  return changed;
}

function domainValues(domain) {
  if (domain.candidates !== null) return [...domain.candidates].sort((a, b) => a < b ? -1 : a > b ? 1 : 0);
  if (domain.min === null || domain.max === null) return null;
  const values = [];
  for (let value = domain.min; value <= domain.max; value += 1n) values.push(value);
  return values;
}

function normalizeVariables(problem) {
  if (!problem || typeof problem !== "object") fail(TypeError, "Constraint problem must be an object.", "ERR_CONSTRAINT_PROBLEM");
  if (!problem.variables || typeof problem.variables !== "object" || Array.isArray(problem.variables)) {
    fail(TypeError, "problem.variables must be an object keyed by variable name.", "ERR_CONSTRAINT_VARIABLES");
  }
  const variables = new Map();
  for (const [name, spec0] of Object.entries(problem.variables)) {
    if (!name) fail(RangeError, "Variable names must not be empty.", "ERR_CONSTRAINT_VARIABLE");
    const spec = spec0 ?? {};
    if (typeof spec !== "object" || Array.isArray(spec)) {
      fail(TypeError, `variables.${name} must be an object.`, "ERR_CONSTRAINT_VARIABLE");
    }
    const domain = { min: null, max: null, candidates: null };
    if (Object.hasOwn(spec, "jdn")) {
      const value = absoluteToJdn(spec.jdn, `variables.${name}.jdn`);
      domain.min = value;
      domain.max = value;
    }
    const range = normalizeRange(spec.range, `variables.${name}.range`);
    if (range) intersectRange(domain, range.min, range.max);
    variables.set(name, domain);
  }
  if (variables.size === 0) fail(RangeError, "At least one variable is required.", "ERR_CONSTRAINT_VARIABLES");
  return variables;
}

function needVariable(variables, name, fieldName) {
  if (typeof name !== "string" || !variables.has(name)) {
    fail(RangeError, `${fieldName} must name a declared variable.`, "ERR_CONSTRAINT_VARIABLE");
  }
  return name;
}

function normalizeConstraints(problem, variables) {
  if (!Array.isArray(problem.constraints)) fail(TypeError, "problem.constraints must be an array.", "ERR_CONSTRAINTS");
  return problem.constraints.map((source, index) => {
    const at = `constraints[${index}]`;
    if (!source || typeof source !== "object") fail(TypeError, `${at} must be an object.`, "ERR_CONSTRAINT");
    switch (source.type) {
      case "pastafari": {
        const target = needVariable(variables, source.target, `${at}.target`);
        const wanted = normalizePastafariDate(source.date, `${at}.date`);
        if (source.calculation !== undefined && source.calculationJdn !== undefined) {
          fail(TypeError, `${at} must provide calculation or calculationJdn, not both.`, "ERR_CONSTRAINT_CALCULATION");
        }
        let calculation;
        if (source.calculation === SAME_AS_TARGET || source.calculation === "same-as-target") {
          calculation = { kind: "variable", name: target, diagonal: true };
        } else if (typeof source.calculation === "string" && variables.has(source.calculation)) {
          calculation = { kind: "variable", name: source.calculation, diagonal: source.calculation === target };
        } else if (source.calculationJdn !== undefined) {
          calculation = { kind: "absolute", jdn: absoluteToJdn(source.calculationJdn, `${at}.calculationJdn`) };
        } else if (source.calculation !== undefined) {
          calculation = { kind: "absolute", jdn: absoluteToJdn(source.calculation, `${at}.calculation`) };
        } else {
          fail(TypeError, `${at} requires calculation or calculationJdn.`, "ERR_CONSTRAINT_CALCULATION");
        }
        return { type: "pastafari", target, calculation, wanted, index };
      }
      case "equal":
        return { type: "equal", left: needVariable(variables, source.left, `${at}.left`), right: needVariable(variables, source.right, `${at}.right`), index };
      case "order": {
        const op = source.op;
        if (!["<", "<=", ">", ">="].includes(op)) fail(RangeError, `${at}.op is invalid.`, "ERR_CONSTRAINT_ORDER");
        return { type: "order", left: needVariable(variables, source.left, `${at}.left`), right: needVariable(variables, source.right, `${at}.right`), op, index };
      }
      case "difference": {
        const left = needVariable(variables, source.left, `${at}.left`);
        const right = needVariable(variables, source.right, `${at}.right`);
        let min;
        let max;
        if (source.equals !== undefined) {
          min = max = toBigInt(source.equals, `${at}.equals`);
        } else {
          min = source.min === undefined ? null : toBigInt(source.min, `${at}.min`);
          max = source.max === undefined ? null : toBigInt(source.max, `${at}.max`);
          if (min === null && max === null) fail(TypeError, `${at} requires equals, min or max.`, "ERR_CONSTRAINT_DIFFERENCE");
          if (min !== null && max !== null && max < min) fail(RangeError, `${at}.max is smaller than min.`, "ERR_CONSTRAINT_DIFFERENCE");
        }
        return { type: "difference", left, right, min, max, index };
      }
      default:
        fail(RangeError, `${at}.type is unsupported.`, "ERR_CONSTRAINT_TYPE");
    }
  });
}

function tarjan(variableNames, constraints) {
  const adjacency = new Map(variableNames.map((name) => [name, []]));
  for (const constraint of constraints) {
    if (constraint.type !== "pastafari" || constraint.calculation.kind !== "variable") continue;
    adjacency.get(constraint.calculation.name).push(constraint.target);
  }
  let nextIndex = 0;
  const stack = [];
  const onStack = new Set();
  const indexBy = new Map();
  const lowBy = new Map();
  const components = [];
  function visit(v) {
    indexBy.set(v, nextIndex);
    lowBy.set(v, nextIndex);
    nextIndex += 1;
    stack.push(v);
    onStack.add(v);
    for (const w of adjacency.get(v)) {
      if (!indexBy.has(w)) {
        visit(w);
        lowBy.set(v, Math.min(lowBy.get(v), lowBy.get(w)));
      } else if (onStack.has(w)) {
        lowBy.set(v, Math.min(lowBy.get(v), indexBy.get(w)));
      }
    }
    if (lowBy.get(v) === indexBy.get(v)) {
      const component = [];
      while (true) {
        const w = stack.pop();
        onStack.delete(w);
        component.push(w);
        if (w === v) break;
      }
      components.push(component);
    }
  }
  for (const name of variableNames) if (!indexBy.has(name)) visit(name);
  return { components, adjacency };
}

function isCyclicComponent(component, adjacency) {
  if (component.length > 1) return true;
  return adjacency.get(component[0]).includes(component[0]);
}

function propagateLinear(variables, constraints) {
  let any = false;
  let changed;
  do {
    incrementDiagnosticCounter("constraints.propagation.passes");
    changed = false;
    for (const c of constraints) {
      if (c.type === "equal") {
        const a = variables.get(c.left);
        const b = variables.get(c.right);
        const ab = finiteBounds(a);
        const bb = finiteBounds(b);
        if (bb) changed = intersectRange(a, bb.min, bb.max) || changed;
        if (ab) changed = intersectRange(b, ab.min, ab.max) || changed;
        if (a.candidates !== null) changed = intersectCandidates(b, a.candidates) || changed;
        if (b.candidates !== null) changed = intersectCandidates(a, b.candidates) || changed;
      } else if (c.type === "order") {
        let left = variables.get(c.left);
        let right = variables.get(c.right);
        let op = c.op;
        if (op === ">" || op === ">=") {
          [left, right] = [right, left];
          op = op === ">" ? "<" : "<=";
        }
        const lb = finiteBounds(left);
        const rb = finiteBounds(right);
        const delta = op === "<" ? 1n : 0n;
        if (rb) changed = intersectRange(left, null, rb.max - delta) || changed;
        if (lb) changed = intersectRange(right, lb.min + delta, null) || changed;
      } else if (c.type === "difference") {
        const left = variables.get(c.left);
        const right = variables.get(c.right);
        const lb = finiteBounds(left);
        const rb = finiteBounds(right);
        if (rb) {
          const min = c.min === null ? null : rb.min + c.min;
          const max = c.max === null ? null : rb.max + c.max;
          changed = intersectRange(left, min, max) || changed;
        }
        if (lb) {
          const min = c.max === null ? null : lb.min - c.max;
          const max = c.min === null ? null : lb.max - c.min;
          changed = intersectRange(right, min, max) || changed;
        }
      }
      for (const domain of variables.values()) if (domainEmpty(domain)) return { changed: any || changed, impossible: true };
    }
    any ||= changed;
  } while (changed);
  return { changed: any, impossible: false };
}

function pairKey(calculationJdn, targetJdn) {
  return `${calculationJdn}:${targetJdn}`;
}

function relationSupports(relation, variables) {
  const targetDomain = variables.get(relation.constraint.target);
  const calculation = relation.constraint.calculation;
  const calcDomain = calculation.kind === "variable" ? variables.get(calculation.name) : null;
  const targetValues = new Set();
  const calcValues = new Set();
  for (const pair of relation.pairs.values()) {
    if (!hasValue(targetDomain, pair.targetJdn)) continue;
    if (calcDomain && !hasValue(calcDomain, pair.calculationJdn)) continue;
    targetValues.add(pair.targetJdn);
    calcValues.add(pair.calculationJdn);
  }
  let changed = intersectCandidates(targetDomain, targetValues);
  if (calcDomain) changed = intersectCandidates(calcDomain, calcValues) || changed;
  return changed;
}

function rangeSize(domain) {
  return cardinality(domain);
}

function compareSize(a, b) {
  if (a === null) return b === null ? 0 : 1;
  if (b === null) return -1;
  return a < b ? -1 : a > b ? 1 : 0;
}

function checkLinearConstraint(c, assignment) {
  if (c.type === "equal") {
    if (!assignment.has(c.left) || !assignment.has(c.right)) return true;
    return assignment.get(c.left) === assignment.get(c.right);
  }
  if (c.type === "order") {
    if (!assignment.has(c.left) || !assignment.has(c.right)) return true;
    const a = assignment.get(c.left);
    const b = assignment.get(c.right);
    return c.op === "<" ? a < b : c.op === "<=" ? a <= b : c.op === ">" ? a > b : a >= b;
  }
  if (c.type === "difference") {
    if (!assignment.has(c.left) || !assignment.has(c.right)) return true;
    const difference = assignment.get(c.left) - assignment.get(c.right);
    return (c.min === null || difference >= c.min) && (c.max === null || difference <= c.max);
  }
  return true;
}

function relationAllows(constraint, relation, assignment) {
  const targetAssigned = assignment.has(constraint.target);
  const calcAssigned = constraint.calculation.kind === "absolute" || assignment.has(constraint.calculation.name);
  if (!targetAssigned && !calcAssigned) return true;
  const target = targetAssigned ? assignment.get(constraint.target) : null;
  const calc = constraint.calculation.kind === "absolute"
    ? constraint.calculation.jdn
    : calcAssigned ? assignment.get(constraint.calculation.name) : null;
  if (targetAssigned && calcAssigned) return relation.pairs.has(pairKey(calc, target));
  for (const pair of relation.pairs.values()) {
    if (targetAssigned && pair.targetJdn !== target) continue;
    if (calcAssigned && pair.calculationJdn !== calc) continue;
    return true;
  }
  return false;
}

function assignmentObject(assignment) {
  const result = {};
  for (const [name, jdn] of assignment) {
    result[name] = Object.freeze({ jdn, gregorian: jdnToGregorian(jdn) });
  }
  return Object.freeze(result);
}

export async function solvePastafariConstraintsDirect(problem, options = {}) {
  if (options === null || typeof options !== "object") fail(TypeError, "Constraint solver options must be an object.", "ERR_OPTIONS");
  if (options.onProgress !== undefined && typeof options.onProgress !== "function") fail(TypeError, "onProgress must be a function.", "ERR_REVERSE_PROGRESS");
  const yieldEvery = options.yieldEvery === undefined ? DEFAULT_YIELD_EVERY : Number(options.yieldEvery);
  if (!Number.isSafeInteger(yieldEvery) || yieldEvery < 1) fail(RangeError, "yieldEvery must be a positive safe integer.", "ERR_REVERSE_YIELD");
  const maxSolutions = options.maxSolutions === undefined ? null : Number(options.maxSolutions);
  if (maxSolutions !== null && (!Number.isSafeInteger(maxSolutions) || maxSolutions < 1)) fail(RangeError, "maxSolutions must be a positive safe integer.", "ERR_CONSTRAINT_MAX_SOLUTIONS");
  const maxScanned = options.maxScanned === undefined ? null : toBigInt(options.maxScanned, "maxScanned");
  if (maxScanned !== null && maxScanned < 1n) fail(RangeError, "maxScanned must be positive.", "ERR_CONSTRAINT_MAX_SCANNED");

  const variables = normalizeVariables(problem);
  const constraints = normalizeConstraints(problem, variables);
  const pastafariConstraints = constraints.filter((c) => c.type === "pastafari");
  const linearConstraints = constraints.filter((c) => c.type !== "pastafari");
  const { components, adjacency } = tarjan([...variables.keys()], constraints);
  const cyclicComponents = components.filter((component) => isCyclicComponent(component, adjacency));
  incrementDiagnosticCounter("constraints.solve.calls");
  incrementDiagnosticCounter("constraints.variables", variables.size);
  incrementDiagnosticCounter("constraints.constraints", constraints.length);
  incrementDiagnosticCounter("constraints.cyclic-components", cyclicComponents.length);
  diagnosticTrace("constraints", "solve-start", {
    variables: variables.size,
    constraints: constraints.length,
    pastafariConstraints: pastafariConstraints.length,
    cyclicComponents: cyclicComponents.length,
  });
  const solveToken = beginDiagnosticOperation("constraints", "solve", {
    variables: variables.size,
    constraints: constraints.length,
    pastafariConstraints: pastafariConstraints.length,
    cyclicComponents: cyclicComponents.length,
  });
  let diagnosticOutcome = "ok";

  try {
  let progressScanned = 0n;
  let reverseCalls = 0n;
  let forwardVerifications = 0n;
  let pruned = 0n;
  let stopped = false;
  let lastProgress = -1n;
  const report = (phase, complete = false, matches = 0) => {
    if (!options.onProgress) return;
    if (progressScanned < lastProgress) fail(Error, "Constraint progress regressed.", "ERR_CONSTRAINT_PROGRESS_INTERNAL");
    lastProgress = progressScanned;
    options.onProgress(Object.freeze({ scanned: progressScanned, total: null, matches, phase, complete }));
  };
  const step = async (phase) => {
    if (options.signal?.aborted) throw abortError();
    if (maxScanned !== null && progressScanned >= maxScanned) {
      stopped = true;
      return false;
    }
    progressScanned += 1n;
    incrementDiagnosticCounter("constraints.scanned");
    if (progressScanned % BigInt(yieldEvery) === 0n) {
      report(phase, false);
      await breathe();
      if (options.signal?.aborted) throw abortError();
    }
    return true;
  };

  let propagated = propagateLinear(variables, linearConstraints);
  if (propagated.impossible) {
    report("done", true, 0);
    return Object.freeze({ solutions: Object.freeze([]), complete: true, termination: "complete", scanned: progressScanned, candidates: 0n, verified: 0n, stats: Object.freeze({ reverseCalls, forwardVerifications, pruned, cyclicComponents: cyclicComponents.length, relationPairs: 0n }) });
  }

  const relations = new Map();
  for (const constraint of pastafariConstraints) {
    relations.set(constraint.index, { constraint, pairs: new Map(), scannedCalculations: new Set(), exhaustive: false });
  }

  async function materializeRelation(relation) {
    const c = relation.constraint;
    if (relation.exhaustive) return relationSupports(relation, variables);
    if (c.calculation.kind === "variable" && c.calculation.diagonal) {
      const domain = variables.get(c.target);
      const bounds = finiteBounds(domain);
      if (!bounds) return false;
      const diagonalTotal = bounds.max - bounds.min + 1n;
      if (maxScanned !== null && progressScanned + diagonalTotal > maxScanned) {
        stopped = true;
        return false;
      }
      const progressBase = progressScanned;
      const found = await findPastafariDate(c.wanted, {
        calculationDate: SAME_AS_TARGET,
        searchRange: [bounds.min, bounds.max],
        signal: options.signal,
        yieldEvery,
        onProgress: (progress) => {
          progressScanned = progressBase + BigInt(progress.scanned);
          report("reverse", false, progress.matches);
        },
      });
      progressScanned = progressBase + diagonalTotal;
      reverseCalls += 1n;
      incrementDiagnosticCounter("constraints.reverse-calls");
      for (const candidate of found) {
        if (!hasValue(domain, candidate.targetJdn)) continue;
        relation.pairs.set(pairKey(candidate.calculationJdn, candidate.targetJdn), candidate);
      }
      relation.exhaustive = true;
      return relationSupports(relation, variables);
    }

    let calcValues;
    if (c.calculation.kind === "absolute") {
      calcValues = [c.calculation.jdn];
    } else {
      calcValues = domainValues(variables.get(c.calculation.name));
      if (calcValues === null) return false;
    }

    for (const calculationJdn of calcValues) {
      const key = calculationJdn.toString();
      if (relation.scannedCalculations.has(key)) continue;
      if (!await step("reverse")) return false;
      relation.scannedCalculations.add(key);
      const found = await findPastafariDate(c.wanted, { calculationJdn, signal: options.signal });
      reverseCalls += 1n;
      incrementDiagnosticCounter("constraints.reverse-calls");
      for (const candidate of found) {
        relation.pairs.set(pairKey(candidate.calculationJdn, candidate.targetJdn), candidate);
      }
    }
    if (c.calculation.kind === "absolute") relation.exhaustive = true;
    else {
      const domain = variables.get(c.calculation.name);
      const count = cardinality(domain);
      relation.exhaustive = count !== null && BigInt(relation.scannedCalculations.size) >= count;
    }
    return relation.exhaustive ? relationSupports(relation, variables) : false;
  }

  let changed = true;
  while (changed && !stopped) {
    changed = false;
    for (const relation of relations.values()) {
      if (await materializeRelation(relation)) changed = true;
      if (stopped) break;
      for (const domain of variables.values()) {
        if (domainEmpty(domain)) {
          report("done", true, 0);
          return Object.freeze({ solutions: Object.freeze([]), complete: true, termination: "complete", scanned: progressScanned, candidates: 0n, verified: 0n, stats: Object.freeze({ reverseCalls, forwardVerifications, pruned, cyclicComponents: cyclicComponents.length, relationPairs: BigInt([...relations.values()].reduce((sum, relation) => sum + relation.pairs.size, 0)) }) });
        }
      }
    }
    if (!stopped) {
      propagated = propagateLinear(variables, linearConstraints);
      if (propagated.impossible) {
        report("done", true, 0);
        return Object.freeze({ solutions: Object.freeze([]), complete: true, termination: "complete", scanned: progressScanned, candidates: 0n, verified: 0n, stats: Object.freeze({ reverseCalls, forwardVerifications, pruned, cyclicComponents: cyclicComponents.length, relationPairs: BigInt([...relations.values()].reduce((sum, relation) => sum + relation.pairs.size, 0)) }) });
      }
      changed ||= propagated.changed;
      for (const relation of relations.values()) if (relation.exhaustive && relationSupports(relation, variables)) changed = true;
    }
  }

  if (!stopped) {
    for (const component of cyclicComponents) {
      const unresolved = [...relations.values()].some((relation) => {
        const constraint = relation.constraint;
        return !relation.exhaustive
          && constraint.calculation.kind === "variable"
          && component.includes(constraint.calculation.name)
          && component.includes(constraint.target);
      });
      if (unresolved) {
        fail(
          RangeError,
          `Cyclic constraint component [${component.join(", ")}] has no finite domain anchor.`,
          "ERR_CONSTRAINT_RANGE_REQUIRED",
          { variables: Object.freeze(component.slice()) },
        );
      }
    }
    for (const relation of relations.values()) {
      if (!relation.exhaustive) {
        const c = relation.constraint;
        const calcName = c.calculation.kind === "variable" ? c.calculation.name : null;
        fail(
          RangeError,
          `Constraint ${c.index} cannot be exhaustively materialized because ${calcName ?? "its calculation day"} has no finite domain.`,
          "ERR_CONSTRAINT_RANGE_REQUIRED",
        );
      }
    }
    for (const [name, domain] of variables) {
      if (cardinality(domain) === null) fail(RangeError, `Variable ${name} has no finite domain.`, "ERR_CONSTRAINT_RANGE_REQUIRED", { variable: name });
    }
  }

  const order = [...variables.keys()].sort((a, b) => compareSize(cardinality(variables.get(a)), cardinality(variables.get(b))));
  const valuesByVariable = new Map(order.map((name) => [name, domainValues(variables.get(name)) ?? []]));
  const solutions = [];
  const assignment = new Map();
  const calendar = new PastafariCalendar();
  let candidateAssignments = 0n;

  function partialConsistent() {
    for (const c of linearConstraints) if (!checkLinearConstraint(c, assignment)) return false;
    for (const c of pastafariConstraints) {
      const relation = relations.get(c.index);
      if (relation.exhaustive && !relationAllows(c, relation, assignment)) return false;
    }
    return true;
  }

  function verifyFullAssignment() {
    for (const c of linearConstraints) if (!checkLinearConstraint(c, assignment)) return false;
    for (const c of pastafariConstraints) {
      const targetJdn = assignment.get(c.target);
      const calculationJdn = c.calculation.kind === "absolute" ? c.calculation.jdn : assignment.get(c.calculation.name);
      const actual = calendar.convertJdn(targetJdn, { calculationJdn });
      forwardVerifications += 1n;
      incrementDiagnosticCounter("constraints.forward-verifications");
      if (!samePastafari(actual, c.wanted)) return false;
    }
    return true;
  }

  async function search(depth) {
    if (stopped) return;
    if (options.signal?.aborted) throw abortError();
    if (maxSolutions !== null && solutions.length >= maxSolutions) {
      stopped = true;
      return;
    }
    if (depth === order.length) {
      if (!await step("verify")) return;
      candidateAssignments += 1n;
      if (verifyFullAssignment()) {
        solutions.push(assignmentObject(assignment));
        report("verify", false, solutions.length);
      }
      return;
    }
    const name = order[depth];
    for (const value of valuesByVariable.get(name)) {
      assignment.set(name, value);
      if (partialConsistent()) await search(depth + 1);
      else {
        pruned += 1n;
        incrementDiagnosticCounter("constraints.pruned");
      }
      assignment.delete(name);
      if (stopped) return;
      if (progressScanned % BigInt(yieldEvery) === 0n) await breathe();
    }
  }

  if (!stopped) await search(0);
  const complete = !stopped;
  const termination = complete ? "complete" : maxSolutions !== null && solutions.length >= maxSolutions ? "max-solutions" : "max-scanned";
  incrementDiagnosticCounter(`constraints.termination.${termination}`);
  incrementDiagnosticCounter("constraints.solutions", solutions.length);
  diagnosticTrace("constraints", "solve-end", {
    termination,
    scanned: progressScanned,
    candidates: candidateAssignments,
    solutions: solutions.length,
    reverseCalls,
    forwardVerifications,
    pruned,
  });
  report("done", complete, solutions.length);
  return Object.freeze({
    solutions: Object.freeze(solutions.slice()),
    complete,
    termination,
    scanned: progressScanned,
    candidates: candidateAssignments,
    verified: BigInt(solutions.length),
    stats: Object.freeze({
      reverseCalls,
      forwardVerifications,
      pruned,
      cyclicComponents: cyclicComponents.length,
      relationPairs: BigInt([...relations.values()].reduce((sum, relation) => sum + relation.pairs.size, 0)),
    }),
  });
  } catch (error) {
    diagnosticOutcome = error?.name === "AbortError" ? "cancelled" : "error";
    recordDiagnosticError("constraints", error, solveToken?.id, { phase: "solve" });
    throw error;
  } finally {
    endDiagnosticOperation(solveToken, diagnosticOutcome);
  }
}
