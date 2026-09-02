'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

(async () => {
  const browserRoot = path.resolve(__dirname, '..', 'browser');
  const serviceModule = await import(pathToFileURL(path.join(browserRoot, 'calendar-service.js')).href);
  const componentModule = await import(pathToFileURL(path.join(browserRoot, 'pastafari-date.js')).href);

  assert.deepEqual(componentModule.PastafariDateElement.observedAttributes, [
    'date', 'calculation-date', 'headless', 'no-editor',
  ]);
  assert.equal(typeof componentModule.getPastafariDateAsync, 'function');
  assert.equal(componentModule.getPastafariDate, componentModule.getPastafariDateAsync);

  let call = null;
  serviceModule.installSharedCalendarService({
    async convert(targetJdn, calculationJdn) {
      call = { targetJdn, calculationJdn };
      return { year: '7', cutletName: 'C', dayInCutlet: 2, monthName: 'M', dayInMonth: 1 };
    },
    async getCutletView() { throw new Error('ne usat per li asincron API'); },
    async retry() {},
    dispose() {},
  });
  const result = await componentModule.getPastafariDateAsync('0001-01-01', '0001-01-01');
  assert.deepEqual(call, { targetJdn: 1721426n, calculationJdn: 1721426n });
  assert.deepEqual(result, { year: '7', cutletName: 'C', dayInCutlet: 2, monthName: 'M', dayInMonth: 1 });
  assert.ok(Object.isFrozen(result));

  console.log('browser-interface-contract: PASS');
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
