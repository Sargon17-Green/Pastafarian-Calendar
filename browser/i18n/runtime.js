'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));

  function data() {
    const candidate = root.PastafariBrowserLocaleData;
    if (!candidate || !Array.isArray(candidate.locales) || candidate.locales.length === 0) {
      throw new Error('PastafariBrowserLocaleData manca o es vacui.');
    }
    return candidate;
  }

  function canonicalCandidates(tag) {
    if (typeof tag !== 'string' || tag.trim() === '') return [];
    let canonical;
    try {
      canonical = Intl.getCanonicalLocales(tag.trim())[0];
    } catch (_) {
      return [];
    }
    const parts = canonical.split('-');
    const values = [];
    for (let length = parts.length; length >= 1; length -= 1) {
      values.push(parts.slice(0, length).join('-'));
    }
    return values;
  }

  function localeMap() {
    return new Map(data().locales.map((locale) => [locale.code.toLowerCase(), locale]));
  }

  function resolveLocale(requested, browserLanguages) {
    const map = localeMap();
    const candidates = [];
    if (requested) candidates.push(requested);
    for (const value of browserLanguages || []) candidates.push(value);

    for (const candidate of candidates) {
      for (const tag of canonicalCandidates(candidate)) {
        const found = map.get(tag.toLowerCase());
        if (found) return found;
      }
    }

    const fallback = map.get(String(data().defaultLocale).toLowerCase());
    if (!fallback) throw new Error('Li default browser-locale ne existe: ' + data().defaultLocale);
    return fallback;
  }

  function format(template, values) {
    const vars = values || {};
    return String(template).replace(/\{([A-Za-z0-9_]+)\}/g, (whole, key) => (
      Object.prototype.hasOwnProperty.call(vars, key) ? String(vars[key]) : whole
    ));
  }

  function translate(locale, key, values) {
    if (!locale || !locale.messages || !Object.prototype.hasOwnProperty.call(locale.messages, key)) {
      throw new Error('Manca li browser-message ' + key + ' por li locale ' + (locale && locale.code ? locale.code : '<null>') + '.');
    }
    const message = locale.messages[key];
    if (typeof message !== 'string' || message.trim() === '') {
      throw new Error('Li browser-message ' + key + ' es vacui por li locale ' + locale.code + '.');
    }
    return format(message, values);
  }

  function calendarName(locale, group, sourceName) {
    if (!locale || !locale.calendar) {
      throw new Error('Manca li calendar-nómines por li locale ' + (locale && locale.code ? locale.code : '<null>') + '.');
    }
    const names = group === 'cutlet'
      ? locale.calendar.cutlets
      : group === 'month'
        ? locale.calendar.months
        : null;
    if (!names) throw new Error('Ínvalid grupp de calendar-nómine: ' + group + '.');

    const key = String(sourceName);
    if (!Object.prototype.hasOwnProperty.call(names, key)) {
      throw new Error('Manca li ' + group + '-nómine ' + key + ' por li locale ' + locale.code + '.');
    }
    const localized = names[key];
    if (typeof localized !== 'string' || localized.trim() === '') {
      throw new Error('Li ' + group + '-nómine ' + key + ' es vacui por li locale ' + locale.code + '.');
    }
    return localized;
  }

  function supportedLocales() {
    return Object.freeze(data().locales.slice());
  }

  ns.i18n = Object.freeze({
    resolveLocale,
    translate,
    calendarName,
    supportedLocales,
  });
})(typeof globalThis === 'object' ? globalThis : this);
