'use strict';
const assert = require('node:assert/strict');
const fixture = require('./fixtures/canonical-saved-sum-downstream.json');
const production = require('../src');

function canonicalFive(result) {
  const cutlet = production.SourceLanguageCatalog.cutlets.find((row) => row.text === result[1]);
  const month = production.SourceLanguageCatalog.months.find((row) => row.text === result[3]);
  assert.ok(cutlet); assert.ok(month);
  return [result[0].toString(), cutlet.canonicalIndex, result[2].toString(), month.canonicalIndex, result[4].toString()];
}
function streamAsStrings(value) { return { first: value.first.toString(), directionStep: value.directionStep.toString() }; }
function yearAsStrings(value) {
  return {
    number: value.number.toString(),
    openGateIndex: value.openGateIndex.toString(),
    closeGateIndex: value.closeGateIndex.toString(),
    openDay: value.openDay.toString(),
    firstDay: value.firstDay.toString(),
    closeDay: value.closeDay.toString()
  };
}

assert.equal(fixture.authority, 'current Scroll saved-sum semantics');
for (const row of fixture.cases) {
  const c = BigInt(row.calculationDay);
  const baseTarget = BigInt(row.targets.find((target) => target.kind === 'base').targetDay);
  const routed = production.calendarDateSpaghettiWithContext(c, baseTarget);
  assert.deepEqual(yearAsStrings(routed.context.stage57SemanticYear), row.year, row.label + ': year');
  for (const [name, seal] of Object.entries({ cutletCount: '20', cutletPartition: '21', cutletNames: '22', monthCount: '30', monthLengths: '31', monthWeaving: '32', monthNames: '33' })) {
    assert.deepEqual(streamAsStrings(routed.context.answerStreamsBySeal[seal]), row.queryStreams[name], row.label + ': stream ' + name);
  }
  assert.equal(routed.context.structure.cutletCount, row.cutletCount, row.label + ': cutlet count');
  assert.deepEqual(routed.context.structure.cutletPartition, row.cutletPartition, row.label + ': cutlet partition');
  assert.deepEqual(routed.context.structure.cutletNameIndices, row.cutletNameIndices, row.label + ': cutlet names');
  assert.equal(routed.context.structure.monthCount, row.monthCount, row.label + ': month count');
  assert.deepEqual(routed.context.structure.monthLengths, row.monthLengths, row.label + ': month lengths');
  assert.deepEqual(routed.context.structure.monthNameIndices, row.monthNameIndices, row.label + ': month names');
  for (const target of row.targets) {
    const actual = production.calendarDateSpaghetti(c, BigInt(target.targetDay));
    assert.deepEqual(canonicalFive(actual), target.five, row.label + '/' + target.kind);
  }
}

console.log('CANONICAL SAVED-SUM DOWNSTREAM DIFFERENTIAL PASS — gates/year/query streams/cutlets/months/boundaries/final dates.');
