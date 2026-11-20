#!/usr/bin/env node
'use strict';
/* PROJECT_ID: PC-BRANCH-WAT-SPANISH.
 * Independent mathematical k=5, q=7 oracle. Does not execute WAT.
 * Constructs candidates by base expansion and checks a separate deficit
 * polynomial, then cross-checks small rings with explicit circular walks.
 */
const assert = require('node:assert/strict');
const MODULUS = (1n << 127n) - 1n;
const Q = 7n;

function caseFor(base, direction, correction, bounded) {
  assert(base >= 15n && base % Q === 1n);
  assert(direction === 1 || direction === -1);
  assert(correction === 0 || correction === 1);
  const h = direction === 1 ? 5n : 1n;
  const digits = Array.from({length: 5}, (_, j) => base - h + BigInt(direction * j));
  assert(digits.every(d => d >= 1n && d <= base));
  // Horner evaluation is independent of the production digit-limb builder.
  const candidate = 1n + digits.reduceRight((acc, digit) => acc * base + (digit - 1n), 0n);
  const space = base ** 5n;
  const deficit = direction === 1
    ? base**4n + 2n*base**3n + 3n*base**2n + 4n*base + 5n
    : 5n*base**4n + 4n*base**3n + 3n*base**2n + 2n*base + 1n;
  assert.equal(space - candidate, deficit, 'independent polynomial identity');
  assert.equal(candidate % Q, 0n, 'exact seventh divisibility');
  const n = candidate / Q - BigInt(correction);
  assert(n > base**4n && n < space, 'exact k=5 domain');
  const quotient = space / n;
  const limit = quotient * n;
  assert(limit >= 1n && limit <= space);
  assert(space < (quotient + 1n) * n);
  let accepted = candidate;
  let rejected = 0n;
  if (candidate > limit) {
    if (direction === 1) {
      rejected = space - candidate + 1n;
      accepted = 1n;
    } else {
      rejected = candidate - limit;
      accepted = limit;
    }
  }
  const rank = (accepted - 1n) % n + 1n;
  assert(rank >= 1n && rank <= n);
  if (quotient === Q) {
    assert.equal(limit, candidate - Q * BigInt(correction));
    if (correction === 0) {
      assert.equal(accepted, candidate);
      assert.equal(rank, n);
    } else if (direction === 1) {
      assert.equal(accepted, 1n);
      assert.equal(rank, 1n);
      assert.equal(rejected, deficit + 1n);
    } else {
      assert.equal(accepted, limit);
      assert.equal(rank, n);
      assert.equal(rejected, Q);
    }
  }
  if (bounded) {
    let observed = candidate;
    let observedRejected = 0n;
    while (observed > limit) {
      observed = direction === 1 ? (observed === space ? 1n : observed + 1n) :
        (observed === 1n ? space : observed - 1n);
      observedRejected += 1n;
      assert(observedRejected <= 300000n, 'small ring walk bound');
    }
    assert.equal(observed, accepted, 'stepwise accepted candidate');
    assert.equal(observedRejected, rejected, 'stepwise rejection count');
  }
  return {modulus: base.toString(), direction, correction,
    quotient: quotient.toString(), n: n.toString(),
    rank: rank.toString(), rejected: rejected.toString(),
    accepted: accepted.toString(), first: digits[0].toString(),
    candidate: candidate.toString(), limit: limit.toString()};
}

function main() {
  let small = 0, medium = 0, rejectionSteps = 0n;
  const smallQuotients = {};
  for (const base of [15n, 22n]) {
    for (const direction of [1, -1]) for (const correction of [0, 1]) {
      const c = caseFor(base, direction, correction, true);
      rejectionSteps += BigInt(c.rejected);
      smallQuotients[base + '_' + direction + '_' + correction] = c.quotient;
      small++;
    }
  }
  assert.equal(small, 8);
  assert.equal(smallQuotients['15_-1_0'], '10');
  assert.equal(smallQuotients['22_-1_0'], '9');
  assert.equal(smallQuotients['15_1_0'], '7');
  for (const base of [43n, 50n, 57n, 64n]) {
    for (const direction of [1, -1]) for (const correction of [0, 1]) {
      const c = caseFor(base, direction, correction, false);
      assert.equal(c.quotient, '7');
      medium++;
    }
  }
  assert.equal(medium, 16);
  const production = {};
  for (const direction of [1, -1]) for (const correction of [0, 1]) {
    const c = caseFor(MODULUS, direction, correction, false);
    assert.equal(c.quotient, '7');
    production[(direction === 1 ? 'forward' : 'backward') + '_' +
      (correction ? 'rejection' : 'exact')] = c;
  }
  assert.equal(MODULUS % Q, 1n);
  return {project_id:'PC-BRANCH-WAT-SPANISH', mode:'independent_math_only_NOT_NATIVE',
    k:5, requested_quotient:7, small_explicit_walks:small,
    small_rejection_steps:rejectionSteps.toString(), medium_exact_q7:medium,
    production_exact_q7:4, production, failed:0};
}
if (require.main === module) console.log(JSON.stringify(main()));
module.exports = {main, caseFor};
