#!/usr/bin/env node
'use strict';
/** Stage02 DISCOVERY01: independent k=5,q=5 arithmetic oracle; no WebAssembly execution. */
function run() {
  'use strict';
  const PROJECT_ID = 'PC-BRANCH-WAT-SPANISH';
  const fail = (condition, message) => { if (!condition) throw Error(message); };
  const forwardBases = [12n, 17n, 22n];
  const backwardBases = [52n, 57n, 62n];
  const check = (base, step, delta, walk) => {
    fail(base >= 12n && base % 5n === 2n, 'modular precondition');
    fail((step === 1 || step === -1) && (delta === 0 || delta === 1), 'input domain');
    const first = base - (step === 1 ? 5n : 4n);
    const space = base ** 5n;
    let x = 1n;
    const digits = [];
    for (let j = 0; j < 5; j++) {
      const digit = first + BigInt(j * step);
      fail(digit >= 1n && digit <= base, 'ring digit range');
      digits.push(digit.toString());
      x += (digit - 1n) * base ** BigInt(j);
    }
    // Closed-form polynomial derived independently of the base-digit loop.
    const deficit = step === 1
      ? base ** 4n + 2n * base ** 3n + 3n * base ** 2n + 4n * base + 5n
      : 8n * base ** 4n + 7n * base ** 3n + 6n * base ** 2n + 5n * base + 4n;
    fail(x === space - deficit, 'independent polynomial disagrees with digits');
    fail(x > 0n && x % 5n === 0n, 'q5 divisibility');
    const n = x / 5n - BigInt(delta);
    fail(n > base ** 4n && n < space && space / n === 5n, 'wide k=5,q=5 gate');
    const limit = 5n * n;
    fail(x - limit === 5n * BigInt(delta), 'exact boundary delta');
    const accepted = delta === 0 ? x : (step === 1 ? 1n : limit);
    const rejections = delta === 0 ? 0n : (step === 1 ? deficit + 1n : 5n);
    const rank = 1n + (accepted - 1n) % n;
    fail(rank === (delta === 1 && step === 1 ? 1n : n), 'expected rank');
    if (walk) {
      let cursor = x, count = 0;
      while (cursor > limit) {
        cursor = step === 1
          ? (cursor === space ? 1n : cursor + 1n)
          : (cursor === 1n ? space : cursor - 1n);
        count++;
        fail(count <= 300000, 'explicit bounded walk exhausted');
      }
      fail(cursor === accepted && BigInt(count) === rejections, 'stepwise differential mismatch');
    }
    return {first: first.toString(), digits, n: n.toString(),
      x: x.toString(), space: space.toString(), limit: limit.toString(),
      accepted: accepted.toString(), rank: rank.toString(),
      rejections: rejections.toString(), q: '5'};
  };
  let bounded = 0, rejected = 0n;
  for (const [step, bases] of [[1, forwardBases], [-1, backwardBases]]) {
    for (const base of bases) for (const delta of [0,1]) {
      const result = check(base,step,delta,true);
      bounded++;
      rejected += BigInt(result.rejections);
    }
  }
  fail(bounded === 12 && rejected === 376079n, 'bounded regression totals');
  const productionBase = (1n << 127n) - 1n;
  const production = {};
  for (const step of [1,-1]) for (const delta of [0,1]) {
    const key = `${step === 1 ? 'forward' : 'backward'}_${delta === 0 ? 'exact' : 'rejected'}`;
    production[key] = check(productionBase,step,delta,false);
  }
  return {project_id:PROJECT_ID,mode:'independent_bigint_math_only_not_native',
    k:5,q:5,bounded_cases:bounded,bounded_rejections:Number(rejected),
    production_algebraic_cases:production,failed:0,native:'NOT_EXECUTED_BY_THIS_ORACLE'};
}
if (require.main === module) console.log(JSON.stringify(run()));
module.exports = {run};
