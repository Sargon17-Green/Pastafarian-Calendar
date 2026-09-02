'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));

  function safePositiveInteger(value, field) {
    const big = BigInt(value);
    if (big < 1n || big > BigInt(Number.MAX_SAFE_INTEGER)) {
      throw new RangeError(field + ' ne posse esser representat quam un secur JavaScript integer.');
    }
    return Number(big);
  }

  function normalizeCalendarResult(value) {
    if (!Array.isArray(value) && (!value || typeof value !== 'object')) {
      throw new TypeError('Li calendarium retornat un ínvalid resultate.');
    }
    const year = Array.isArray(value) ? value[0] : value.year;
    const cutletName = Array.isArray(value) ? value[1] : value.cutletName;
    const dayInCutlet = Array.isArray(value) ? value[2] : value.dayInCutlet;
    const monthName = Array.isArray(value) ? value[3] : value.monthName;
    const dayInMonth = Array.isArray(value) ? value[4] : value.dayInMonth;
    if (cutletName == null || monthName == null) {
      throw new TypeError('Li calendarium retornat un resultate sin nómin de cutlet o mensu.');
    }
    return Object.freeze({
      year: String(year),
      cutletName: String(cutletName),
      dayInCutlet: safePositiveInteger(dayInCutlet, 'dayInCutlet'),
      monthName: String(monthName),
      dayInMonth: safePositiveInteger(dayInMonth, 'dayInMonth'),
    });
  }

  function cloneCanonicalResult(value) {
    const normalized = normalizeCalendarResult(value);
    return Object.freeze({
      year: normalized.year,
      cutletName: normalized.cutletName,
      dayInCutlet: normalized.dayInCutlet,
      monthName: normalized.monthName,
      dayInMonth: normalized.dayInMonth,
    });
  }

  ns.resultNormalizer = Object.freeze({ normalizeCalendarResult, cloneCanonicalResult });
})(typeof globalThis === 'object' ? globalThis : this);
