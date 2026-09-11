'use strict';

// HISTORICAL — SUPERSEDED MUTANT ONLY.
// This file deliberately implements the rejected Stage-56 raw-sum interpretation so
// regression tests can prove that the canonical saved-sum path disagrees with it.
// It MUST NOT be used as a canonical oracle or to regenerate normative expectations.
const base = require('./normative-reference');

function rawSumMutantPostStirOne(stirNumber, bowls) {
  if (!Number.isInteger(stirNumber) || stirNumber < 1 || stirNumber > 12) {
    throw new RangeError('Li stir del raw-sum mutant deve esser inter 1 e 12.');
  }
  if (!Array.isArray(bowls) || bowls.length !== 6 || bowls.some((value) => typeof value !== 'bigint')) {
    throw new TypeError('Li raw-sum mutant exige exactmen six bowls BigInt.');
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

function rawSumMutantPostStir12(bowls) {
  let current = bowls.slice();
  const rounds = [];
  for (let stir = 1; stir <= 12; stir += 1) {
    const round = rawSumMutantPostStirOne(stir, current);
    rounds.push(round);
    current = round.bowls.slice();
  }
  return Object.freeze({ bowls: Object.freeze(current.slice()), rounds: Object.freeze(rounds.slice()) });
}

function rawSumMutantSauce(calculationDay, targetDay) {
  const counts = base.workCounts(calculationDay, targetDay);
  const hidden = base.buildHiddenDrops(counts, base.STONES);
  const visible = base.buildVisibleDrops(counts, base.STONES, hidden);
  const afterDrops = base.applyVisibleDropsToBowls(base.initialBowls(counts), visible, base.STONES);
  const post = rawSumMutantPostStir12(afterDrops.bowls);
  return Object.freeze({
    bowlsAfterDrops: Object.freeze(afterDrops.bowls.slice()),
    bowls: Object.freeze(post.bowls.slice()),
    rounds: post.rounds,
    orderAtDrop46: Object.freeze(afterDrops.orderAtDrop46.slice())
  });
}

module.exports = Object.freeze({
  HISTORICAL_SUPERSEDED_RAW_SUM_MUTANT: true,
  rawSumMutantPostStirOne,
  rawSumMutantPostStir12,
  rawSumMutantSauce
});
