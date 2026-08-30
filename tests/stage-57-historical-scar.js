'use strict';

const assert = require('assert/strict');
const production = require('../src');

assert.throws(
  () => production.calendarDateSpaghettiStage56Historical(-15048553n, -15044872n),
  (error) => error instanceof production.BootstrapStageError
    && error.message === 'Patch 26 final diverge del year resoluet per li sequential walk.'
);

console.log('STAGE 57 HISTORIC SCAR PASS: li route Stage 56 continua executer e faller sur li witness old; Stage 57 solmen circumva it in li path final.');
