'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { pathToFileURL } = require('url');
const current = require('../src/index.js');

const PROJECT_OFFSET = 1721425n;
const CURRENT_CUTLETS = Object.freeze([
  'bronze','vulpe','ren','Lagash','pense','quar partes de nin','Palgurash','papirus','grappe',
  'scorpion','cindre','frument','fluvie','rise','Akkad','corn','li vacui vase',
]);
const REVERSE_CUTLETS = Object.freeze([
  'ארד','שועל','כליה','לגש','מחשבה','ארבעה חלקים מתשעה','פַּלְגּוּרַשׁ','גומא','אשכול',
  'עקרב','אפר','חיטה','נהר','צחוק','אכד','קרן','הכד הריק',
]);
const CURRENT_MONTHS = Object.freeze([
  'argile','granat','cubit','invidie','Eridu','dent-pasta','tri partes de quin','Karshumav',
  'leopard','stann','brume','oliban','fus','costa','carob','Uruk','honte','camel','cupr','pute',
  'vitelle','stelle','mel','splen','calcari','joy','fig','Ninive','ran','pech','lampe',
  'li cludet porta','sesam','nuca','argent','Susa','tempeste','asin','farine','regret',
  'Babylon','lingue','lin','sal','pir','arc','sand',
]);
const REVERSE_MONTHS = Object.freeze([
  'טין','רימון','מרפק','קנאה','ארידו','משחת־שיניים','שלושה חלקים מחמישה','כַּרְשׁוּמַב',
  'נמר','בדיל','ערפל','לבונה','כישור','צלע','חרוב','אורוק','בושה','גמל','נחושת','באר',
  'חלמון','כוכב','דבש','טחול','אבן־גיר','שמחה','תאנה','נינוה','צפרדע','זפת','נר',
  'הדלת הסגורה','שומשום','עורף','כסף','שושן','סערה','חמור','קמח','חרטה','בבל','לשון',
  'פשתן','מלח','אגס','קשת','חול',
]);

function currentValue(calculationJdn, targetJdn) {
  const tuple = current.calendarDateSpaghetti(
    calculationJdn - PROJECT_OFFSET,
    targetJdn - PROJECT_OFFSET,
  );
  assert(Array.isArray(tuple) && tuple.length === 5, 'Stage 57 forward result must remain a five-part tuple.');
  return {
    year: String(tuple[0]),
    cutletName: String(tuple[1]),
    dayInCutlet: Number(tuple[2]),
    monthName: String(tuple[3]),
    dayInMonth: Number(tuple[4]),
  };
}

function mapFastToCurrent(value) {
  const cutletIndex = REVERSE_CUTLETS.indexOf(String(value.cutletName));
  const monthIndex = REVERSE_MONTHS.indexOf(String(value.monthName));
  assert(cutletIndex >= 0, 'Unknown reverse-engine cutlet: ' + value.cutletName);
  assert(monthIndex >= 0, 'Unknown reverse-engine month: ' + value.monthName);
  return {
    year: String(value.year),
    cutletName: CURRENT_CUTLETS[cutletIndex],
    dayInCutlet: Number(value.dayInCutlet),
    monthName: CURRENT_MONTHS[monthIndex],
    dayInMonth: Number(value.dayInMonth),
  };
}

function mapCurrentToFast(value) {
  const cutletIndex = CURRENT_CUTLETS.indexOf(String(value.cutletName));
  const monthIndex = CURRENT_MONTHS.indexOf(String(value.monthName));
  assert(cutletIndex >= 0);
  assert(monthIndex >= 0);
  return {
    year: String(value.year),
    cutletName: REVERSE_CUTLETS[cutletIndex],
    dayInCutlet: Number(value.dayInCutlet),
    monthName: REVERSE_MONTHS[monthIndex],
    dayInMonth: Number(value.dayInMonth),
  };
}

(async () => {
  // The application intentionally keeps the repository's historical CommonJS
  // package mode while the vendored reverse engine is native ESM in browsers.
  // Mirror the browser module boundary in an isolated temporary package so Node
  // parses the exact vendored sources as ESM without changing project-wide mode.
  const moduleRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'pastafari-reverse-vendor-'));
  fs.cpSync(path.resolve(__dirname, '../browser/reverse-engine'), moduleRoot, { recursive: true });
  fs.writeFileSync(path.join(moduleRoot, 'package.json'), '{"type":"module"}\n', 'utf8');

  try {
    const fastUrl = pathToFileURL(path.join(moduleRoot, 'pastafari-calendar-fast.js')).href;
    const clientUrl = pathToFileURL(path.join(moduleRoot, 'pastafari-constraints-client.js')).href;
    const fast = await import(fastUrl);
    const constraints = await import(clientUrl);
    const fastCalendar = new fast.PastafariCalendar();

  const calculations = [2461259n, 2461309n];
  const offsets = [-400n, -31n, -1n, 0n, 1n, 7n, 31n, 180n, 400n, 1200n];
  let checked = 0;
  for (const calculationJdn of calculations) {
    for (const offset of offsets) {
      const targetJdn = calculationJdn + offset;
      const expected = currentValue(calculationJdn, targetJdn);
      const observed = mapFastToCurrent(
        fastCalendar.convertJdn(targetJdn, { calculationJdn }).toJSON(),
      );
      assert.deepStrictEqual(observed, expected,
        'reverse candidate engine diverges from Stage 57 at c=' + calculationJdn + ', t=' + targetJdn);
      checked += 1;
    }
  }

  // One real public-contract round trip: construct the simple one-variable
  // constraint with a fixed calculation day and require the known target.
  const calculationJdn = 2461309n;
  const targetJdn = calculationJdn + 7n;
  const wantedCurrent = currentValue(calculationJdn, targetJdn);
  const wantedFast = mapCurrentToFast(wantedCurrent);
  const result = await constraints.solvePastafariConstraints({
    variables: { target: {} },
    constraints: [{
      type: 'pastafari',
      target: 'target',
      calculationJdn,
      date: wantedFast,
    }],
  }, { timeoutMs: 120000 });

  assert.strictEqual(result.complete, true, 'authoritative simple reverse did not prove completeness');
  assert(result.solutions.some((solution) => BigInt(solution.target.jdn) === targetJdn),
    'authoritative simple reverse did not recover the original target JDN');

  for (const solution of result.solutions) {
    const jdn = BigInt(solution.target.jdn);
    assert.deepStrictEqual(currentValue(calculationJdn, jdn), wantedCurrent,
      'reverse solution fails Stage 57 forward verification');
  }

    console.log('browser-reverse-vendor: PASS (' + checked + ' forward differential witnesses + reverse round-trip)');
  } finally {
    fs.rmSync(moduleRoot, { recursive: true, force: true });
  }
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
