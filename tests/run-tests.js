'use strict';

const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const production = require('../src');
const o = require('./normative-reference');

const fixture = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'fixtures', 'stage-01.json'), 'utf8'));
let passed = 0;

function test(name, fn) {
  fn();
  passed += 1;
  console.log('PASS ' + name);
}

function bi(s) { return BigInt(s); }

test('constant exact e relation del dies de base', () => {
  assert.equal(o.M, (1n << 127n) - 1n);
  assert.equal(o.TABLETS_DAY - o.FOUNDATION_DAY, 14777149n);
  assert.equal(o.YEAR_MAX_DAYS, 5778n);
  assert.equal(fixture.constants.M, o.M.toString());
});

test('SAVE conserva li interval 1..M e tracta multiplicas de M quam M', () => {
  for (const [input, expected] of fixture.save) assert.equal(o.SAVE(bi(input)).toString(), expected);
  for (const x of [-3n * o.M, -1n, 0n, 1n, o.M, 4n * o.M + 9n]) {
    const y = o.SAVE(x);
    assert.ok(1n <= y && y <= o.M);
  }
});

test('dayCount usa paritá correct circum li die de fundation', () => {
  for (const [day, expected] of fixture.dayCount) assert.equal(o.dayCount(bi(day)).toString(), expected);
  assert.equal(o.dayCount(o.FOUNDATION_DAY), 1n);
  assert.equal(o.dayCount(o.FOUNDATION_DAY - 1n) % 2n, 0n);
  assert.equal(o.dayCount(o.FOUNDATION_DAY + 1n) % 2n, 1n);
});

test('workCounts usa distance cronologic inclusiv', () => {
  const a = o.workCounts(o.FOUNDATION_DAY, o.FOUNDATION_DAY);
  assert.deepEqual(Object.fromEntries(Object.entries(a).map(([k,v]) => [k,v.toString()])), fixture.workCounts[0]);
  const b = o.workCounts(o.FOUNDATION_DAY - 2n, o.FOUNDATION_DAY + 3n);
  assert.equal(b.distance, 6n);
  assert.equal(b.direction, 3n);
});

test('li table de stones deriva simultanmen ex chascun snapshot precedent', () => {
  assert.equal(o.STONES.length, 46);
  for (const row of fixture.stones) assert.deepEqual(o.STONES[row.index - 1].map(String), row.values);
  const old = o.STONES[0];
  const expectedSecond = [
    o.SAVE(old[0] * old[0] + 3n * old[1] + 2n),
    o.SAVE(old[1] * old[1] + 5n * old[2] + old[0]),
    o.SAVE(old[2] * old[2] + 7n * old[3] + old[1]),
    o.SAVE(old[3] * old[3] + 11n * old[4] + old[2]),
    o.SAVE(old[4] * old[4] + 13n * old[0] + old[3])
  ];
  assert.deepEqual(o.STONES[1], expectedSecond);
});

test('unranking lexicografic del six boles respecta rangs 1 e 720', () => {
  assert.deepEqual(o.bowlOrderFromNumber(1n), fixture.permutations.rank1);
  assert.deepEqual(o.bowlOrderFromNumber(2n), fixture.permutations.rank2);
  assert.deepEqual(o.bowlOrderFromNumber(720n), fixture.permutations.rank720);
  assert.deepEqual(o.bowlOrderFromDrop(720n), fixture.permutations.drop720);
});

test('li sauce normativ local es determinist al fundation', () => {
  const first = o.sauce(o.FOUNDATION_DAY, o.FOUNDATION_DAY);
  const second = o.sauce(o.FOUNDATION_DAY, o.FOUNDATION_DAY);
  assert.deepEqual(first.bowls.map(String), fixture.sauceFoundation.bowls);
  assert.deepEqual(first.orderAtDrop46, fixture.sauceFoundation.orderAtDrop46);
  assert.deepEqual(first, second);
});

test('li question de bole usa li órdine del drop 46 e un direction unic', () => {
  const s = o.sauce(o.FOUNDATION_DAY, o.FOUNDATION_DAY);
  const a = o.askBowl(s, 1, 1n);
  assert.equal(a.first.toString(), fixture.askFoundationSeal1.first);
  assert.equal(a.directionStep.toString(), fixture.askFoundationSeal1.directionStep);
  assert.deepEqual([0n,1n,2n].map((k) => o.answerAt(a,k).toString()), fixture.askFoundationSeal1.firstThree);
});

test('compositiones limitat es contat exactmen e unrankat lexicograficmen', () => {
  const family = o.makeBoundedCompositionCounter(7, 2, 2, 5);
  assert.equal(family.countAll().toString(), fixture.boundedComposition.count);
  assert.deepEqual(Array.from({ length: Number(family.countAll()) }, (_, i) => family.unrank1(BigInt(i + 1))), fixture.boundedComposition.ranks);
});

test('li DP de intertexe selecte un intertexe complet e legal', () => {
  const family = o.makeMonthWeavingFamily([2, 1]);
  assert.equal(family.count().toString(), fixture.weaving.count);
  assert.deepEqual(Array.from({ length: Number(family.count()) }, (_, i) => family.unrank1(BigInt(i + 1))), fixture.weaving.ranks);
  for (const row of fixture.weaving.ranks) {
    assert.equal(row.filter((x) => x === 1).length, 2);
    assert.equal(row.filter((x) => x === 2).length, 1);
    assert.ok(row.indexOf(1) < row.indexOf(2));
    assert.ok(row.lastIndexOf(1) < row.lastIndexOf(2));
  }
});

test('li annu 5000 rejecte implicitmen longores super 5778', () => {
  const engine = o.createGateEngine();
  const y = o.year5000(o.FOUNDATION_DAY, engine);
  assert.deepEqual({
    number: y.number.toString(),
    openGateIndex: y.openGateIndex.toString(),
    closeGateIndex: y.closeGateIndex.toString(),
    openGateDay: y.openGateDay.toString(),
    closeGateDay: y.closeGateDay.toString()
  }, fixture.year5000Foundation);
  const L = y.closeGateDay - y.openGateDay;
  assert.ok(252n <= L && L <= 5778n);
});

test('SourceLanguageCatalog es congelat, complet e index-stabil', () => {
  const c = production.SourceLanguageCatalog;
  assert.ok(Object.isFrozen(c));
  assert.ok(Object.isFrozen(c.cutlets));
  assert.ok(Object.isFrozen(c.months));
  assert.equal(c.cutlets.length, 17);
  assert.equal(c.months.length, 47);
  c.cutlets.forEach((row, i) => { assert.equal(row.canonicalIndex, i + 1); assert.ok(Object.isFrozen(row)); });
  c.months.forEach((row, i) => { assert.equal(row.canonicalIndex, i + 1); assert.ok(Object.isFrozen(row)); });
  assert.equal(production.textByCanonicalIndex('cutlet', 12), 'frument');
  assert.equal(production.textByCanonicalIndex('month', 44), 'sal');
});

test('li infrastructura monster neutral crea un context isolat e validat', () => {
  const a = production.createBootstrapContext(1n, 2n);
  const b = production.createBootstrapContext(1n, 2n);
  assert.notEqual(a, b);
  assert.notEqual(a.metrics, b.metrics);
  assert.equal(a.status, 'READY_FOR_HISTORIC_DEVELOPMENT');
  assert.deepEqual(a.branchTrace, ['BOOTSTRAP_VALIDATED']);
  assert.throws(() => production.createBootstrapContext(1, 2n));
});

test('li function final resta intentionalmen absent in Stage 1', () => {
  assert.throws(() => production.calendarDateSpaghetti(1n, 1n), production.BootstrapStageError);
});

console.log('\n' + passed + ' tests passat; Stage 1 es GREEN.');
