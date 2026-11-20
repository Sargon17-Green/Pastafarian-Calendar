#!/usr/bin/env node
'use strict';
/* PROJECT_ID: PC-BRANCH-WAT-SPANISH
 * Stage02 DISCOVERY01 k=5/q=8 independent math-only oracle.
 * Does not import the WAT fixture, Native runner, or any prior q oracle.
 */
const assert = require('node:assert/strict');

const Q = 8n;
const PRODUCTION_BASE = (1n << 127n) - 1n;

function streamWitness(base, direction, delta, requireK5 = true) {
  assert.equal(base % Q, 7n, 'base must be congruent to 7 modulo 8');
  assert(base >= 15n, 'five valid adjacent digits required');
  assert(direction === 1 || direction === -1);
  assert(delta === 0 || delta === 1);
  const offset = direction === 1 ? 9n : 5n;
  let x = 1n;
  let radix = 1n;
  let first;
  for (let j = 0; j !== 5; j++) {
    const digit = base - offset + BigInt(direction * j);
    assert(digit >= 1n && digit <= base, 'response outside circular alphabet');
    if (j === 0) first = digit;
    x += (digit - 1n) * radix;
    radix *= base;
  }
  const space = radix;
  // Separate, closed-form polynomial: no reuse of the radix construction.
  const deficit = direction === 1
    ? 5n*base**4n + 6n*base**3n + 7n*base**2n + 8n*base + 9n
    : 9n*base**4n + 8n*base**3n + 7n*base**2n + 6n*base + 5n;
  assert.equal(x + deficit, space, 'independent deficit identity');
  assert.equal(x % Q, 0n, 'eight-way exact divisibility');
  const n = x / Q - BigInt(delta);
  assert(n > 0n && n < space, 'valid selection domain');
  if (requireK5) assert(n > base**4n, 'k=5 selection domain');
  const quotient = space / n;
  const limit = quotient * n;
  assert(limit <= space && space < (quotient + 1n) * n, 'quotient inequality');
  const rejected = x > limit ? (direction === 1 ? space - x + 1n : x - limit) : 0n;
  const accepted = x <= limit ? x : direction === 1 ? 1n : limit;
  const rank = (accepted - 1n) % n + 1n;
  assert(rank >= 1n && rank <= n);
  if (quotient === Q) {
    assert.equal(limit, x - Q * BigInt(delta));
    if (delta === 0) assert.equal(rank, n);
    else if (direction === 1) {
      assert.equal(rejected, deficit + 1n);
      assert.equal(accepted, 1n);
      assert.equal(rank, 1n);
    } else {
      assert.equal(rejected, Q);
      assert.equal(accepted, limit);
      assert.equal(rank, n);
    }
  }
  return {base:base.toString(),direction,delta,first:first.toString(),
    k5_domain: n > base**4n,q:quotient.toString(),n:n.toString(),space:space.toString(),
    candidate:x.toString(),limit:limit.toString(),accepted:accepted.toString(),
    rank:rank.toString(),rejections:rejected.toString()};
}

// Independent bounded oracle. Its starting candidate is chosen near S,
// without using contiguous-digit construction or the polynomial above.
function explicitRingWalk(base, direction, delta) {
  const space = base ** 5n;
  const initial = space - (space % Q);
  const n = initial / Q - BigInt(delta);
  assert(n > base**4n && n < space);
  const q = space / n;
  assert.equal(q, Q);
  const limit = q * n;
  let current = initial;
  let steps = 0;
  while (current > limit) {
    current = direction === 1 ? (current === space ? 1n : current + 1n)
      : (current === 1n ? space : current - 1n);
    steps++;
    assert(steps <= 100, 'bounded oracle must not run indefinitely');
  }
  const predictedSteps = delta === 0 ? 0 : direction === 1
    ? Number(space - initial + 1n) : 8;
  const predictedAccepted = delta === 0 ? initial : direction === 1 ? 1n : limit;
  assert.equal(steps, predictedSteps, 'explicit walk vs independent closed-form');
  assert.equal(current, predictedAccepted);
  assert.equal((current - 1n) % n + 1n, direction === 1 && delta === 1 ? 1n : n);
  return steps;
}

function main() {
  let bounded = 0, boundedSteps = 0, medium = 0;
  const observedSmallQ = {};
  for (const b of [15n, 23n, 31n, 39n]) {
    for (const direction of [1, -1]) for (const delta of [0, 1]) {
      boundedSteps += explicitRingWalk(b, direction, delta);
      bounded++;
    }
  }
  assert.equal(bounded, 16);
  assert.equal(boundedSteps, 64);

  // Small stream cases are a structural check only: q is not assumed to be 8.
  let smallStream = 0;
  for (const b of [15n, 23n]) {
    for (const direction of [1, -1]) for (const delta of [0, 1]) {
      const c = streamWitness(b, direction, delta, false);
      observedSmallQ[String(b)+'_'+direction+'_'+delta] = c.q;
      smallStream++;
    }
  }
  assert.equal(smallStream, 8);
  assert.equal(observedSmallQ['15_1_0'], '12');
  assert.equal(observedSmallQ['15_-1_0'], '22');
  assert.equal(observedSmallQ['23_1_0'], '10');
  assert.equal(observedSmallQ['23_-1_0'], '13');

  for (const b of [87n, 95n, 103n, 111n]) {
    for (const direction of [1, -1]) for (const delta of [0, 1]) {
      const c = streamWitness(b, direction, delta);
      assert.equal(c.q, '8', 'medium witness must be exact q=8');
      medium++;
    }
  }
  assert.equal(medium, 16);
  const production = {};
  for (const direction of [1, -1]) for (const delta of [0, 1]) {
    const c = streamWitness(PRODUCTION_BASE, direction, delta);
    assert.equal(c.q, '8');
    production[(direction === 1 ? 'forward' : 'backward')+'_'+(delta ? 'rejection' : 'exact')] = c;
  }
  assert.equal(Object.keys(production).length, 4);
  return {project_id:'PC-BRANCH-WAT-SPANISH',mode:'independent_math_only_NOT_NATIVE',
    k:5,requested_quotient:8,bounded_ring_walks:bounded,
    bounded_rejection_steps:boundedSteps,small_structural_streams:smallStream,
    small_actual_quotients:observedSmallQ,medium_exact_q8:medium,
    production_exact_q8:4,production,failed:0};
}
if (require.main === module) console.log(JSON.stringify(main()));
module.exports = {main,streamWitness,explicitRingWalk};
