'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const serviceApi = ns.calendarService;
  const axis = ns.dateAxis;

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

  function canonicalIndex(list, value, field) {
    const index = list.indexOf(String(value));
    if (index < 0) throw new RangeError('Ínconosset ' + field + ': ' + String(value));
    return index;
  }

  function positiveSafeInteger(value, field) {
    const number = Number(value);
    if (!Number.isSafeInteger(number) || number < 1) {
      throw new RangeError(field + ' deve esser un integer positiv.');
    }
    return number;
  }

  function normalizeCurrentDate(value) {
    if (!value || typeof value !== 'object') throw new TypeError('Li date Pastafarian deve esser un object.');
    return Object.freeze({
      year: String(BigInt(value.year)),
      cutletName: String(value.cutletName),
      dayInCutlet: positiveSafeInteger(value.dayInCutlet, 'dayInCutlet'),
      monthName: String(value.monthName),
      dayInMonth: positiveSafeInteger(value.dayInMonth, 'dayInMonth'),
    });
  }

  function toReverseDate(value) {
    const date = normalizeCurrentDate(value);
    const cutletIndex = canonicalIndex(CURRENT_CUTLETS, date.cutletName, 'cutlet');
    const monthIndex = canonicalIndex(CURRENT_MONTHS, date.monthName, 'month');
    return Object.freeze({
      year: date.year,
      cutletName: REVERSE_CUTLETS[cutletIndex],
      dayInCutlet: date.dayInCutlet,
      monthName: REVERSE_MONTHS[monthIndex],
      dayInMonth: date.dayInMonth,
    });
  }

  function sameCurrentDate(actual, wanted) {
    return actual && String(actual.year) === wanted.year
      && String(actual.cutletName) === wanted.cutletName
      && Number(actual.dayInCutlet) === wanted.dayInCutlet
      && String(actual.monthName) === wanted.monthName
      && Number(actual.dayInMonth) === wanted.dayInMonth;
  }

  let modulePromise = null;
  function reverseClientModule() {
    const config = root.PastafariBrowserConfig || {};
    const url = config.reverseClientUrl;
    if (!url) {
      const error = new Error('Li reverse-search module ne es disponibil in ti construction.');
      error.code = 'ERR_REVERSE_UNAVAILABLE';
      return Promise.reject(error);
    }
    if (!modulePromise) modulePromise = import(url);
    return modulePromise;
  }

  async function solveSimplePastafariDate(value, calculationJdn, options) {
    const wanted = normalizeCurrentDate(value);
    const moduleApi = await reverseClientModule();
    const reverseDate = toReverseDate(wanted);
    const calc = BigInt(calculationJdn);
    const problem = Object.freeze({
      variables: Object.freeze({ target: Object.freeze({}) }),
      constraints: Object.freeze([Object.freeze({
        type: 'pastafari',
        target: 'target',
        calculationJdn: calc,
        date: reverseDate,
      })]),
    });
    const result = await moduleApi.solvePastafariConstraints(problem, options || {});
    const service = serviceApi.getSharedCalendarService();
    const verified = [];
    for (const solution of result.solutions || []) {
      if (!solution || !solution.target || solution.target.jdn == null) continue;
      const targetJdn = BigInt(solution.target.jdn);
      const actual = await service.convert(targetJdn, calc);
      if (!sameCurrentDate(actual, wanted)) {
        const error = new Error('Li reverse candidate ne concorda con li authoritative Stage 57 forward conversion.');
        error.name = 'ReverseForwardMismatchError';
        error.code = 'ERR_REVERSE_FORWARD_MISMATCH';
        error.targetJdn = String(targetJdn);
        error.calculationJdn = String(calc);
        error.expected = wanted;
        error.actual = actual;
        throw error;
      }
      verified.push(Object.freeze({
        jdn: targetJdn,
        gregorian: axis.jdnToGregorian(targetJdn),
        value: actual,
      }));
    }
    return Object.freeze({
      solutions: Object.freeze(verified),
      complete: result.complete === true,
      termination: String(result.termination || ''),
      scanned: result.scanned == null ? null : BigInt(result.scanned),
      candidates: result.candidates == null ? null : BigInt(result.candidates),
      verified: result.verified == null ? null : BigInt(result.verified),
      stats: result.stats || null,
    });
  }

  ns.reverseBridge = Object.freeze({
    CURRENT_CUTLETS,
    CURRENT_MONTHS,
    REVERSE_CUTLETS,
    REVERSE_MONTHS,
    normalizeCurrentDate,
    toReverseDate,
    solveSimplePastafariDate,
    isAvailable() {
      const config = root.PastafariBrowserConfig || {};
      return typeof config.reverseClientUrl === 'string' && config.reverseClientUrl !== '';
    },
  });
})(typeof globalThis === 'object' ? globalThis : this);
