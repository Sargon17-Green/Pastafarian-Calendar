'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const production = require('../src');
const oracle = require('./stage-56-reference');

const F = production.FOUNDATION_DAY_OLD;
let groups = 0;

function group(label, fn) {
  fn();
  groups += 1;
  console.log('STAGE 56 PASS — ' + label);
}

function canonicalFive(result) {
  const cutlet = production.SourceLanguageCatalog.cutlets.find((row) => row.text === result[1]);
  const month = production.SourceLanguageCatalog.months.find((row) => row.text === result[3]);
  assert.ok(cutlet, 'Li nom de cutlet deve resolver a un canonicalIndex.');
  assert.ok(month, 'Li nom de mensu deve resolver a un canonicalIndex.');
  return [result[0], cutlet.canonicalIndex, result[2], month.canonicalIndex, result[4]];
}

function oneBasedReferenceBowls(values) {
  return [null, ...values];
}

group('discriminator separa rawBowlSum de savedOrderNumber sin mutar permutation', () => {
  const bowls = [null, 1n, 2n, 3n, 4n, 5n, 6n];
  const legacy = production.postStirOneForOrderMemoryDiscovery(1, bowls);
  const context = production.createStage56PostStirContext();
  context.legacyScarCallCount += 1;
  const corrected = production.stage56RawBowlSumPostStirDetour(1, bowls, legacy, context);
  const expected = oracle.rawBowlSumPostStirOne(1, bowls.slice(1));
  assert.equal(context.rawBowlSum, 21n);
  assert.equal(context.savedOrderNumber, 170n);
  assert.notEqual(context.rawBowlSum, context.savedOrderNumber);
  assert.deepEqual(corrected.order, legacy.order);
  assert.deepEqual(corrected.order, expected.order);
  assert.notDeepEqual(corrected.bowls, legacy.bowls);
  assert.deepEqual(corrected.bowls, oneBasedReferenceBowls(expected.bowls));
});

group('scar static conserva +savedStirSum e detour usa +rawBowlSum', () => {
  const legacySource = production.postStirOneForOrderMemoryDiscovery.toString();
  const patchSource = production.stage56RawBowlSumPostStirDetour.toString();
  assert.match(legacySource, /\+ savedStirSum/);
  assert.doesNotMatch(legacySource, /\+ rawBowlSum/);
  assert.match(patchSource, /\+ rawBowlSum/);
  assert.match(patchSource, /legacyRound\.savedStirSum !== savedOrderNumber/);
  assert.match(patchSource, /stage54ArraysEqual\(legacyRound\.order, order\)/);
});

group('omni 12 post-stirs concorda con oracle local raw-bowl-sum', () => {
  for (const [calculationDay, targetDay] of [[F, F], [-15048173n, -15048173n]]) {
    const actual = production.sauceWithScarsStage56(calculationDay, targetDay);
    const expected = oracle.sauce(calculationDay, targetDay);
    const state = actual.stage56PostStirContext;
    assert.equal(state.appliedCount, 12);
    assert.equal(state.legacyScarCallCount, 12);
    assert.equal(state.appliedFlag, true);
    assert.equal(state.stirIndex, 12);
    assert.equal(state.history.length, 12);
    for (let index = 0; index < 12; index += 1) {
      const witness = state.history[index];
      const expectedRound = expected.rounds[index];
      assert.equal(witness.stirIndex, index + 1);
      assert.equal(witness.legacyScarCallCount, index + 1);
      assert.equal(witness.rawBowlSum, expectedRound.rawBowlSum);
      assert.equal(witness.savedOrderNumber, expectedRound.savedOrderNumber);
      assert.deepEqual(witness.oldResult.order, expectedRound.order);
      assert.deepEqual(witness.correctedResult.order, expectedRound.order);
      assert.deepEqual(witness.correctedResult.bowls, oneBasedReferenceBowls(expectedRound.bowls));
    }
    assert.deepEqual(actual.bowls.slice(1), expected.bowls);
    assert.deepEqual(actual.orderAt46Latch, expected.orderAtDrop46);
  }
});

group('Foundation bowls e order-46 es reconstructet independentmen', () => {
  const actual = production.sauceWithScarsStage56(F, F);
  const expected = oracle.sauce(F, F);
  assert.deepEqual(actual.bowls.slice(1), expected.bowls);
  assert.deepEqual(actual.orderAt46Latch, expected.orderAtDrop46);
  assert.deepEqual(actual.bowls.slice(1).map(String), [
    '67068226522203060890658143482200172502',
    '156830781782038036265833091137164500083',
    '27860245395513113590943202859639481773',
    '154958270957687565769906933601352753179',
    '83762519477527209919484977230999195024',
    '154633989471499313687998830839607736513'
  ]);
  assert.deepEqual(actual.orderAt46Latch, [4, 5, 2, 3, 6, 1]);
});

group('second sauce witness bowls e order-46 es reconstructet independentmen', () => {
  const actual = production.sauceWithScarsStage56(-15048173n, -15048173n);
  const expected = oracle.sauce(-15048173n, -15048173n);
  assert.deepEqual(actual.bowls.slice(1), expected.bowls);
  assert.deepEqual(actual.orderAt46Latch, expected.orderAtDrop46);
  assert.deepEqual(actual.bowls.slice(1).map(String), [
    '117774601791306122049402151598700069949',
    '25984316916056421874135403969605614983',
    '143826773047381553934876475558335320216',
    '59571312657074816751803206901536426066',
    '65620015217119503197726025514221700116',
    '28674863197150075414624507047786307945'
  ]);
  assert.deepEqual(actual.orderAt46Latch, [3, 4, 6, 5, 2, 1]);
});

group('context ownership es separat inter du sauces', () => {
  const leftSauce = production.sauceWithScarsStage56(F, F);
  const rightSauce = production.sauceWithScarsStage56(F, F);
  assert.notStrictEqual(leftSauce.stage56PostStirContext, rightSauce.stage56PostStirContext);
  assert.notStrictEqual(leftSauce.stage56PostStirContext.history, rightSauce.stage56PostStirContext.history);
  assert.equal(Object.isFrozen(leftSauce.stage56PostStirContext), true);
  assert.equal(Object.isFrozen(leftSauce.stage56PostStirContext.history), true);
  assert.equal(leftSauce.stage56PostStirContext.appliedCount, 12);
  assert.equal(rightSauce.stage56PostStirContext.appliedCount, 12);
});

group('production ne importa null oracle e li Stage 55 certificate resta separat', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'src', 'index.js'), 'utf8');
  assert.equal(source.includes("require('../tests/normative-reference')"), false);
  assert.equal(source.includes("require('../tests/stage-56-reference')"), false);
  assert.equal(fs.existsSync(path.join(__dirname, '..', 'FINAL_AUDIT_STAGE_55.md')), true);
});

console.log('STAGE 56 CORRECTIVE PASS — ' + groups + ' gruppes; rawBowlSum detour es authoritative e li scar legacy resta activ.');
