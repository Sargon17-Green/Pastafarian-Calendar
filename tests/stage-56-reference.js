'use strict';

// Oracle local correctiv de Stage 56. It reutilisa solmen li parte pre-post-stir del reference
// JavaScript del sam linea; null function production es importat ci.
const base = require('./normative-reference');

function rawBowlSumPostStirOne(stirNumber, bowls) {
  if (!Number.isInteger(stirNumber) || stirNumber < 1 || stirNumber > 12) {
    throw new RangeError('Li stir del oracle Stage 56 deve esser inter 1 e 12.');
  }
  if (!Array.isArray(bowls) || bowls.length !== 6 || bowls.some((value) => typeof value !== 'bigint')) {
    throw new TypeError('Li oracle Stage 56 exige exactmen six bowls BigInt.');
  }
  const old = bowls.slice();
  const rawBowlSum = old.reduce((sum, value) => sum + value, 0n);
  const savedOrderNumber = base.SAVE(rawBowlSum + 149n * BigInt(stirNumber));
  const orderNumber = base.regularMod(savedOrderNumber - 1n, 720n) + 1n;
  const order = base.bowlOrderFromNumber(orderNumber);
  const nextBowls = new Array(6);
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    const prevId = order[base.wrap1(position - 1, 6) - 1];
    const nextId = order[base.wrap1(position + 1, 6) - 1];
    const u = old[bowlId - 1]
      + 3n * old[prevId - 1]
      + 5n * old[nextId - 1]
      + rawBowlSum
      + BigInt(stirNumber)
      + BigInt(position * position);
    nextBowls[bowlId - 1] = base.SAVE(base.square(u) + 7n * old[prevId - 1] * old[nextId - 1]);
  }
  return Object.freeze({
    bowls: Object.freeze(nextBowls.slice()),
    order: Object.freeze(order.slice()),
    rawBowlSum,
    savedOrderNumber
  });
}

function rawBowlSumPostStir12(bowls) {
  let current = bowls.slice();
  const rounds = [];
  for (let stir = 1; stir <= 12; stir += 1) {
    const round = rawBowlSumPostStirOne(stir, current);
    rounds.push(round);
    current = round.bowls.slice();
  }
  return Object.freeze({ bowls: Object.freeze(current.slice()), rounds: Object.freeze(rounds.slice()) });
}

function sauce(calculationDay, targetDay) {
  const counts = base.workCounts(calculationDay, targetDay);
  const hidden = base.buildHiddenDrops(counts, base.STONES);
  const visible = base.buildVisibleDrops(counts, base.STONES, hidden);
  const afterDrops = base.applyVisibleDropsToBowls(base.initialBowls(counts), visible, base.STONES);
  const post = rawBowlSumPostStir12(afterDrops.bowls);
  return Object.freeze({
    bowlsAfterDrops: Object.freeze(afterDrops.bowls.slice()),
    bowls: Object.freeze(post.bowls.slice()),
    rounds: post.rounds,
    orderAtDrop46: Object.freeze(afterDrops.orderAtDrop46.slice())
  });
}

module.exports = Object.freeze({
  SourceLanguageCatalog: base.SourceLanguageCatalog,
  SAVE: base.SAVE,
  regularMod: base.regularMod,
  rawBowlSumPostStirOne,
  rawBowlSumPostStir12,
  sauce
});
