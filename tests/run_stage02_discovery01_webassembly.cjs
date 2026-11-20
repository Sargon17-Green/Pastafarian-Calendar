#!/usr/bin/env node
'use strict';
// Stage02 DISCOVERY01 native WebAssembly runner and independent BigInt oracle.
// Requires Node.js >=18 and WABT wat2wasm on PATH; does not modify sources.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const TARGETS = new Map([
  ['test_discovery01_k3_backward_q2_n_minus_one', {q: 2n, delta: -1n}],
  ['test_discovery01_k3_backward_q2_n_plus_one', {q: 2n, delta: 1n}],
  ['test_discovery01_k3_backward_q3_n_minus_one', {q: 3n, delta: -1n}],
  ['test_discovery01_k3_backward_q3_exact_limit', {q: 3n, delta: 0n}],
  ['test_discovery01_k3_backward_q3_n_plus_one', {q: 3n, delta: 1n}]
]);
const SHORT_TARGETS = new Map([
  ['test_discovery01_short_q2_m_backward_limit', {q: 2n, step: -1, first: 'm'}],
  ['test_discovery01_short_q2_m_forward_wrap', {q: 2n, step: 1, first: 'm'}],
  ['test_discovery01_short_q1_above_half_forward_wrap', {q: 1n, step: 1, first: 'm'}],
  ['test_discovery01_short_q1_above_half_at_limit', {q: 1n, step: -1, first: 'n'}]
]);
const SHORT_Q23_TARGETS = new Map([
  ['test_discovery01_short_q23_m_forward_q3', {q:3n, place:'m', step:1}],
  ['test_discovery01_short_q23_m_backward_q3', {q:3n, place:'m', step:-1}],
  ['test_discovery01_short_q23_limit_forward_q3', {q:3n, place:'limit', step:1}],
  ['test_discovery01_short_q23_m_forward_q2', {q:2n, place:'m', step:1}],
  ['test_discovery01_short_q23_limit_plus_one_backward_q2', {q:2n, place:'limit_plus_one', step:-1}],
  ['test_discovery01_short_q23_limit_backward_q2', {q:2n, place:'limit', step:-1}]
]);
const SHORT_Q2_LIVENESS_TARGETS = new Map([
  ['test_discovery01_short_q2_m_backward_jump', {first: 'm'}],
  ['test_discovery01_short_q2_m_minus_one_backward_jump', {first: 'm_minus_one'}]
]);
const SHORT_Q123_DIFFERENTIAL_TARGETS = new Map([
  ['test_discovery01_short_diff_q1_m_backward', {q:1n, place:'m', step:-1}],
  ['test_discovery01_short_diff_q1_n_forward', {q:1n, place:'n', step:1}],
  ['test_discovery01_short_diff_q2_limit_plus_one_forward', {q:2n, place:'limit_plus_one', step:1}],
  ['test_discovery01_short_diff_q2_n_plus_one_backward', {q:2n, place:'n_plus_one', step:-1}],
  ['test_discovery01_short_diff_q3_m_backward', {q:3n, place:'m', step:-1}],
  ['test_discovery01_short_diff_q3_m_forward', {q:3n, place:'m', step:1}]
]);
const SHORT_Q45_TARGETS = new Map([
  ['test_discovery01_short_diff_q4_limit_backward', {q:4n, place:'limit', step:-1}],
  ['test_discovery01_short_diff_q4_limit_plus_one_backward', {q:4n, place:'limit_plus_one', step:-1}],
  ['test_discovery01_short_diff_q4_limit_plus_one_forward', {q:4n, place:'limit_plus_one', step:1}],
  ['test_discovery01_short_diff_q4_m_backward', {q:4n, place:'m', step:-1}],
  ['test_discovery01_short_diff_q4_m_forward', {q:4n, place:'m', step:1}],
  ['test_discovery01_short_diff_q5_limit_backward', {q:5n, place:'limit', step:-1}],
  ['test_discovery01_short_diff_q5_limit_plus_one_backward', {q:5n, place:'limit_plus_one', step:-1}],
  ['test_discovery01_short_diff_q5_limit_plus_one_forward', {q:5n, place:'limit_plus_one', step:1}],
  ['test_discovery01_short_diff_q5_m_backward', {q:5n, place:'m', step:-1}],
  ['test_discovery01_short_diff_q5_m_forward', {q:5n, place:'m', step:1}]
]);
const SHORT_SMALL_N_TARGETS = new Map([
  ['test_discovery01_short_small_n1_m_backward', {n:1n, step:-1}],
  ['test_discovery01_short_small_n1_m_forward', {n:1n, step:1}],
  ['test_discovery01_short_small_n2_m_backward', {n:2n, step:-1}],
  ['test_discovery01_short_small_n2_m_forward', {n:2n, step:1}],
  ['test_discovery01_short_small_n4_m_backward', {n:4n, step:-1}],
  ['test_discovery01_short_small_n4_m_forward', {n:4n, step:1}],
  ['test_discovery01_short_small_n11_m_backward', {n:11n, step:-1}],
  ['test_discovery01_short_small_n11_m_forward', {n:11n, step:1}]
]);
const FORWARD_TARGETS = new Map([
  ['test_discovery01_k3_forward_q2_n_minus_one', {q: 2n, delta: -1n}],
  ['test_discovery01_k3_forward_q2_exact_limit', {q: 2n, delta: 0n}],
  ['test_discovery01_k3_forward_q2_n_plus_one', {q: 2n, delta: 1n}],
  ['test_discovery01_k3_forward_q3_n_minus_one', {q: 3n, delta: -1n}],
  ['test_discovery01_k3_forward_q3_floor_boundary', {q: 3n, delta: 0n}],
  ['test_discovery01_k3_forward_q3_n_plus_one', {q: 3n, delta: 1n}]
]);

const K4_Q1_TARGETS = new Map([
  ['test_discovery01_k4_q1_backward_exact_limit', {first:'two', step:-1, offset:0n}],
  ['test_discovery01_k4_q1_backward_two_rejections', {first:'two', step:-1, offset:2n}],
  ['test_discovery01_k4_q1_forward_exact_limit', {first:'m_minus_three', step:1, offset:0n}],
  ['test_discovery01_k4_q1_forward_astronomical_skip', {first:'m_minus_three', step:1, offset:1n}]
]);
const K5_Q2_TARGETS = new Map([
  ['test_discovery01_k5_q2_forward_exact_limit',{step:1,offset:0n}],
  ['test_discovery01_k5_q2_forward_skip',{step:1,offset:1n}],
  ['test_discovery01_k5_q2_backward_exact_limit',{step:-1,offset:0n}],
  ['test_discovery01_k5_q2_backward_two_rejections',{step:-1,offset:1n}]
]);
const K5_Q3_TARGETS = new Map([
  ['test_discovery01_k5_q3_forward_exact_limit',{step:1,offset:0n}],
  ['test_discovery01_k5_q3_forward_wrap',{step:1,offset:1n}],
  ['test_discovery01_k5_q3_backward_exact_limit',{step:-1,offset:0n}],
  ['test_discovery01_k5_q3_backward_three_rejections',{step:-1,offset:1n}]
]);
const K5_Q4_TARGETS = new Map([
  ['test_discovery01_k5_q4_forward_exact_limit',{step:1,offset:0n}],
  ['test_discovery01_k5_q4_forward_wrap',{step:1,offset:1n}],
  ['test_discovery01_k5_q4_backward_exact_limit',{step:-1,offset:0n}],
  ['test_discovery01_k5_q4_backward_four_rejections',{step:-1,offset:1n}]
]);
const K5_Q5_TARGETS = new Map([
  ['test_discovery01_k5_q5_forward_exact_limit',{step:1,offset:0n}],
  ['test_discovery01_k5_q5_forward_wrap',{step:1,offset:1n}],
  ['test_discovery01_k5_q5_backward_exact_limit',{step:-1,offset:0n}],
  ['test_discovery01_k5_q5_backward_five_rejections',{step:-1,offset:1n}]
]);
const SOURCE = path.join(__dirname, 'normative_selector.wat');
const PTR = {M: 65536, FIRST: 74368, CUR: 78784, N: 83200, LIMIT: 96448, SPACE: 100864, WIDE: 105280, RESULT: 145024};
const M = (1n << 127n) - 1n;
const MAX_LIMBS = 1100;
function bigintFromWasm(memory, offset) {
  const view = new DataView(memory.buffer);
  const len = view.getUint32(offset, true);
  assert.ok(len <= MAX_LIMBS, 'invalid limb count');
  let number = 0n;
  for (let i = len - 1; i >= 0; --i) {
    const limb = view.getUint32(offset + 4 + 4 * i, true);
    assert.ok(limb < 2 ** 30, 'invalid base-2^30 limb');
    number = (number << 30n) + BigInt(limb);
  }
  return number.toString();
}
function child(file, name) {
  const bytes = fs.readFileSync(file);
  const module = new WebAssembly.Module(bytes);
  const instance = new WebAssembly.Instance(module, {});
  assert.equal(typeof instance.exports[name], 'function', 'missing export');
  const value = instance.exports[name]();
  const record = {name, value};
  if (TARGETS.has(name) || FORWARD_TARGETS.has(name) || SHORT_TARGETS.has(name) || SHORT_Q23_TARGETS.has(name) || SHORT_Q2_LIVENESS_TARGETS.has(name) || SHORT_Q123_DIFFERENTIAL_TARGETS.has(name) || SHORT_Q45_TARGETS.has(name) || SHORT_SMALL_N_TARGETS.has(name) || K4_Q1_TARGETS.has(name) || K5_Q2_TARGETS.has(name) || K5_Q3_TARGETS.has(name) || K5_Q4_TARGETS.has(name) || K5_Q5_TARGETS.has(name)) {
    const mem = instance.exports.memory;
    assert.ok(mem instanceof WebAssembly.Memory, 'missing memory export');
    record.numerics = {};
    for (const [key, offset] of Object.entries(PTR)) {
      record.numerics[key] = bigintFromWasm(mem, offset);
    }
  }
  process.stdout.write(JSON.stringify(record) + '\n');
}
function checkNumerics(name, values) {
  assert.ok(TARGETS.has(name), 'unexpected numeric target');
  const {q: expectedQ, delta} = TARGETS.get(name);
  // Independiente del módulo: el flujo de respuestas desde 1 con paso -1
  // produce los dígitos [0, M-1, M-2] en base M.
  const x = 1n + (M - 1n) * M + (M - 2n) * M * M;
  const t = ((M - 1n) / expectedQ) * (M * M - 1n);
  const n = t + delta;
  const space = M ** 3n;
  const q = space / n;
  const limit = q * n;
  const chosen = x <= limit ? x : limit; // step=-1: primera aceptación
  const rank = ((chosen - 1n) % n) + 1n;
  const expectedRank = delta === -1n ? t - 1n : delta === 0n ? t : t + 1n - expectedQ;
  assert.equal((M - 1n) % expectedQ, 0n);
  assert.ok(n > M * M && n < space, 'not a k=3 input');
  assert.equal(q, expectedQ);
  assert.equal(x, expectedQ * t);
  assert.equal(x - limit, -expectedQ * delta);
  assert.equal(rank, expectedRank);
  for (const [key, value] of Object.entries({
    M, N: n, SPACE: space, LIMIT: limit, WIDE: chosen, RESULT: rank
  })) {
    assert.equal(BigInt(values[key]), value, name + ': ' + key);
  }
  return {
    name, delta: Number(delta), q: expectedQ.toString(), n: n.toString(),
    initial_x: x.toString(), wide: chosen.toString(),
    limit: limit.toString(), rank: rank.toString(),
    acceptance: x > limit ? 'backward_rejection_to_limit' :
      x === limit ? 'exact_limit' : 'below_limit'
  };
}
function checkForwardNumerics(name, values) {
  assert.ok(FORWARD_TARGETS.has(name), 'unexpected forward numeric target');
  const {q, delta} = FORWARD_TARGETS.get(name);
  const space = M ** 3n;
  const x = space - M - 2n;  // first=M-2, step=+1; exact stream closed form
  const n = x / q + delta;
  const actualQ = space / n;
  const limit = actualQ * n;
  const chosen = x > limit ? 1n : x; // forward rejection wraps to 1
  const rank = 1n + ((chosen - 1n) % n);
  assert.equal((M - 1n) % q, 0n);
  assert.equal(x % q, q === 2n ? 0n : 1n);
  assert.ok(n > M * M && n < space, 'forward input not in k=3');
  assert.equal(actualQ, q);
  assert.equal(x - limit, q === 2n ? -2n * delta : 1n - 3n * delta);
  const expectedRank = delta === 1n ? n - 2n :
    (q === 2n && delta === 0n ? n : 1n);
  assert.equal(rank, expectedRank);
  for (const [key, value] of Object.entries({
    M, N: n, SPACE: space, LIMIT: limit, WIDE: chosen, RESULT: rank
  })) {
    assert.equal(BigInt(values[key]), value, name + ': ' + key);
  }
  return {
    name, q: q.toString(), delta: Number(delta), first: (M - 2n).toString(),
    n: n.toString(), initial_x: x.toString(), limit: limit.toString(),
    wide: chosen.toString(), rank: rank.toString(),
    rejection_steps: x > limit ? (space - x + 1n).toString() : '0'
  };
}
function checkShortNumerics(name, values) {
  assert.ok(SHORT_TARGETS.has(name), 'unexpected short target');
  const {q: expectedQ, first: source, step} = SHORT_TARGETS.get(name);
  const n = expectedQ === 2n ? (M - 1n) / 2n : (M + 1n) / 2n;
  const first = source === 'n' ? n : M;
  const q = M / n, limit = q * n;
  const accepted = first <= limit ? first : (step === 1 ? 1n : limit);
  const rank = ((accepted - 1n) % n) + 1n;
  assert.equal(q, expectedQ);
  assert.equal(M - limit, q === 2n ? 1n : n - 1n);
  assert.equal(rank, source === 'n' || step === -1 ? n : 1n);
  for (const [key, value] of Object.entries({M, N: n, LIMIT: limit, RESULT: rank})) {
    assert.equal(BigInt(values[key]), value, name + ': ' + key);
  }
  return {name, q: q.toString(), n: n.toString(), first: first.toString(),
    step, limit: limit.toString(), rank: rank.toString()};
}
function checkShortQ23(name,values) {
  const {q:expectQ, place, step}=SHORT_Q23_TARGETS.get(name);
  const n=(M-1n)/3n+(expectQ===2n?1n:0n),q=M/n,limit=q*n;
  const first=place==='m'?M:place==='limit'?limit:limit+1n;
  const accepted=first<=limit?first:(step===1?1n:limit);
  const rank=(accepted-1n)%n+1n;
  const count=first<=limit?0n:(step===1?M-first+1n:first-limit);
  assert.equal(q,expectQ);assert.ok(count<=1n);
  assert.equal(rank,(step===1 && place==='m')?1n:n);
  for(const [key,value] of Object.entries({M,N:n,FIRST:first,LIMIT:limit,RESULT:rank}))
    assert.equal(BigInt(values[key]),value,name+' '+key);
  return {q:String(q),n:String(n),first:String(first),limit:String(limit),
    rank:String(rank),step,rejections:String(count)};
}
function checkShortQ2Liveness(name, values) {
  const {first: source} = SHORT_Q2_LIVENESS_TARGETS.get(name);
  const n = (M + 2n) / 3n;
  const limit = 2n * n;
  const first = source === 'm' ? M : M - 1n;
  const rejectedSteps = first - limit;
  assert.equal(M / n, 2n, 'q must be 2');
  assert.ok(rejectedSteps > 1000000n, 'the probe must require an astronomical legacy loop');
  const rank = ((limit - 1n) % n) + 1n;
  assert.equal(rank, n, 'algebraic rank');
  for (const [key, value] of Object.entries({M, N:n, FIRST:first, CUR:limit, LIMIT:limit, RESULT:rank})) {
    assert.equal(BigInt(values[key]), value, name + ': ' + key);
  }
  return {name, q: '2', first: first.toString(), n: n.toString(),
    limit: limit.toString(), rejections_avoided: rejectedSteps.toString(),
    accepted: limit.toString(), rank: rank.toString()};
}
function checkShortQ123Differential(name, values) {
  const {q, place, step} = SHORT_Q123_DIFFERENTIAL_TARGETS.get(name);
  const n = q === 1n ? (M + 1n) / 2n : q === 2n ? (M + 2n) / 3n : (M + 1n) / 4n;
  const limit = (M / n) * n;
  const first = place === 'm' ? M : place === 'n' ? n :
    place === 'n_plus_one' ? n + 1n : limit + 1n;
  assert.equal(M / n, q, name + ': wrong quotient');
  assert.ok(first >= 1n && first <= M, name + ': first outside ring');
  // Symbolic ring walk, with step-by-step independent Python checks on small rings.
  const rejections = first <= limit ? 0n :
    (step === 1 ? M - first + 1n : first - limit);
  const accepted = first <= limit ? first : (step === 1 ? 1n : limit);
  const rank = ((accepted - 1n) % n) + 1n;
  for (const [key, expected] of Object.entries({
    M, N:n, FIRST:first, CUR:accepted, LIMIT:limit, RESULT:rank
  })) assert.equal(BigInt(values[key]), expected, name + ': ' + key);
  return {name, q:String(q), step, n:String(n), first:String(first),
    limit:String(limit), accepted:String(accepted), rank:String(rank),
    mathematical_rejections:String(rejections)};
}
function checkShortQ45(name, values) {
  const {q: expectedQ, place, step} = SHORT_Q45_TARGETS.get(name);
  const n = M / (expectedQ + 1n) + 1n;
  const q = M / n;
  assert.equal(q, expectedQ, name + ': wrong quotient');
  const limit = q * n;
  assert.ok(limit < M && n > 1n, name + ': invalid rejection tail');
  const first = place === 'limit' ? limit :
    place === 'limit_plus_one' ? limit + 1n : M;
  assert.ok(first >= 1n && first <= M, name + ': first out of range');
  // Independent BigInt ring arithmetic; never use WASM output for expectations.
  const rejections = first <= limit ? 0n :
    step === 1 ? M - first + 1n : first - limit;
  const accepted = first <= limit ? first : step === 1 ? 1n : limit;
  const rank = ((accepted - 1n) % n) + 1n;
  assert.ok(rejections >= 0n && rejections <= M);
  assert.ok(rank >= 1n && rank <= n);
  for (const [key, expected] of Object.entries({
    M, N: n, FIRST: first, CUR: accepted, LIMIT: limit, RESULT: rank
  })) assert.equal(BigInt(values[key]), expected, name + ': ' + key);
  return {name, q:String(q), n:String(n), first:String(first), step,
    limit:String(limit), accepted:String(accepted),
    rank:String(rank), mathematical_rejections:String(rejections)};
}
function checkShortSmallN(name, values) {
  const {n, step} = SHORT_SMALL_N_TARGETS.get(name);
  const expectedRemainder = new Map([[1n,0n],[2n,1n],[4n,3n],[11n,6n]]).get(n);
  assert.equal(M % n, expectedRemainder, name + ': wrong large-quotient boundary');
  const first = M, limit = (M / n) * n;
  const rejected = first <= limit ? 0n : step === 1 ? 1n : first - limit;
  const accepted = first <= limit ? first : step === 1 ? 1n : limit;
  const rank = 1n + (accepted - 1n) % n;
  assert.equal(rejected, n === 1n ? 0n : step === 1 ? 1n : expectedRemainder);
  assert.ok(rank >= 1n && rank <= n);
  for (const [key, expected] of Object.entries({
    M, N:n, FIRST:first, CUR:accepted, LIMIT:limit, RESULT:rank
  })) assert.equal(BigInt(values[key]), expected, name + ': ' + key);
  return {name, n:String(n), q:String(M / n), step, first:String(first),
    limit:String(limit), accepted:String(accepted), rank:String(rank),
    mathematical_rejections:String(rejected)};
}

function checkK4Q1(name, values) {
  assert.ok(K4_Q1_TARGETS.has(name), 'unexpected k4 q1 case');
  const {first:source, step, offset} = K4_Q1_TARGETS.get(name);
  const space = M ** 4n, first = source === 'two' ? 2n : M - 3n;
  let digit = first, power = 1n, x = 1n;
  for (let j = 0; j < 4; j++) {
    x += (digit - 1n) * power;
    digit = (digit - 1n + BigInt(step) + M) % M + 1n;
    power *= M;
  }
  // Closed forms independently cross-check the streamed-digit reconstruction.
  const closedX = source === 'two' ?
    M ** 4n - M ** 3n - M ** 2n + 2n :
    M ** 4n - M ** 2n - 2n * M - 3n;
  assert.equal(x, closedX, name + ': digit stream');
  const n = x - offset, q = space / n, limit = q * n;
  assert.ok(n > M ** 3n && n < space, name + ': not k=4');
  assert.equal(q, 1n, name + ': quotient not 1');
  assert.equal(limit, n, name + ': limit not N');
  const rejected = x > limit;
  const accepted = rejected ? (step === 1 ? 1n : limit) : x;
  const rank = (accepted - 1n) % n + 1n;
  const rejectionCount = rejected ? (step === 1 ? space - x + 1n : x - limit) : 0n;
  assert.equal(rejectionCount, offset === 0n ? 0n :
    step === 1 ? M ** 2n + 2n * M + 4n : offset);
  for (const [key, expected] of Object.entries({
    M, FIRST:first, CUR:digit, N:n, SPACE:space, LIMIT:limit,
    WIDE:accepted, RESULT:rank
  })) assert.equal(BigInt(values[key]), expected, name + ': ' + key);
  return {name, k:4, q:'1', first:String(first), step, n:String(n),
    initial_x:String(x), limit:String(limit), accepted:String(accepted),
    rank:String(rank), mathematical_rejections:String(rejectionCount)};
}

function checkK5Q2(name, values) {
  const {step,offset}=K5_Q2_TARGETS.get(name);
  const space=M**5n,first=step===1?M-5n:M-1n;
  let x=1n,digit=first,weight=1n;
  for(let j=0;j<5;j++) {
    x+=(digit-1n)*weight;
    digit=1n+(digit-1n+BigInt(step)+M)%M;
    weight*=M;
  }
  const polynomial=step===1?
    space-(M**4n+2n*M**3n+3n*M**2n+4n*M+5n):
    space-(5n*M**4n+4n*M**3n+3n*M**2n+2n*M+1n);
  assert.equal(x,polynomial,name+': BigInt algebraic x');
  assert.equal(x%2n,0n);
  const n=x/2n-offset,q=space/n,limit=q*n;
  assert.ok(n>M**4n&&n<space,name+': not k5');
  assert.equal(q,2n,name+': not q2');
  assert.equal(limit,x-2n*offset);
  const accepted=offset===0n?x:step===1?1n:limit;
  const rank=1n+(accepted-1n)%n;
  assert.equal(rank,step===1&&offset?1n:n);
  assert.equal(digit,step===1?M:M-6n);
  for(const [key,v] of Object.entries({M,FIRST:first,CUR:digit,N:n,SPACE:space,
    LIMIT:limit,WIDE:accepted,RESULT:rank}))
    assert.equal(BigInt(values[key]),v,name+': '+key);
  const reject=!offset?0n:step===1?space-x+1n:2n;
  return {name,k:5,q:'2',first:String(first),step,n:String(n),
    initial_x:String(x),limit:String(limit),accepted:String(accepted),
    rank:String(rank),mathematical_rejections:String(reject)};
}

function checkK5Q3(name, values) {
  const {step,offset}=K5_Q3_TARGETS.get(name);
  const space=M**5n,first=step===1?M-4n:M-3n;
  let x=1n,digit=first,weight=1n;
  for(let j=0;j<5;j++) {
    x+=(digit-1n)*weight;
    digit=1n+(digit-1n+BigInt(step)+M)%M;
    weight*=M;
  }
  const polynomial=step===1?
    space-(M**3n+2n*M**2n+3n*M+4n):
    space-(7n*M**4n+6n*M**3n+5n*M**2n+4n*M+3n);
  assert.equal(x,polynomial,name+': independent closed form');
  assert.equal(M%3n,1n);
  assert.equal(x%3n,0n);
  const n=x/3n-offset,q=space/n,limit=q*n;
  assert.ok(n>M**4n&&n<space,name+': not k5');
  assert.equal(q,3n,name+': not q3');
  assert.equal(limit,x-3n*offset);
  const accepted=offset===0n?x:step===1?1n:limit;
  const rank=1n+(accepted-1n)%n;
  assert.equal(rank,step===1&&offset?1n:n);
  assert.equal(digit,step===1?1n:M-8n);
  for(const [key,v] of Object.entries({M,FIRST:first,CUR:digit,N:n,SPACE:space,
    LIMIT:limit,WIDE:accepted,RESULT:rank}))
    assert.equal(BigInt(values[key]),v,name+': '+key);
  const reject=!offset?0n:step===1?space-x+1n:3n;
  return {name,k:5,q:'3',first:String(first),step,n:String(n),
    initial_x:String(x),limit:String(limit),accepted:String(accepted),
    rank:String(rank),mathematical_rejections:String(reject)};
}

function checkK5Q4(name, values) {
  assert.ok(K5_Q4_TARGETS.has(name), 'unexpected k5 q4 case');
  const {step,offset}=K5_Q4_TARGETS.get(name);
  const space=M**5n,first=step===1?M-5n:M-1n;
  let x=1n,digit=first,weight=1n;
  for(let j=0;j<5;j++) {
    x+=(digit-1n)*weight;
    digit=1n+(digit-1n+BigInt(step)+M)%M;
    weight*=M;
  }
  const polynomial=step===1?
    space-(M**4n+2n*M**3n+3n*M**2n+4n*M+5n):
    space-(5n*M**4n+4n*M**3n+3n*M**2n+2n*M+1n);
  assert.equal(x,polynomial,name+': independent closed form');
  assert.equal(M%4n,3n);
  assert.equal(x%4n,0n);
  const n=x/4n-offset,q=space/n,limit=q*n;
  assert.ok(n>M**4n&&n<space,name+': not k5');
  assert.equal(q,4n,name+': not q4');
  assert.equal(limit,x-4n*offset);
  const accepted=offset===0n?x:step===1?1n:limit;
  const rank=1n+(accepted-1n)%n;
  assert.equal(rank,step===1&&offset?1n:n);
  assert.equal(digit,step===1?M:M-6n);
  for(const [key,v] of Object.entries({M,FIRST:first,CUR:digit,N:n,SPACE:space,
    LIMIT:limit,WIDE:accepted,RESULT:rank}))
    assert.equal(BigInt(values[key]),v,name+': '+key);
  const reject=!offset?0n:step===1?space-x+1n:4n;
  return {name,k:5,q:'4',first:String(first),step,n:String(n),
    initial_x:String(x),limit:String(limit),accepted:String(accepted),
    rank:String(rank),mathematical_rejections:String(reject)};
}

function checkK5Q5(name, values) {
  assert.ok(K5_Q5_TARGETS.has(name), 'unexpected q5 case');
  const {step,offset}=K5_Q5_TARGETS.get(name);
  assert.equal(M%5n,2n,'modulus residue');
  const first=step===1?M-5n:M-4n;
  const digits=Array.from({length:5},(_,j)=>first+BigInt(j*step));
  assert.ok(digits.every(d=>d>=1n&&d<=M),'digit range');
  const space=M**5n;
  const x=digits.reduce((v,d,j)=>v+(d-1n)*M**BigInt(j),1n);
  const deficit=step===1 ? M**4n+2n*M**3n+3n*M**2n+4n*M+5n
                         : 8n*M**4n+7n*M**3n+6n*M**2n+5n*M+4n;
  assert.equal(x,space-deficit,name+': closed form');
  assert.equal(x%5n,0n,name+': divisibility');
  const n=x/5n-offset, quotient=space/n, limit=quotient*n;
  assert.ok(n>M**4n && n<space,name+': k5 range');
  assert.equal(quotient,5n,name+': q');
  assert.equal(limit,x-5n*offset,name+': L');
  const rejected=offset===0n?0n:step===1?deficit+1n:5n;
  const accepted=offset===0n?x:step===1?1n:limit;
  const rank=1n+(accepted-1n)%n;
  assert.equal(rank,step===1&&offset?1n:n,name+': rank');
  const cur=step===1?M:M-9n;
  for(const [key,value] of Object.entries({M,FIRST:first,CUR:cur,N:n,
    SPACE:space,LIMIT:limit,WIDE:accepted,RESULT:rank}))
    assert.equal(BigInt(values[key]),value,name+': '+key);
  return {name,k:5,q:'5',step,offset:String(offset),first:String(first),
    n:String(n),initial_x:String(x),limit:String(limit),
    accepted:String(accepted),rank:String(rank),
    mathematical_rejections:String(rejected)};
}

function main() {
  if (process.argv[2] === '--one') {
    child(process.argv[3], process.argv[4]);
    return;
  }
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'wat-es-stage02-'));
  try {
    const compiled = path.join(dir, 'selector.wasm');
    const compile = spawnSync('wat2wasm', [SOURCE, '-o', compiled],
      {encoding: 'utf8', timeout: 30000});
    if (compile.error || compile.status !== 0) {
      throw new Error('wat2wasm failed: ' + (compile.error || compile.stderr));
    }
    const mod = new WebAssembly.Module(fs.readFileSync(compiled));
    const tests = WebAssembly.Module.exports(mod)
      .filter(e => e.kind === 'function' && e.name.startsWith('test_'))
      .map(e => e.name).sort();
    assert.equal(tests.length, 95, 'unexpected regression set size');
    assert.equal(new Set(tests).size, tests.length, 'duplicate export');
    for (const name of TARGETS.keys()) assert.ok(tests.includes(name), 'missing target: ' + name);
    for (const name of FORWARD_TARGETS.keys()) assert.ok(tests.includes(name), 'missing forward target: ' + name);
    for (const name of SHORT_TARGETS.keys()) assert.ok(tests.includes(name), 'missing short target: ' + name);
    for (const name of SHORT_Q23_TARGETS.keys()) assert.ok(tests.includes(name), 'missing q23: ' + name);
    for (const name of SHORT_Q2_LIVENESS_TARGETS.keys()) assert.ok(tests.includes(name), 'missing liveness: ' + name);
    for (const name of SHORT_Q123_DIFFERENTIAL_TARGETS.keys()) assert.ok(tests.includes(name), 'missing differential: ' + name);
    for (const name of SHORT_Q45_TARGETS.keys()) assert.ok(tests.includes(name), 'missing q45: ' + name);
    for (const name of SHORT_SMALL_N_TARGETS.keys()) assert.ok(tests.includes(name), 'missing small n: ' + name);
    for (const name of K4_Q1_TARGETS.keys()) assert.ok(tests.includes(name), 'missing k4 q1: ' + name);
    for (const name of K5_Q2_TARGETS.keys()) assert.ok(tests.includes(name), 'missing k5 q2: ' + name);
    for (const name of K5_Q3_TARGETS.keys()) assert.ok(tests.includes(name), 'missing k5 q3: ' + name);
    for (const name of K5_Q4_TARGETS.keys()) assert.ok(tests.includes(name), 'missing k5 q4: ' + name);
    for (const name of K5_Q5_TARGETS.keys()) assert.ok(tests.includes(name), 'missing k5 q5: ' + name);
    let passed = 0;
    const numerics = {};
    const forwardNumerics = {};
    const shortNumerics = {};
    const q23Numerics = {};
    const shortQ2LivenessNumerics = {};
    const shortQ123DifferentialNumerics = {};
    const shortQ45Numerics = {};
    const shortSmallNNumerics = {};
    const k4Q1Numerics = {};
    const k5Q2Numerics = {};
    const k5Q3Numerics = {};
    const k5Q4Numerics = {};
    const k5Q5Numerics = {};
    for (const name of tests) {
      const p = spawnSync(process.execPath, [__filename, '--one', compiled, name],
        {encoding: 'utf8', timeout: 30000, maxBuffer: 1000000});
      if (p.error || p.status !== 0 || p.stderr !== '') {
        throw new Error(name + ': process failed: ' + (p.error || p.stderr));
      }
      const outcome = JSON.parse(p.stdout);
      assert.equal(outcome.name, name);
      assert.equal(outcome.value, 1, 'WAT test failed: ' + name);
      if (TARGETS.has(name)) numerics[name] = checkNumerics(name, outcome.numerics);
      if (FORWARD_TARGETS.has(name)) forwardNumerics[name] = checkForwardNumerics(name, outcome.numerics);
      if (SHORT_TARGETS.has(name)) shortNumerics[name] = checkShortNumerics(name, outcome.numerics);
      if (SHORT_Q23_TARGETS.has(name)) q23Numerics[name] = checkShortQ23(name,outcome.numerics);
      if (SHORT_Q2_LIVENESS_TARGETS.has(name)) shortQ2LivenessNumerics[name] = checkShortQ2Liveness(name,outcome.numerics);
      if (SHORT_Q123_DIFFERENTIAL_TARGETS.has(name)) shortQ123DifferentialNumerics[name] = checkShortQ123Differential(name, outcome.numerics);
      if (SHORT_Q45_TARGETS.has(name)) shortQ45Numerics[name] = checkShortQ45(name, outcome.numerics);
      if (SHORT_SMALL_N_TARGETS.has(name)) shortSmallNNumerics[name] = checkShortSmallN(name, outcome.numerics);
      if (K4_Q1_TARGETS.has(name)) k4Q1Numerics[name] = checkK4Q1(name, outcome.numerics);
      if (K5_Q2_TARGETS.has(name)) k5Q2Numerics[name] = checkK5Q2(name, outcome.numerics);
      if (K5_Q3_TARGETS.has(name)) k5Q3Numerics[name] = checkK5Q3(name, outcome.numerics);
      if (K5_Q4_TARGETS.has(name)) k5Q4Numerics[name] = checkK5Q4(name, outcome.numerics);
      if (K5_Q5_TARGETS.has(name)) k5Q5Numerics[name] = checkK5Q5(name, outcome.numerics);
      passed++;
    }
    assert.equal(Object.keys(numerics).length, TARGETS.size, 'missing numeric probes');
    assert.equal(Object.keys(forwardNumerics).length, FORWARD_TARGETS.size, 'missing forward numeric probes');
    assert.equal(Object.keys(shortNumerics).length, SHORT_TARGETS.size, 'missing short numeric probes');
    assert.equal(Object.keys(q23Numerics).length, SHORT_Q23_TARGETS.size, 'missing short q23 probes');
    assert.equal(Object.keys(shortQ2LivenessNumerics).length, SHORT_Q2_LIVENESS_TARGETS.size, 'missing short q2 liveness probes');
    assert.equal(Object.keys(shortQ123DifferentialNumerics).length, SHORT_Q123_DIFFERENTIAL_TARGETS.size, 'missing short q123 differential probes');
    assert.equal(Object.keys(shortQ45Numerics).length, SHORT_Q45_TARGETS.size, 'missing short q45 probes');
    assert.equal(Object.keys(shortSmallNNumerics).length, SHORT_SMALL_N_TARGETS.size, 'missing small n probes');
    assert.equal(Object.keys(k4Q1Numerics).length, K4_Q1_TARGETS.size, 'missing k4 q1 probes');
    assert.equal(Object.keys(k5Q2Numerics).length, K5_Q2_TARGETS.size, 'missing k5 q2 probes');
    assert.equal(Object.keys(k5Q3Numerics).length, K5_Q3_TARGETS.size, 'missing k5 q3 probes');
    assert.equal(Object.keys(k5Q4Numerics).length, K5_Q4_TARGETS.size, 'missing k5 q4 probes');
    assert.equal(Object.keys(k5Q5Numerics).length, K5_Q5_TARGETS.size, 'missing k5 q5 probes');
    const report = {
      project_id: 'PC-BRANCH-WAT-SPANISH',
      native_engine: 'Node WebAssembly via WABT',
      source_sha256: crypto.createHash('sha256').update(fs.readFileSync(SOURCE)).digest('hex'),
      total: tests.length, passed, failed: tests.length - passed,
      numeric_oracles: numerics,
      forward_numeric_oracles: forwardNumerics,
      short_numeric_oracles: shortNumerics,
      short_q23_numeric_oracles: q23Numerics,
      short_q2_liveness_numeric_oracles: shortQ2LivenessNumerics,
      short_q123_differential_numeric_oracles: shortQ123DifferentialNumerics,
      short_q45_numeric_oracles: shortQ45Numerics,
      short_small_n_numeric_oracles: shortSmallNNumerics,
      k4_q1_numeric_oracles: k4Q1Numerics,
      k5_q2_numeric_oracles: k5Q2Numerics,
      k5_q3_numeric_oracles: k5Q3Numerics,
      k5_q4_numeric_oracles: k5Q4Numerics,
      k5_q5_numeric_oracles: k5Q5Numerics
    };
    process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  } finally {
    fs.rmSync(dir, {recursive: true, force: true});
  }
}
try { main(); } catch (err) {
  process.stderr.write(String(err.stack || err) + '\n');
  process.exitCode = 1;
}
