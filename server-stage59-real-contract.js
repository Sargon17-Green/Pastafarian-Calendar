'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { Stage58PersistenceBridge } = require('../server/stage58-persistence-bridge');

const corePath = path.resolve(__dirname, '..', 'src', 'index.js');
if (!fs.existsSync(corePath)) {
  console.log('server-stage59-real-contract: SKIP (src/index.js absent in delta-only workspace)');
  process.exit(0);
}

const core = require(corePath);
assert.equal(typeof core.calendarDateSpaghetti, 'function');
assert.ok(core.STAGE57_GLOBAL_GATE_REGISTRY);
assert.ok(core.STAGE57_GLOBAL_MANAGER);
const bridge = new Stage58PersistenceBridge(core, {});
const status = bridge.status();
for (const scope of [
  'gate-days', 'gate-gaps', 'year-5000', 'year-transitions', 'year-histories', 'semantic-structures',
  'selection-results', 'sauce-stage56',
]) {
  assert.ok(status.scopes[scope], 'missing Stage 58 scope ' + scope);
}
console.log('server-stage59-real-contract: PASS');
