#!/usr/bin/env node
'use strict';
// Standalone, independent STATIC model. Not a PowerShell execution and not a
// Stage43 activation/seal gate. No metadata or repository files are written.
const assert = require('assert');
const path = require('path');
const cp = require('child_process');
const { TextDecoder } = require('util');

const root = path.resolve(__dirname, '..');
const pinnedBlob = 'a3f53b67e4445bdc835179cd484fe27b3e2648f7';
function git(args) {
  return cp.execFileSync('git', args, { cwd: root, maxBuffer: 8 * 1024 * 1024 });
}
const actualBlob = git(['rev-parse', 'HEAD:DEVELOPMENT_STAGE.md']).toString('ascii').trim();
assert.strictEqual(actualBlob, pinnedBlob, 'Frozen Stage42 Git blob changed; do not reinterpret this oracle');
const originalBytes = git(['show', 'HEAD:DEVELOPMENT_STAGE.md']);
function inspect(bytes) {
  let offset = 0;
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf) offset = 3;
  let text;
  try {
    text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes.subarray(offset));
  } catch (_) {
    return { code: 'INVALID_UTF8', map: null };
  }
  if (/\r(?!\n)/.test(text)) return { code: 'STANDALONE_CR', map: null };
  if (text.includes('\r\n') && text.replace(/\r\n/g, '').includes('\n')) {
    return { code: 'MIXED_LINE_ENDINGS', map: null };
  }
  if (text.includes('\uFEFF')) return { code: 'INTERIOR_BOM', map: null };
  if (/[\x00-\x09\x0B-\x0C\x0E-\x1F\x7F\u0085\u2028\u2029]/.test(text)) {
    return { code: 'FORBIDDEN_CONTROL', map: null };
  }
  const map = new Map();
  for (const line of text.replace(/\r\n/g, '\n').split('\n')) {
    if (line.length === 0) continue;
    const m = /^([A-Z][A-Z0-9_]*)=(.*)$/.exec(line);
    if (!m) return { code: 'MALFORMED_LINE', map: null };
    if (map.has(m[1])) return { code: 'DUPLICATE_KEY', map: null };
    map.set(m[1], m[2]);
  }
  return { code: 'OK', map };
}
const baseline = inspect(originalBytes);
assert.strictEqual(baseline.code, 'OK');
assert.strictEqual(baseline.map.size, 728);
assert.strictEqual(baseline.map.get('TOTAL_STAGES'), '55');
assert.strictEqual(baseline.map.get('CURRENT_STAGE'), '42');
assert.strictEqual(baseline.map.get('CURRENT_DISCOVERY'), '27');
assert.strictEqual(baseline.map.get('LAST_COMPLETED_STAGE'), '42');
assert.strictEqual(baseline.map.get('STAGE42_RUNTIME_VERIFICATION'), 'EVIDENCE_ONLY_CONFIRMED');
assert.strictEqual([...baseline.map.keys()].filter(k => k.startsWith('STAGE43_')).length, 0);
const pinnedMembership = [
  'CURRENT_STAGE=42', 'CURRENT_DISCOVERY=27',
  'LAST_COMPLETED_STAGE=42', 'STAGE42_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED'
];
function fullSnapshotAccept(bytes) {
  const parsed = inspect(bytes);
  if (parsed.code !== 'OK' || parsed.map.size !== baseline.map.size) return false;
  for (const [k, v] of baseline.map) {
    if (!parsed.map.has(k) || parsed.map.get(k) !== v) return false;
  }
  return true;
}
function membershipAccept(bytes) {
  let s = bytes.toString('utf8').replace(/\r\n/g, '\n');
  if (s.startsWith('\uFEFF')) s = s.slice(1);
  const lines = new Set(s.split('\n'));
  return pinnedMembership.every(x => lines.has(x));
}
const text = originalBytes.toString('utf8').replace(/\r\n/g, '\n');
const lines = text.split('\n');
function replaceKey(key, val) {
  return lines.map(l => l.startsWith(key + '=') ? key + '=' + val : l).join('\n');
}
function removeKey(key) {
  return lines.filter(l => !l.startsWith(key + '=')).join('\n');
}
const originalLongValue = baseline.map.get('MONSTER_ARCHITECTURE_GROWTH');
assert.strictEqual(typeof originalLongValue, 'string');
function c(id, label, content, allow) {
  return { id, label, bytes: Buffer.isBuffer(content) ? content : Buffer.from(content, 'utf8'), allow };
}
const cases = [
  c('C00', 'unchanged_baseline', text, true),
  c('C01', 'CRLF_only', text.replace(/\n/g, '\r\n'), true),
  c('C02', 'initial_BOM', '\uFEFF' + text, true),
  c('C03', 'additional_blank_line', text + '\n', true),
  c('C04', 'no_terminal_newline', text.replace(/\n+$/, ''), true),
  c('C05', 'BOM_plus_CRLF', '\uFEFF' + text.replace(/\n/g, '\r\n'), true),
  c('X01', 'unchecked_value_same_count', replaceKey('MONSTER_ARCHITECTURE_GROWTH', 'SYNTHETIC_BAD'), false),
  c('X02', 'unknown_key_swap_same_count', removeKey('MONSTER_ARCHITECTURE_GROWTH') + '\nUNAUTHORIZED_KEY=surrogate', false),
  c('X03', 'current_patch_changed', replaceKey('CURRENT_PATCH', '15'), false),
  c('X04', 'premature_stage43_append', text + '\nSTAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE', false),
  c('X05', 'identical_duplicate', text + '\nTOTAL_STAGES=55', false),
  c('X06', 'conflicting_duplicate', text + '\nCURRENT_STAGE=43', false),
  c('X07', 'unicode_value_replaced', replaceKey('NATURAL_LANGUAGE', 'Filipino'), false),
  c('X08', 'empty_nonoptional_value', replaceKey('NATURAL_LANGUAGE', ''), false),
  c('X09', 'unknown_empty_value', text + '\nUNAUTHORIZED_KEY=', false),
  c('X10', 'missing_equals', text + '\nBadMissingEquals', false),
  c('X11', 'standalone_CR', text + '\rUNAUTHORIZED_KEY=1', false),
  c('X12', 'mixed_line_endings', text.replace('\n', '\r\n'), false),
  c('X13', 'interior_BOM', text + '\nUNAUTHORIZED_KEY=\uFEFF', false),
  c('X14', 'NUL_control', text + '\nBAD_KEY=\u0000', false),
  c('X15', 'lowercase_key', text + '\nwrong=1', false),
  c('X16', 'spaces_only_line', text + '\n  ', false),
  c('X17', 'extra_equals_same_count', replaceKey('MONSTER_ARCHITECTURE_GROWTH', originalLongValue + '=ADDED'), false),
  c('X18', 'stage_43_without_discovery', replaceKey('CURRENT_STAGE', '43'), false),
  c('X19', 'remove_nonmembership_key', removeKey('MONSTER_ARCHITECTURE_GROWTH'), false),
  c('X20', 'stage43_key_swap_same_count', removeKey('MONSTER_ARCHITECTURE_GROWTH') + '\nSTAGE43_RUNTIME_VERIFICATION=PENDING_NATIVE', false),
  c('X21', 'duplicate_after_removal_same_count', removeKey('MONSTER_ARCHITECTURE_GROWTH') + '\nTOTAL_STAGES=55', false)
];
let legal = 0, rejected = 0, shapeAcceptedRejects = 0, membershipAcceptedRejects = 0;
for (const item of cases) {
  const parseResult = inspect(item.bytes);
  const accepted = fullSnapshotAccept(item.bytes);
  assert.strictEqual(accepted, item.allow, item.id + ' frozen-snapshot expectation');
  if (accepted) legal++;
  else {
    rejected++;
    if (parseResult.code === 'OK') shapeAcceptedRejects++;
    if (membershipAccept(item.bytes)) membershipAcceptedRejects++;
  }
  process.stdout.write(item.id + ' ' + (accepted ? 'ALLOW' : 'REJECT') +
    ' shape=' + parseResult.code +
    ' stage43_membership=' + (membershipAccept(item.bytes) ? 'ALLOW' : 'REJECT') + '\n');
}
assert.strictEqual(cases.length, 27);
assert.strictEqual(legal, 6);
assert.strictEqual(rejected, 21);
assert.strictEqual(shapeAcceptedRejects, 11);
assert.strictEqual(membershipAcceptedRejects, 20);
process.stdout.write('MODEL_ONLY=YES\nSTAGE43_ACTIVATION=NOT_ACTIVATED\n' +
  'QA_CASES=27\nLEGAL=6\nREJECTED=21\n' +
  'SHAPE_ACCEPTED_INVALID=11\nMEMBERSHIP_ACCEPTED_INVALID=20\n' +
  'FROZEN_BLOB=' + actualBlob + '\n');
