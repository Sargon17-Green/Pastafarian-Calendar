'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const production = require('../src');
const reference = require('./normative-reference');
const rawMutant = require('./stage-56-reference');

const F = production.FOUNDATION_DAY_OLD;
let groups = 0;
function group(label, fn) {
  fn();
  groups += 1;
  console.log('SAVED-SUM PASS — ' + label);
}
function oneBased(values) { return [null, ...values]; }

function canonicalPostStirOne(stirNumber, bowls) {
  const old = bowls.slice();
  const rawBowlSum = old.reduce((sum, value) => sum + value, 0n);
  const savedOrderNumber = reference.SAVE(rawBowlSum + 149n * BigInt(stirNumber));
  const orderNumber = reference.regularMod(savedOrderNumber - 1n, 720n) + 1n;
  const order = reference.bowlOrderFromNumber(orderNumber);
  const nextBowls = new Array(6);
  const positions = [];
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    const prevId = order[reference.wrap1(position - 1, 6) - 1];
    const nextId = order[reference.wrap1(position + 1, 6) - 1];
    const u = old[bowlId - 1]
      + 3n * old[prevId - 1]
      + 5n * old[nextId - 1]
      + savedOrderNumber
      + BigInt(stirNumber)
      + BigInt(position * position);
    const rawBeforeSave = reference.square(u) + 7n * old[prevId - 1] * old[nextId - 1];
    nextBowls[bowlId - 1] = reference.SAVE(rawBeforeSave);
    positions.push({ position, bowlId, prevId, nextId, u, rawBeforeSave, output: nextBowls[bowlId - 1] });
  }
  return { bowls: nextBowls, order, rawBowlSum, savedOrderNumber, positions };
}

function independentSauceRounds(calculationDay, targetDay) {
  const counts = reference.workCounts(calculationDay, targetDay);
  const hidden = reference.buildHiddenDrops(counts, reference.STONES);
  const visible = reference.buildVisibleDrops(counts, reference.STONES, hidden);
  const afterDrops = reference.applyVisibleDropsToBowls(reference.initialBowls(counts), visible, reference.STONES);
  let bowls = afterDrops.bowls.slice();
  const rounds = [];
  for (let stir = 1; stir <= 12; stir += 1) {
    const round = canonicalPostStirOne(stir, bowls);
    rounds.push(round);
    bowls = round.bowls.slice();
  }
  return { bowlsAfterDrops: afterDrops.bowls.slice(), orderAtDrop46: afterDrops.orderAtDrop46.slice(), rounds, bowls };
}

group('discriminator kills rawSumMutant when S != R', () => {
  const bowls0 = [1n, 2n, 3n, 4n, 5n, 6n];
  const bowls1 = oneBased(bowls0);
  const legacy = production.postStirOneForOrderMemoryDiscovery(1, bowls1);
  const context = production.createStage56PostStirContext();
  context.legacyScarCallCount += 1;
  const actual = production.stage56CanonicalSavedSumPostStir(1, bowls1, legacy, context);
  const canonical = canonicalPostStirOne(1, bowls0);
  const mutant = rawMutant.rawSumMutantPostStirOne(1, bowls0);

  assert.equal(canonical.rawBowlSum, 21n);
  assert.equal(canonical.savedOrderNumber, 170n);
  assert.notEqual(canonical.rawBowlSum, canonical.savedOrderNumber);
  assert.deepEqual(canonical.order, [2, 4, 1, 3, 6, 5]);
  assert.deepEqual(canonical.positions.map((row) => row.u), [209n, 190n, 208n, 223n, 236n, 240n]);
  assert.deepEqual(canonical.bowls, [43348n, 43821n, 49771n, 36114n, 57684n, 55801n]);
  assert.deepEqual(mutant.bowls, [3565n, 3740n, 5518n, 1695n, 8365n, 7674n]);
  assert.notDeepEqual(canonical.bowls, mutant.bowls);
  assert.deepEqual(actual.order, canonical.order);
  assert.deepEqual(actual.bowls, oneBased(canonical.bowls));
  assert.notDeepEqual(actual.bowls, oneBased(mutant.bowls));
});

group('reachable implementation source adds savedOrderNumber, not rawBowlSum, inside u', () => {
  const source = production.stage56CanonicalSavedSumPostStir.toString();
  assert.match(source, /\+ savedOrderNumber\s*\+ BigInt\(stirNumber\)/);
  assert.doesNotMatch(source, /\+ rawBowlSum\s*\+ BigInt\(stirNumber\)/);
  assert.match(source, /const old = bowls\.slice\(\)/);
  assert.match(source, /const pending = new Array\(7\)\.fill\(null\)/);
});

group('bowls after drop 46 and all 12 post-stirs match independent canonical reference', () => {
  for (const [calculationDay, targetDay] of [[F, F], [-15048173n, -15048173n]]) {
    const actual = production.sauceWithScarsStage56(calculationDay, targetDay);
    const expected = independentSauceRounds(calculationDay, targetDay);
    assert.deepEqual(actual.bowlsAfterDrops.slice(1), expected.bowlsAfterDrops);
    assert.deepEqual(actual.orderAt46Latch, expected.orderAtDrop46);
    assert.equal(actual.stage56SavedSumApplied, true);
    assert.equal(actual.stage56RawBowlSumApplied, false);
    assert.equal(actual.stage56PostStirContext.history.length, 12);
    for (let index = 0; index < 12; index += 1) {
      const got = actual.stage56PostStirContext.history[index];
      const want = expected.rounds[index];
      assert.equal(got.stirIndex, index + 1);
      assert.equal(got.rawBowlSum, want.rawBowlSum);
      assert.equal(got.savedOrderNumber, want.savedOrderNumber);
      assert.deepEqual(got.correctedResult.order, want.order);
      assert.deepEqual(got.correctedResult.bowls, oneBased(want.bowls));
      assert.notEqual(got.rawBowlSum, got.savedOrderNumber, 'each witness round should discriminate S from R');
    }
    assert.deepEqual(actual.bowls.slice(1), expected.bowls);
  }
});

group('Foundation final bowls are canonical saved-sum bowls', () => {
  const actual = production.sauceWithScarsStage56(F, F);
  assert.deepEqual(actual.bowls.slice(1).map(String), [
    '65286679584284972964194865805379907599',
    '127720283375330263615328810127751035299',
    '54364069496183805843611594721403108554',
    '93072329024469476118876155742008280619',
    '54867842942953573450868747713087920246',
    '111207247632761530752404582123499651367'
  ]);
});

group('Stage 58 remembered sauce preserves canonical saved-sum and cold/warm equality', () => {
  production.resetStage58AccelerationMetrics();
  const a = production.sauceWithScarsStage56(F + 17n, F - 9n);
  const b = production.sauceWithScarsStage56(F + 17n, F - 9n);
  assert.equal(a.stage56SavedSumApplied, true);
  assert.equal(b.stage56SavedSumApplied, true);
  assert.equal(a.stage56RawBowlSumApplied, false);
  assert.equal(b.stage56RawBowlSumApplied, false);
  assert.deepEqual(b.bowls, a.bowls);
  assert.deepEqual(b.orderAt46Latch, a.orderAt46Latch);
  assert.equal(b.stage58MemoryReplay, true);
});

group('deterministic random corpus matches canonical bowls, drop-46 order and query streams', () => {
  let state = 0x5a17n;
  const next = () => {
    state = (1103515245n * state + 12345n) & 0x7fffffffn;
    return state;
  };
  for (let i = 0; i < 12; i += 1) {
    const center = i % 2 === 0 ? F : -15048173n;
    const calculationDay = center + (next() % 2001n) - 1000n;
    const targetDay = calculationDay + (next() % 2001n) - 1000n;
    const actual = production.sauceWithScarsStage56(calculationDay, targetDay);
    const expected = reference.sauce(calculationDay, targetDay);
    assert.deepEqual(actual.bowls.slice(1), expected.bowls);
    assert.deepEqual(actual.orderAt46Latch, expected.orderAtDrop46);
    for (const [bowlId, seal] of [[1, 1n], [2, 21n], [3, 31n], [5, 33n]]) {
      const semanticNext = production.nextBowlFromOrderAt46Latch(actual.orderAt46Latch, bowlId);
      const got = production.answerRingFromCurrentState(actual.bowls, bowlId, semanticNext, seal);
      const want = reference.askBowl(expected, bowlId, seal);
      assert.deepEqual(got, want);
    }
  }
});

group('semantic caches survive repeat, A→B→A, import-order and failure→retry', () => {
  const a = [F + 41n, F - 73n];
  const b = [-15048173n + 19n, -15048173n + 271n];
  const a1 = production.sauceWithScarsStage56(...a);
  const b1 = production.sauceWithScarsStage56(...b);
  const a2 = production.sauceWithScarsStage56(...a);
  assert.deepEqual(a2.bowls, a1.bowls);
  assert.deepEqual(a2.orderAt46Latch, a1.orderAt46Latch);
  assert.notDeepEqual(b1.bowls, a1.bowls);
  assert.equal(a2.stage58MemoryReplay, true);

  let injected = false;
  assert.throws(() => production.sauceWithScarsStage56(F + 83n, F + 91n, () => {
    if (!injected) { injected = true; throw new Error('injected-checkpoint-failure'); }
  }), /injected-checkpoint-failure/);
  const retry = production.sauceWithScarsStage56(F + 83n, F + 91n);
  const retryReference = reference.sauce(F + 83n, F + 91n);
  assert.deepEqual(retry.bowls.slice(1), retryReference.bowls);

  const root = path.join(__dirname, '..');
  const scriptA = `const p=require(${JSON.stringify(root + '/src')});require(${JSON.stringify(root + '/src/normative-cooking-trace')});const x=p.sauceWithScarsStage56(p.FOUNDATION_DAY_OLD+5n,p.FOUNDATION_DAY_OLD-7n);process.stdout.write(JSON.stringify(x.bowls.slice(1).map(String)));`;
  const scriptB = `require(${JSON.stringify(root + '/src/normative-cooking-trace')});const p=require(${JSON.stringify(root + '/src')});const x=p.sauceWithScarsStage56(p.FOUNDATION_DAY_OLD+5n,p.FOUNDATION_DAY_OLD-7n);process.stdout.write(JSON.stringify(x.bowls.slice(1).map(String)));`;
  const runA = spawnSync(process.execPath, ['-e', scriptA], { encoding: 'utf8' });
  const runB = spawnSync(process.execPath, ['-e', scriptB], { encoding: 'utf8' });
  assert.equal(runA.status, 0, runA.stderr);
  assert.equal(runB.status, 0, runB.stderr);
  assert.equal(runA.stdout, runB.stdout);
});

group('historical raw-sum reference is isolated as mutant, never imported by production', () => {
  assert.equal(rawMutant.HISTORICAL_SUPERSEDED_RAW_SUM_MUTANT, true);
  const source = fs.readFileSync(path.join(__dirname, '..', 'src', 'index.js'), 'utf8');
  assert.equal(source.includes("require('../tests/stage-56-reference')"), false);
  assert.equal(source.includes("require('../tests/normative-reference')"), false);
});

console.log('CANONICAL SAVED-SUM CORRECTION PASS — ' + groups + ' groups.');
