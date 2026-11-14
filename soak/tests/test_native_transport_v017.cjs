'use strict';
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {exactDay, produce, parseArgs} = require('../runner/pilot_javascript_transport_v017.cjs');
assert.equal(exactDay('-15055671'), -15055671n);
assert.equal(exactDay('0'), 0n);
for (const value of ['-0', '+3', '00', '01', '-01', ' 1', '1.0', '1\n', '', '1e2']) {
  assert.throws(() => exactDay(value), /noncanonical/);
}
assert.deepEqual(parseArgs(['--sources-root', 'C:\\pinned', '--check-only']), {
  'sources-root': 'C:\\pinned', 'check-only': true
});
const calls = [];
const entry = {
  native: { calendarDate(c, t) {
    calls.push([c, t]);
    return [5000n, 'scorpion', 503n, 'pute', 56n];
  }},
  indexFromNative(group, name) {
    if (group === 'cutlet' && name === 'scorpion') return 10;
    if (group === 'month' && name === 'pute') return 20;
    throw Error('unrecognized native name');
  }
};
const [raw, norm] = produce(entry, -15055671n, -15055671n);
assert.deepEqual(calls, [[-15055671n, -15055671n]]);
assert.equal(JSON.parse(raw).native_tuple[1], 'scorpion');
const row = JSON.parse(norm);
assert.deepEqual([row.year, row.cutlet_index, row.day_in_cutlet,
  row.month_index, row.day_in_month], ['5000', 10, 503, 20, 56]);
assert.equal(row.source_raw_sha256, crypto.createHash('sha256').update(raw).digest('hex'));
assert.equal(row.calculation_day, '-15055671');
assert.equal(row.target_day, '-15055671');
assert.equal(raw.at(-1), 10);
assert.equal(norm.at(-1), 10);
assert.throws(() => produce({
  ...entry, indexFromNative() { throw Error('unknown name'); }
}, 0n, 0n), /unknown name/);
assert.throws(() => produce({
  ...entry, native: {calendarDate() {return [5000n, 'scorpion', 0n, 'pute', 56n];}}
}, 0n, 0n), /invalid native day ordinal/);
console.log('JS_NATIVE_TRANSPORT_PURE_TEST_PASS cases=15 converter_source_calls=0');
