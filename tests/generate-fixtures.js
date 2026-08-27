'use strict';

const fs = require('fs');
const path = require('path');
const o = require('./normative-reference');

function s(x) { return x.toString(); }
function sa(xs) { return xs.map((x) => typeof x === 'bigint' ? x.toString() : x); }

const f = o.FOUNDATION_DAY;
const sauceFoundation = o.sauce(f, f);
const gateEngine = o.createGateEngine();
const year5000Foundation = o.year5000(f, gateEngine);
const bounded = o.makeBoundedCompositionCounter(7, 2, 2, 5);
const weave = o.makeMonthWeavingFamily([2, 1]);

const fixture = {
  constants: {
    M: s(o.M),
    tabletsDay: s(o.TABLETS_DAY),
    foundationDay: s(o.FOUNDATION_DAY),
    yearMaxDays: s(o.YEAR_MAX_DAYS)
  },
  save: [
    ["0", s(o.SAVE(0n))],
    ["1", s(o.SAVE(1n))],
    [s(o.M - 1n), s(o.SAVE(o.M - 1n))],
    [s(o.M), s(o.SAVE(o.M))],
    [s(o.M + 1n), s(o.SAVE(o.M + 1n))],
    [s(2n * o.M), s(o.SAVE(2n * o.M))],
    ["-1", s(o.SAVE(-1n))]
  ],
  dayCount: [-2n, -1n, 0n, 1n, 2n].map((d) => [s(f + d), s(o.dayCount(f + d))]),
  workCounts: [
    Object.fromEntries(Object.entries(o.workCounts(f, f)).map(([k,v]) => [k,s(v)])),
    Object.fromEntries(Object.entries(o.workCounts(f - 2n, f + 3n)).map(([k,v]) => [k,s(v)]))
  ],
  stones: [0, 1, 2, 45].map((i) => ({ index: i + 1, values: sa(o.STONES[i]) })),
  permutations: {
    rank1: o.bowlOrderFromNumber(1n),
    rank2: o.bowlOrderFromNumber(2n),
    rank720: o.bowlOrderFromNumber(720n),
    drop720: o.bowlOrderFromDrop(720n)
  },
  sauceFoundation: {
    bowls: sa(sauceFoundation.bowls),
    orderAtDrop46: sauceFoundation.orderAtDrop46
  },
  askFoundationSeal1: (() => {
    const a = o.askBowl(sauceFoundation, 1, 1n);
    return { first: s(a.first), directionStep: s(a.directionStep), firstThree: [0n,1n,2n].map((k) => s(o.answerAt(a,k))) };
  })(),
  boundedComposition: {
    count: s(bounded.countAll()),
    ranks: Array.from({ length: Number(bounded.countAll()) }, (_, i) => bounded.unrank1(BigInt(i + 1)))
  },
  weaving: {
    lengths: [2,1],
    count: s(weave.count()),
    ranks: Array.from({ length: Number(weave.count()) }, (_, i) => weave.unrank1(BigInt(i + 1)))
  },
  year5000Foundation: {
    number: s(year5000Foundation.number),
    openGateIndex: s(year5000Foundation.openGateIndex),
    closeGateIndex: s(year5000Foundation.closeGateIndex),
    openGateDay: s(year5000Foundation.openGateDay),
    closeGateDay: s(year5000Foundation.closeGateDay)
  },
  gatesNearFoundation: {
    minus1: s(gateEngine.ensureGateIndex(-1n)),
    zero: s(gateEngine.ensureGateIndex(0n)),
    plus1: s(gateEngine.ensureGateIndex(1n))
  }
};

const destination = path.join(__dirname, '..', 'fixtures', 'stage-01.json');
fs.writeFileSync(destination, JSON.stringify(fixture, null, 2) + '\n', 'utf8');
console.log('Fixtures de Stage 1 regenerat independentmen ex li reference normativ local.');
