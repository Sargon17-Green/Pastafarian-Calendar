#!/usr/bin/env node
'use strict';
/* PROJECT_ID: PC-BRANCH-WAT-SPANISH
 * Stage02 DISCOVERY01 k=5/q=9: new independent mathematics-only oracle.
 * No WAT import, Native execution, fixture replay or use of other branches.
 */
const assert = require('node:assert/strict');

const Q = 9n;
const M = (1n << 127n) - 1n;

// Construct a five-answer path in little-endian base-B representation.
// The two start offsets were independently derived from B = 1 (mod 9).
function deriveStream(base, direction, delta, exactQ) {
  assert.equal(base % Q, 1n, 'base congruence must match production');
  assert(direction === 1 || direction === -1);
  assert(delta === 0 || delta === 1);
  const offset = direction === 1 ? 13n : 9n;
  assert(base >= offset + (direction === -1 ? 4n : 0n) + 1n);

  const digits = [];
  let posValue = 1n, place = 1n;
  for (let j = 0; j < 5; ++j) {
    const answer = base - offset + BigInt(j * direction);
    assert(answer >= 1n && answer <= base);
    digits.push(answer);
    posValue += (answer - 1n) * place;
    place *= base;
  }
  const space = place;

  // Closed algebraic oracle, different from the positional digit loop:
  // D = offset*(1+B+B^2+B^3+B^4) - direction*(B+2B^2+3B^3+4B^4).
  const B2 = base * base, B3 = B2 * base, B4 = B3 * base;
  const geom = 1n + base + B2 + B3 + B4;
  const weighted = base + 2n * B2 + 3n * B3 + 4n * B4;
  const deficit = offset * geom - BigInt(direction) * weighted;
  const algebraicX = space - deficit;
  assert.equal(posValue, algebraicX, 'positional vs closed-form oracle');
  assert.equal(posValue % Q, 0n, 'candidate must be exactly divisible by nine');

  const n = algebraicX / Q - BigInt(delta);
  assert(n > 0n && n < space);
  assert(n > B4, 'minimal k must be five');
  const actualQ = space / n;
  const limit = actualQ * n;
  assert(limit <= space && space < (actualQ + 1n) * n);
  if (exactQ) {
    assert.equal(actualQ, Q, 'exact 9 quotient required');
    assert.equal(limit, algebraicX - Q * BigInt(delta));
  }

  let expectedRank = null, expectedAccepted = null, rejected = null;
  if (actualQ === Q) {
    expectedAccepted = delta === 0 ? algebraicX : direction === 1 ? 1n : limit;
    expectedRank = (expectedAccepted - 1n) % n + 1n;
    rejected = delta === 0 ? 0n : direction === 1 ? deficit + 1n : Q;
    assert.equal(expectedRank, direction === 1 && delta === 1 ? 1n : n);
  }
  return {base:base.toString(),direction,delta,first:digits[0].toString(),
    candidate:algebraicX.toString(),deficit:deficit.toString(),space:space.toString(),
    n:n.toString(),quotient:actualQ.toString(),limit:limit.toString(),
    accepted:expectedAccepted?.toString() ?? null,rank:expectedRank?.toString() ?? null,
    rejections:rejected?.toString() ?? null};
}

// An entirely separate literal bounded ring traversal from a chosen near-S
// integer. It doesn't read deriveStream and uses no digit-based construction.
function boundedWalk(base, direction, delta) {
  const space = base ** 5n;
  const initial = space - space % Q;
  const n = initial / Q - BigInt(delta);
  assert(n > base ** 4n);
  assert.equal(space / n, Q);
  const limit = Q * n;
  let x = initial, stepCount = 0;
  while (x > limit) {
    x = direction === 1 ? (x === space ? 1n : x + 1n)
      : (x === 1n ? space : x - 1n);
    ++stepCount;
    assert(stepCount <= 32, 'bounded ring step limit exceeded');
  }
  assert.equal(stepCount, delta === 0 ? 0 : direction === 1 ? 2 : 9);
  assert.equal(x, delta === 0 ? initial : direction === 1 ? 1n : limit);
  assert.equal((x - 1n) % n + 1n, direction === 1 && delta === 1 ? 1n : n);
  return stepCount;
}

function main() {
  let bounded = 0, transitions = 0, small = 0, medium = 0;
  const smallQuotients = {};
  for (const B of [19n, 28n, 37n, 46n]) {
    for (const direction of [1, -1]) for (const delta of [0, 1]) {
      transitions += boundedWalk(B, direction, delta);
      ++bounded;
    }
  }
  assert.equal(bounded, 16);
  assert.equal(transitions, 44);

  for (const B of [28n, 37n]) {
    for (const direction of [1, -1]) for (const delta of [0, 1]) {
      const c = deriveStream(B, direction, delta, false);
      smallQuotients[String(B)+'_'+direction+'_'+delta] = c.quotient;
      ++small;
    }
  }
  assert.equal(small, 8);

  for (const B of [145n, 154n, 163n, 172n]) {
    for (const direction of [1, -1]) for (const delta of [0, 1]) {
      deriveStream(B, direction, delta, true);
      ++medium;
    }
  }
  assert.equal(medium, 16);

  const production = {};
  for (const direction of [1, -1]) for (const delta of [0, 1]) {
    const key = (direction === 1 ? 'forward' : 'backward')+'_'+(delta === 0 ? 'exact' : 'rejection');
    production[key] = deriveStream(M, direction, delta, true);
  }
  assert.equal(Object.keys(production).length, 4);
  return {project_id:'PC-BRANCH-WAT-SPANISH',mode:'independent_math_only_NOT_NATIVE',
    k:5,requested_quotient:9,base_modulo_9:M%Q===1n,
    bounded_ring_walks:bounded,bounded_rejection_transitions:transitions,
    small_structural_cases:small,small_quotients:smallQuotients,
    medium_exact_q9:medium,production_exact_q9:4,production,failed:0};
}

if (require.main === module) console.log(JSON.stringify(main()));
module.exports = {main,deriveStream,boundedWalk};
